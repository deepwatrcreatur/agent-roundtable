defmodule Roundtable.RoundRun do
  @moduledoc """
  Persisted state for a single question's progress through the orchestrator.

  ## Storage

  - **Hot:** ETS table `:roundtable_round_runs`, keyed by `issue_number`.
    Call `init/0` once on application start before using any other function.
  - **Durable:** JSON snapshot flushed to `<state_dir>/round_run_<n>.json`
    on every `persist/1` call. On restart, `load/1` falls back to the JSON
    file when the ETS table is cold.

  The state directory defaults to `"state"` but can be overridden via:

      config :roundtable, state_dir: "/tmp/roundtable_state"

  ## Reconciliation

  `reconcile_from_github/2` rebuilds a `RoundRun` from live GitHub data —
  useful after a crash or when no snapshot exists. It calls
  `Gh.view_issue/3`, parses comment authorship and satisfaction markers,
  and infers the current phase from labels.
  """

  alias Roundtable.Actions.Gh
  alias Roundtable.Satisfaction

  @table :roundtable_round_runs

  @type phase ::
          :awaiting_turns
          | :triage_missing_markers
          | :consensus_check
          | :coordinator_unavailable
          | :needs_human_input
          | :closed
          | :needs_human_review

  @type satisfaction_result ::
          :satisfied | :satisfied_conditional | :needs_more_evidence

  @type t :: %__MODULE__{
          issue_number: pos_integer(),
          phase: phase(),
          expected_speakers: [atom()],
          completed_speakers: [atom()],
          last_comment_ids: [String.t()],
          satisfaction_map: %{atom() => satisfaction_result()},
          retry_count: non_neg_integer(),
          updated_at: DateTime.t(),
          # Coordinator lease fields
          coordinator: atom() | nil,
          coordinator_lease_expires_at: DateTime.t() | nil,
          last_progress_at: DateTime.t() | nil,
          suspended_phase: phase() | nil,
          takeover_count: non_neg_integer()
        }

  defstruct [
    :issue_number,
    :phase,
    :expected_speakers,
    :completed_speakers,
    :last_comment_ids,
    :satisfaction_map,
    :retry_count,
    :updated_at,
    :coordinator,
    :coordinator_lease_expires_at,
    :last_progress_at,
    :suspended_phase,
    takeover_count: 0
  ]

  @doc """
  Initialise the ETS backing store.

  Idempotent — safe to call multiple times; an existing table is reused.
  Must be called before `persist/1` or `load/1`.
  """
  @spec init() :: :ok
  def init do
    case :ets.info(@table) do
      :undefined ->
        :ets.new(@table, [:set, :public, :named_table])
        :ok

      _ ->
        :ok
    end
  end

  @doc "Create a fresh `RoundRun` in the `:awaiting_turns` phase."
  @spec new(pos_integer(), [atom()]) :: t()
  def new(issue_number, expected_speakers) do
    %__MODULE__{
      issue_number: issue_number,
      phase: :awaiting_turns,
      expected_speakers: expected_speakers,
      completed_speakers: [],
      last_comment_ids: [],
      satisfaction_map: %{},
      retry_count: 0,
      updated_at: DateTime.utc_now(),
      coordinator: nil,
      coordinator_lease_expires_at: nil,
      last_progress_at: nil,
      suspended_phase: nil,
      takeover_count: 0
    }
  end

  @doc """
  Claim the coordinator role for `agent`.

  Succeeds when no coordinator is active or the existing lease has expired.
  Returns `{:error, :coordinator_active}` when another coordinator holds a
  valid lease. Compare-and-set safe for single-node BEAM.
  """
  @spec claim_coordinator(t(), atom(), pos_integer()) ::
          {:ok, t()} | {:error, :coordinator_active}
  def claim_coordinator(%__MODULE__{} = run, agent, lease_seconds \\ 300) do
    now = DateTime.utc_now()
    expires = DateTime.add(now, lease_seconds, :second)

    cond do
      run.coordinator == nil ->
        updated = %{
          run
          | coordinator: agent,
            coordinator_lease_expires_at: expires,
            last_progress_at: now,
            updated_at: now
        }

        {:ok, updated}

      coordinator_timed_out?(run, now) ->
        updated = %{
          run
          | coordinator: agent,
            coordinator_lease_expires_at: expires,
            last_progress_at: now,
            updated_at: now
        }

        {:ok, updated}

      true ->
        {:error, :coordinator_active}
    end
  end

  @doc "Refresh the coordinator's lease, stamping `last_progress_at`."
  @spec heartbeat(t(), pos_integer()) :: t()
  def heartbeat(%__MODULE__{} = run, lease_seconds \\ 300) do
    now = DateTime.utc_now()
    expires = DateTime.add(now, lease_seconds, :second)
    %{run | coordinator_lease_expires_at: expires, last_progress_at: now, updated_at: now}
  end

  @doc "True if the coordinator's lease has expired relative to `now`."
  @spec coordinator_timed_out?(t(), DateTime.t()) :: boolean()
  def coordinator_timed_out?(%__MODULE__{coordinator_lease_expires_at: nil}, _now), do: false

  def coordinator_timed_out?(%__MODULE__{coordinator_lease_expires_at: exp}, now) do
    DateTime.compare(now, exp) != :lt
  end

  @doc """
  Suspend the current phase and enter `:coordinator_unavailable`.

  Clears the coordinator slot so a standby can claim it.
  """
  @spec enter_coordinator_unavailable(t()) :: t()
  def enter_coordinator_unavailable(%__MODULE__{} = run) do
    run
    |> Map.put(:suspended_phase, run.phase)
    |> Map.put(:coordinator, nil)
    |> Map.put(:coordinator_lease_expires_at, nil)
    |> put_phase(:coordinator_unavailable)
  end

  @doc """
  Claim coordinator role as standby and resume from `:suspended_phase`.

  Returns `{:error, :no_suspended_phase}` when there is nothing to resume.
  """
  @spec takeover(t(), atom()) :: {:ok, t()} | {:error, :no_suspended_phase}
  def takeover(%__MODULE__{suspended_phase: nil}, _agent), do: {:error, :no_suspended_phase}

  def takeover(%__MODULE__{} = run, agent) do
    now = DateTime.utc_now()
    expires = DateTime.add(now, 300, :second)
    resume_phase = run.suspended_phase

    next_run =
      run
      |> Map.put(:coordinator, agent)
      |> Map.put(:coordinator_lease_expires_at, expires)
      |> Map.put(:last_progress_at, now)
      |> Map.put(:takeover_count, run.takeover_count + 1)
      |> Map.put(:suspended_phase, nil)
      |> put_phase(resume_phase)

    {:ok, next_run}
  end

  @doc "Transition to `phase`, stamping `updated_at` and emitting a telemetry span."
  @spec put_phase(t(), phase()) :: t()
  def put_phase(%__MODULE__{} = run, phase) do
    Roundtable.Telemetry.phase_transition(run.issue_number, run.phase, phase)
    %{run | phase: phase, updated_at: DateTime.utc_now()}
  end

  @doc """
  Record that `agent` completed their turn with `satisfaction`.

  Pass `nil` for `satisfaction` when the marker hasn't been parsed yet;
  an existing entry in `satisfaction_map` is preserved.
  """
  @spec mark_speaker_done(t(), atom(), satisfaction_result() | nil) :: t()
  def mark_speaker_done(%__MODULE__{} = run, agent, satisfaction) do
    completed = Enum.uniq([agent | run.completed_speakers])

    sat_map =
      if satisfaction,
        do: Map.put(run.satisfaction_map, agent, satisfaction),
        else: run.satisfaction_map

    %{run | completed_speakers: completed, satisfaction_map: sat_map, updated_at: DateTime.utc_now()}
  end

  @doc "Persist to ETS and flush a JSON snapshot to the state directory."
  @spec persist(t()) :: :ok | {:error, term()}
  def persist(%__MODULE__{} = run) do
    :ets.insert(@table, {run.issue_number, run})
    flush_json(run)
  end

  @doc """
  Load from ETS; falls back to the JSON snapshot on disk.

  Returns `{:error, :not_found}` when neither source has data.
  """
  @spec load(pos_integer()) :: {:ok, t()} | {:error, :not_found}
  def load(issue_number) do
    case :ets.lookup(@table, issue_number) do
      [{^issue_number, run}] -> {:ok, run}
      [] -> load_from_json(issue_number)
    end
  end

  @doc """
  Rebuild a `RoundRun` from live GitHub issue data.

  Calls `Gh.view_issue/3` for `issue_number`, then:
  - parses `completed_speakers` from comment authorship headers
  - re-parses satisfaction markers from each speaker's most recent comment
  - infers `phase` from current issue labels and open/closed state

  `gh_config` accepts an `:agents` key to set `expected_speakers`;
  defaults to `[:codex, :gemini, :claude_ic]`.
  """
  @spec reconcile_from_github(pos_integer(), map()) :: {:ok, t()} | {:error, term()}
  def reconcile_from_github(issue_number, gh_config) do
    expected = Map.get(gh_config, :agents, [:codex, :gemini, :claude_ic])

    case Gh.view_issue(issue_number, [:comments, :labels, :state], gh_config) do
      {:error, reason} ->
        {:error, reason}

      {:ok, issue} ->
        {:ok, build_from_issue(issue_number, expected, issue)}
    end
  end

  @doc false
  # Public for testing — constructs a RoundRun from a pre-fetched issue map.
  @spec build_from_issue(pos_integer(), [atom()], map()) :: t()
  def build_from_issue(issue_number, expected_speakers, issue) do
    comments = Map.get(issue, "comments", [])
    labels = extract_label_names(issue)

    {completed, sat_map, comment_ids} = parse_comments(comments)
    phase = infer_phase(labels, issue)

    %__MODULE__{
      issue_number: issue_number,
      phase: phase,
      expected_speakers: expected_speakers,
      completed_speakers: completed,
      last_comment_ids: comment_ids,
      satisfaction_map: sat_map,
      retry_count: 0,
      updated_at: DateTime.utc_now()
    }
  end

  # ------------------------------------------------------------------
  # JSON persistence
  # ------------------------------------------------------------------

  defp state_dir, do: Application.get_env(:roundtable, :state_dir, "state")

  defp flush_json(%__MODULE__{} = run) do
    dir = state_dir()
    File.mkdir_p!(dir)
    path = Path.join(dir, "round_run_#{run.issue_number}.json")

    data = %{
      issue_number: run.issue_number,
      phase: Atom.to_string(run.phase),
      expected_speakers: Enum.map(run.expected_speakers, &Atom.to_string/1),
      completed_speakers: Enum.map(run.completed_speakers, &Atom.to_string/1),
      last_comment_ids: run.last_comment_ids,
      satisfaction_map:
        Map.new(run.satisfaction_map, fn {k, v} ->
          {Atom.to_string(k), Atom.to_string(v)}
        end),
      retry_count: run.retry_count,
      updated_at: DateTime.to_iso8601(run.updated_at),
      coordinator: if(run.coordinator, do: Atom.to_string(run.coordinator), else: nil),
      coordinator_lease_expires_at:
        if(run.coordinator_lease_expires_at,
          do: DateTime.to_iso8601(run.coordinator_lease_expires_at),
          else: nil
        ),
      last_progress_at:
        if(run.last_progress_at, do: DateTime.to_iso8601(run.last_progress_at), else: nil),
      suspended_phase:
        if(run.suspended_phase, do: Atom.to_string(run.suspended_phase), else: nil),
      takeover_count: run.takeover_count
    }

    case Jason.encode(data, pretty: true) do
      {:ok, json} -> File.write(path, json)
      {:error, reason} -> {:error, reason}
    end
  end

  defp load_from_json(issue_number) do
    path = Path.join(state_dir(), "round_run_#{issue_number}.json")

    with {:ok, json} <- File.read(path),
         {:ok, data} <- Jason.decode(json) do
      run = %__MODULE__{
        issue_number: data["issue_number"],
        phase: String.to_existing_atom(data["phase"]),
        expected_speakers: Enum.map(data["expected_speakers"], &String.to_existing_atom/1),
        completed_speakers: Enum.map(data["completed_speakers"], &String.to_existing_atom/1),
        last_comment_ids: data["last_comment_ids"],
        satisfaction_map:
          Map.new(data["satisfaction_map"], fn {k, v} ->
            {String.to_existing_atom(k), String.to_existing_atom(v)}
          end),
        retry_count: data["retry_count"],
        updated_at: parse_datetime(data["updated_at"]),
        coordinator:
          if(data["coordinator"], do: String.to_existing_atom(data["coordinator"]), else: nil),
        coordinator_lease_expires_at: parse_datetime_nullable(data["coordinator_lease_expires_at"]),
        last_progress_at: parse_datetime_nullable(data["last_progress_at"]),
        suspended_phase:
          if(data["suspended_phase"],
            do: String.to_existing_atom(data["suspended_phase"]),
            else: nil
          ),
        takeover_count: Map.get(data, "takeover_count", 0)
      }

      {:ok, run}
    else
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end

  defp parse_datetime_nullable(nil), do: nil
  defp parse_datetime_nullable(str), do: parse_datetime(str)

  # ------------------------------------------------------------------
  # Comment parsing
  # ------------------------------------------------------------------

  # Maps the comment header prefix to the agent atom.
  @agent_headers [
    {"## Claude IC", :claude_ic},
    {"## Codex", :codex},
    {"## Gemini", :gemini}
  ]

  @doc false
  def parse_comments(comments) do
    {completed, sat_map, ids} =
      Enum.reduce(comments, {[], %{}, []}, fn comment, {comp, sat, ids} ->
        body = Map.get(comment, "body", "")
        id = Map.get(comment, "id", "") |> to_string()

        case detect_agent(body) do
          nil ->
            {comp, sat, ids}

          agent ->
            satisfaction = Satisfaction.parse_marker(body)
            sat = if satisfaction, do: Map.put(sat, agent, label_to_atom(satisfaction)), else: sat
            {Enum.uniq([agent | comp]), sat, [id | ids]}
        end
      end)

    {Enum.reverse(completed), sat_map, Enum.reverse(ids)}
  end

  defp detect_agent(body) do
    Enum.find_value(@agent_headers, nil, fn {header, atom} ->
      if String.starts_with?(body, header), do: atom
    end)
  end

  defp label_to_atom("satisfied"), do: :satisfied
  defp label_to_atom("satisfied-conditional"), do: :satisfied_conditional
  defp label_to_atom("needs-more-evidence"), do: :needs_more_evidence
  defp label_to_atom(_), do: nil

  # ------------------------------------------------------------------
  # Phase inference
  # ------------------------------------------------------------------

  defp infer_phase(labels, issue) do
    state = Map.get(issue, "state", "open")

    cond do
      state == "closed" -> :closed
      "needs-human-review" in labels -> :needs_human_review
      "needs-human-input" in labels -> :needs_human_input
      "coordinator-unavailable" in labels -> :coordinator_unavailable
      true -> :awaiting_turns
    end
  end

  defp extract_label_names(%{"labels" => labels}) when is_list(labels) do
    Enum.map(labels, fn
      %{"name" => name} -> name
      name when is_binary(name) -> name
      _ -> ""
    end)
  end

  defp extract_label_names(_), do: []
end

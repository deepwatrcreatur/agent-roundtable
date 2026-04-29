defmodule Roundtable.Orchestrator do
  @moduledoc """
  Phase state machine orchestrator for roundtable discussions.

  ## Architecture

  Orchestration is split into two concerns:

  - `step/3` — **pure**. Takes the current `RoundRun` + GitHub issue snapshot +
    options, returns `{next_run, [effect]}`. No I/O. Fully unit-testable with
    fixture data.

  - `apply_effects/2` — **impure**. Executes a list of effects (gh CLI calls,
    CLI agent invocations, event callbacks). Returns `:ok`.

  The driver loop in `run_issue_loop/2` fetches a fresh issue snapshot,
  syncs the `RoundRun` from comments, calls `step/3`, persists the updated
  run, applies effects, then repeats until a terminal phase is reached.

  ## Phase transitions

      :awaiting_turns
        pending agents remain        → emit {:run_agent, agent, n}
        all done, round < max_rounds → :triage_missing_markers
        all done, max_rounds reached → :needs_human_review

      :triage_missing_markers
        all markers present          → :consensus_check
        some missing                 → emit {:triage_agent, ...} per missing agent

      :consensus_check
        all satisfied/conditional    → :closed
        any needs-more-evidence      → :awaiting_turns (next round, reset speakers)
        max_rounds reached           → :needs_human_review

      :coordinator_unavailable
        standby available            → takeover, resume suspended_phase
        no standby, max not reached  → :needs_human_input
        max takeovers reached        → :needs_human_review

      :needs_human_input             (HITL interrupt — resume via LiveView)
      :closed                        (terminal)
      :needs_human_review            (terminal)

  ## Effect types

      {:run_agent,    agent, issue_number}
      {:triage_agent, agent, issue_number, comment_text}
      {:gh_comment,   issue_number, body}
      {:gh_label,     issue_number, add :: [String.t()], remove :: [String.t()]}
      {:gh_close,     issue_number, comment}
      {:notify,       event}
  """

  alias Roundtable.Actions.{Gh, RunCliAgent, DiscussionGit}
  alias Roundtable.{DiscussionRepo, Satisfaction, Prompt, RoundRun, Telemetry}

  @default_agents [:codex, :gemini, :claude_ic]
  @default_max_rounds 5
  @terminal_phases [:closed, :needs_human_review, :needs_human_input]
  @default_standby_coordinators [:codex, :gemini]
  @default_coordinator_lease_seconds 300
  @default_max_takeovers 2

  @label_conflicts %{
    "satisfied" => ["needs-more-evidence", "satisfied-conditional"],
    "satisfied-conditional" => ["needs-more-evidence", "satisfied"],
    "needs-more-evidence" => ["satisfied", "satisfied-conditional"]
  }

  @type effect ::
          {:run_agent, atom(), pos_integer()}
          | {:triage_agent, atom(), pos_integer(), String.t()}
          | {:gh_comment, pos_integer(), String.t()}
          | {:gh_label, pos_integer(), [String.t()], [String.t()]}
          | {:gh_close, pos_integer(), String.t()}
          | {:notify, term()}

  @type question :: %{
          id: String.t(),
          issue_number: pos_integer(),
          state: :open | :satisfied | :needs_human_review
        }

  @type result :: %{
          id: String.t(),
          issue_number: pos_integer(),
          state: :satisfied | :needs_human_review
        }

  # ------------------------------------------------------------------
  # Public entry points
  # ------------------------------------------------------------------

  @doc """
  Runs the full discussion for all questions sequentially.
  """
  @spec run(String.t(), [question()], keyword()) :: [result()]
  def run(brief_path, questions, opts \\ []) do
    brief = File.read!(brief_path)
    agents = Keyword.get(opts, :agents, @default_agents)
    max_rounds = Keyword.get(opts, :max_rounds, @default_max_rounds)
    gh_config = build_gh_config(opts)

    Enum.map(questions, fn q ->
      run_question(q, brief, agents, max_rounds, gh_config, opts)
    end)
  end

  @doc """
  Runs a single question through phases to completion.
  """
  @spec run_question(question(), String.t(), [atom()], pos_integer(), map(), keyword()) ::
          result()
  def run_question(question, brief, agents, max_rounds, gh_config, opts \\ []) do
    notify(opts, {:question_start, question.id, question.issue_number})

    run =
      case RoundRun.load(question.issue_number) do
        {:ok, existing} -> existing
        {:error, :not_found} -> RoundRun.new(question.issue_number, agents)
      end

    context = %{
      brief: brief,
      gh_config: gh_config,
      opts: Keyword.merge(opts, max_rounds: max_rounds, agents: agents)
    }

    result_run = run_issue_loop(run, context)

    result = %{question | state: phase_to_state(result_run.phase)}
    notify(opts, {:question_done, question.id, result.state})
    result
  end

  # ------------------------------------------------------------------
  # File-based entry point (discussion repo model — Protocol Update 10)
  # ------------------------------------------------------------------

  @doc """
  Run the full discussion for a `DiscussionRepo`.

  Reads `BRIEF.md` and `roundtable.toml` from the repo, derives questions from
  the brief, runs each question through rounds, and commits round files after
  each round closes. `DECISION.md` is updated after each question reaches
  consensus.

  ## Options

  All options from `run/3` are accepted and take precedence over values in
  `roundtable.toml`.

  ## GitHub Issues overlay

  GitHub Issues are used only when `repo.issues_enabled` is `true`. Otherwise
  the discussion lives entirely in committed files and this function requires
  no `gh` CLI access.
  """
  @spec run_with_repo(DiscussionRepo.t(), keyword()) ::
          {:ok, [map()]} | {:error, term()}
  def run_with_repo(%DiscussionRepo{} = repo, opts \\ []) do
    with {:ok, brief} <- DiscussionGit.read_brief(repo),
         {:ok, config} <- DiscussionGit.read_config(repo) do
      agents     = Keyword.get(opts, :agents, config.agents)
      max_rounds = Keyword.get(opts, :max_rounds, config.max_rounds)
      questions  = parse_questions_from_brief(brief)

      results =
        questions
        |> Enum.with_index(1)
        |> Enum.map(fn {question, q_idx} ->
          run_question_with_repo(repo, question, q_idx, brief, agents, max_rounds, opts)
        end)

      {:ok, results}
    end
  end

  # Run one question through all rounds in the file-based model.
  defp run_question_with_repo(repo, question, q_idx, brief, agents, max_rounds, opts) do
    notify(opts, {:question_start, question.id, q_idx})

    repo_path = repo.local_path

    run =
      case RoundRun.load(q_idx) do
        {:ok, existing} -> existing
        {:error, :not_found} ->
          RoundRun.new(q_idx, agents, discussion_repo_path: repo_path)
      end

    context = %{
      repo: repo,
      brief: brief,
      question: question,
      opts: Keyword.merge(opts, max_rounds: max_rounds, agents: agents)
    }

    {result_run, _buffer, _repo} = run_repo_loop(run, "", repo, context)
    result = %{id: question.id, q_idx: q_idx, state: phase_to_state(result_run.phase)}
    notify(opts, {:question_done, question.id, result.state})
    result
  end

  # The file-based step/apply loop. Carries the round buffer as state.
  defp run_repo_loop(run, buffer, repo, context) do
    if run.phase in @terminal_phases do
      {run, buffer, repo}
    else
      synthetic_issue = build_synthetic_issue(run, buffer)
      {next_run, effects} = step(run, synthetic_issue, context.opts)
      RoundRun.persist(next_run)

      {final_run, final_buffer, final_repo} =
        Enum.reduce(effects, {next_run, buffer, repo}, fn effect, {r, b, rp} ->
          apply_repo_effect(effect, r, b, rp, context)
        end)

      run_repo_loop(final_run, final_buffer, final_repo, context)
    end
  end

  # Apply one effect in the file-based model.
  # Returns {updated_run, updated_buffer, updated_repo}.
  defp apply_repo_effect({:run_agent, agent, _q_idx}, run, buffer, repo, context) do
    opts     = context.opts
    repo_root = Keyword.get(opts, :repo_root, File.cwd!())
    round_n  = run.retry_count
    q_idx    = run.issue_number
    Telemetry.agent_turn(agent, q_idx, round_n)

    prompt = build_file_prompt(context.brief, buffer, agent)

    case RunCliAgent.run(%{agent: cli_agent_atom(agent), prompt: prompt, repo_root: repo_root}, %{}) do
      {:ok, %{stdout: raw}} ->
        text = extract_text(raw, agent)
        contribution = "\n## #{agent_name(agent)}\n\n#{text}\n"
        new_buffer = buffer <> contribution

        {label, method} = detect_or_triage_label_text(q_idx, text, agent, repo_root, opts)
        Telemetry.satisfaction_parse(agent, label || "nil", method)
        sat = label_string_to_atom(label)

        updated_run = RoundRun.mark_speaker_done(run, agent, sat)
        notify(opts, {:agent_done, agent, q_idx})

        # Optional Gh overlay
        if repo.issues_enabled do
          gh_config = build_gh_config(opts)
          comment_body = format_comment(agent, text)
          Telemetry.gh_comment(q_idx, agent, byte_size(comment_body))
          Gh.comment_issue(q_idx, comment_body, gh_config)
          if label, do: apply_label(q_idx, label, gh_config)
        end

        {updated_run, new_buffer, repo}

      {:error, reason} ->
        notify(opts, {:agent_error, agent, reason})
        {run, buffer, repo}
    end
  end

  defp apply_repo_effect({:triage_agent, agent, q_idx, comment_text}, run, buffer, repo, context) do
    opts      = context.opts
    repo_root = Keyword.get(opts, :repo_root, File.cwd!())
    label     = triage_with_ic(q_idx, comment_text, agent, %{repo_root: repo_root}, opts)
    sat       = label_string_to_atom(label)
    Telemetry.satisfaction_parse(agent, label || "nil", :triage)

    updated_run = RoundRun.mark_speaker_done(run, agent, sat)

    if repo.issues_enabled and label do
      apply_label(q_idx, label, build_gh_config(opts))
    end

    {updated_run, buffer, repo}
  end

  defp apply_repo_effect({:notify, {:round_complete, _q_idx}}, run, buffer, repo, context) do
    opts  = context.opts
    round = run.retry_count - 1
    slug  = String.downcase(String.replace(context.question.id, ~r/[^a-z0-9]+/i, "-"))

    case DiscussionGit.commit_round(repo, round, slug, buffer) do
      {:ok, updated_repo} ->
        notify(opts, {:round_committed, round, slug})
        {run, "", updated_repo}

      {:error, reason} ->
        notify(opts, {:commit_error, reason})
        {run, "", repo}
    end
  end

  defp apply_repo_effect({:gh_close, q_idx, comment}, run, buffer, repo, context) do
    opts = context.opts
    decision_section = build_decision_section(context.question, run)

    updated_repo =
      case DiscussionGit.append_decision(repo, decision_section) do
        {:ok, r} -> r
        {:error, _} -> repo
      end

    Telemetry.issue_close(q_idx, run.retry_count, :consensus)
    notify(opts, {:question_satisfied, context.question.id, run.retry_count})

    if updated_repo.issues_enabled do
      gh_config = build_gh_config(opts)
      Gh.comment_issue(q_idx, comment, gh_config)
      Gh.close_issue(q_idx, [], gh_config)
    end

    {run, buffer, updated_repo}
  end

  defp apply_repo_effect({:gh_comment, q_idx, body}, run, buffer, repo, context) do
    if repo.issues_enabled do
      Gh.comment_issue(q_idx, body, build_gh_config(context.opts))
    end
    {run, buffer, repo}
  end

  defp apply_repo_effect({:gh_label, q_idx, add, remove}, run, buffer, repo, context) do
    if repo.issues_enabled do
      Gh.edit_issue_labels(q_idx, add, remove, build_gh_config(context.opts))
    end
    {run, buffer, repo}
  end

  defp apply_repo_effect({:notify, event}, run, buffer, repo, context) do
    notify(context.opts, event)
    {run, buffer, repo}
  end

  defp apply_repo_effect(_unknown, run, buffer, repo, _context),
    do: {run, buffer, repo}

  # Build a synthetic issue map from RoundRun + round buffer for step/3.
  defp build_synthetic_issue(run, buffer) do
    %{
      "state" => if(run.phase == :closed, do: "closed", else: "open"),
      "labels" => satisfaction_map_to_labels(run.satisfaction_map),
      "comments" => parse_buffer_to_comments(buffer)
    }
  end

  defp satisfaction_map_to_labels(sat_map) do
    sat_map
    |> Map.values()
    |> Enum.map(fn
      :satisfied -> "satisfied"
      :satisfied_conditional -> "satisfied-conditional"
      :needs_more_evidence -> "needs-more-evidence"
    end)
    |> Enum.uniq()
  end

  defp parse_buffer_to_comments(buffer) do
    ~r/^## (.+)$/m
    |> Regex.split(buffer, include_captures: true)
    |> Enum.chunk_every(2)
    |> Enum.flat_map(fn
      [header, body] -> [%{"id" => header, "body" => header <> "\n\n" <> String.trim(body)}]
      _ -> []
    end)
  end

  # Build a prompt for the file-based model (brief + accumulated round text).
  defp build_file_prompt(brief, buffer, agent) do
    role = agent_role(agent)
    prior = if buffer == "", do: "", else: "\n\n## Prior contributions this round\n\n#{buffer}"

    """
    #{role}

    ## Discussion Brief

    #{String.slice(brief, 0, 8000)}
    #{prior}

    ## Your turn

    Please respond with your position. End your response with one of:
    - `[satisfied]`
    - `[satisfied-conditional: <condition>]`
    - `[needs more evidence: <what>]`
    """
  end

  # Build the decision section committed to DECISION.md after consensus.
  defp build_decision_section(question, run) do
    sat_lines =
      Enum.map(run.satisfaction_map, fn {agent, result} ->
        "- **#{agent_name(agent)}**: #{result}"
      end)
      |> Enum.join("\n")

    """

    ## #{question.id} (Round #{run.retry_count}, #{Date.to_iso8601(Date.utc_today())})

    Consensus reached after #{run.retry_count} round(s).

    ### Satisfaction summary

    #{sat_lines}
    """
  end

  # Parse ### Q\\d+ section headings from a BRIEF.md string.
  defp parse_questions_from_brief(brief) do
    ~r/###\s+(Q\d+[^\n]*)/
    |> Regex.scan(brief)
    |> Enum.map(fn [_, title] ->
      id = case Regex.run(~r/Q\d+/, title) do
        [match | _] -> match
        _ -> title
      end
      %{id: id, title: String.trim(title)}
    end)
  end

  defp label_string_to_atom("satisfied"), do: :satisfied
  defp label_string_to_atom("satisfied-conditional"), do: :satisfied_conditional
  defp label_string_to_atom("needs-more-evidence"), do: :needs_more_evidence
  defp label_string_to_atom(_), do: nil

  defp detect_or_triage_label_text(q_idx, text, agent, repo_root, opts) do
    case Satisfaction.parse_marker(text) do
      nil ->
        label = triage_with_ic(q_idx, text, agent, %{repo_root: repo_root}, opts)
        {label, :triage}
      label ->
        {label, :marker}
    end
  end

  # Run the IC triage sub-agent to classify a response that has no inline marker.
  # Returns a label string ("satisfied", "satisfied-conditional", "needs-more-evidence")
  # or nil on failure. No I/O beyond the agent call.
  defp triage_with_ic(_q_idx, text, agent, context, opts) do
    repo_root = Map.get(context, :repo_root, File.cwd!())

    triage_prompt = """
    You are an Incident Commander reviewing an agent's response in a roundtable discussion.
    Classify the response below with EXACTLY ONE of:
      satisfied
      satisfied-conditional
      needs-more-evidence

    Respond with only that one word/phrase on a single line. No explanation.

    Agent response:
    #{String.slice(text, 0, 2000)}
    """

    case RunCliAgent.run(%{agent: :claude, prompt: triage_prompt, repo_root: repo_root}, %{}) do
      {:ok, %{stdout: raw}} ->
        triage_text = extract_text(raw, :claude_ic)

        result =
          cond do
            String.contains?(triage_text, "needs-more-evidence") -> "needs-more-evidence"
            String.contains?(triage_text, "satisfied-conditional") -> "satisfied-conditional"
            String.contains?(triage_text, "satisfied") -> "satisfied"
            true ->
              notify(opts, {:triage_unclear, triage_text})
              nil
          end

        if result, do: Telemetry.satisfaction_parse(agent, result, :triage)
        result

      {:error, reason} ->
        notify(opts, {:triage_error, agent, reason})
        nil
    end
  end

  # Apply a satisfaction label to a GitHub issue, removing conflicting labels.
  defp apply_label(issue_number, label, gh_config) do
    remove = Map.get(@label_conflicts, label, [])
    Gh.edit_issue_labels(issue_number, [label], remove, gh_config)
  end

  # ------------------------------------------------------------------
  # Pure step function
  # ------------------------------------------------------------------

  @doc """
  Pure phase transition function.

  Given the current `RoundRun` (already synced from GitHub), the current
  GitHub issue map, and options, returns `{next_run, [effect]}`.

  No I/O. Safe to call from tests with fixture data.
  """
  @spec step(RoundRun.t(), map(), keyword()) :: {RoundRun.t(), [effect()]}
  def step(%RoundRun{phase: :awaiting_turns} = run, _issue, opts) do
    max_rounds = Keyword.get(opts, :max_rounds, @default_max_rounds)
    pending = run.expected_speakers -- run.completed_speakers

    cond do
      pending != [] ->
        [next_agent | _] = pending
        {run, [{:run_agent, next_agent, run.issue_number}]}

      run.retry_count >= max_rounds ->
        next_run = RoundRun.put_phase(run, :needs_human_review)
        comment =
          "**Roundtable:** Max rounds (#{max_rounds}) reached without consensus. " <>
            "Flagging for human review."

        {next_run,
         [
           {:gh_comment, run.issue_number, comment},
           {:gh_label, run.issue_number, ["needs-human-review"], []},
           {:notify, {:question_max_rounds, run.issue_number}}
         ]}

      true ->
        next_run =
          run
          |> Map.put(:retry_count, run.retry_count + 1)
          |> RoundRun.put_phase(:triage_missing_markers)

        {next_run, [{:notify, {:round_complete, run.issue_number}}]}
    end
  end

  def step(%RoundRun{phase: :triage_missing_markers} = run, issue, _opts) do
    missing = run.expected_speakers -- Map.keys(run.satisfaction_map)

    if missing == [] do
      {RoundRun.put_phase(run, :consensus_check), []}
    else
      comments = Map.get(issue, "comments", [])

      effects =
        Enum.flat_map(missing, fn agent ->
          case find_latest_agent_comment(comments, agent) do
            nil -> []
            text -> [{:triage_agent, agent, run.issue_number, text}]
          end
        end)

      if effects == [] do
        # No comments to triage from — proceed to consensus with what we have
        {RoundRun.put_phase(run, :consensus_check), []}
      else
        {run, effects}
      end
    end
  end

  def step(%RoundRun{phase: :consensus_check} = run, _issue, opts) do
    max_rounds = Keyword.get(opts, :max_rounds, @default_max_rounds)
    labels = run.satisfaction_map |> Map.values() |> Enum.map(&satisfaction_to_label/1)
    consensus = Satisfaction.consensus?(labels)
    Telemetry.consensus_check(run.issue_number, labels, consensus)

    cond do
      consensus ->
        Telemetry.issue_close(run.issue_number, run.retry_count, :consensus)
        next_run = RoundRun.put_phase(run, :closed)
        comment = "All agents satisfied. Closed after #{run.retry_count} round(s)."

        {next_run,
         [
           {:gh_close, run.issue_number, comment},
           {:notify, {:question_satisfied, run.issue_number, run.retry_count}}
         ]}

      run.retry_count >= max_rounds ->
        Telemetry.issue_close(run.issue_number, run.retry_count, :max_rounds)
        next_run = RoundRun.put_phase(run, :needs_human_review)
        comment =
          "**Roundtable:** Max rounds (#{max_rounds}) reached without consensus. " <>
            "Flagging for human review."

        {next_run,
         [
           {:gh_comment, run.issue_number, comment},
           {:gh_label, run.issue_number, ["needs-human-review"], []},
           {:notify, {:question_max_rounds, run.issue_number}}
         ]}

      true ->
        # Reset speakers for the next round; back to awaiting_turns
        next_run =
          run
          |> Map.put(:completed_speakers, [])
          |> Map.put(:satisfaction_map, %{})
          |> RoundRun.put_phase(:awaiting_turns)

        {next_run, [{:notify, {:round_start, run.issue_number, run.retry_count + 1}}]}
    end
  end

  def step(%RoundRun{phase: :coordinator_unavailable} = run, _issue, opts) do
    standbys = Keyword.get(opts, :standby_coordinators, @default_standby_coordinators)
    max_takeovers = Keyword.get(opts, :max_takeovers, @default_max_takeovers)
    available = standbys -- [run.coordinator]

    cond do
      run.takeover_count >= max_takeovers ->
        Telemetry.issue_close(run.issue_number, run.retry_count, :max_rounds)
        next_run = RoundRun.put_phase(run, :needs_human_review)
        comment =
          "**Roundtable:** Coordinator unavailable and max takeovers (#{max_takeovers}) reached. " <>
            "Flagging for human review."

        {next_run,
         [
           {:gh_comment, run.issue_number, comment},
           {:gh_label, run.issue_number, ["needs-human-review"], ["coordinator-unavailable"]},
           {:notify, {:coordinator_max_takeovers, run.issue_number}}
         ]}

      available != [] ->
        [standby | _] = available
        prev = run.coordinator

        case RoundRun.takeover(run, standby) do
          {:ok, resumed_run} ->
            Telemetry.coordinator_takeover(run.issue_number, prev, standby)
            note =
              "**Roundtable:** Coordinator #{inspect(prev)} timed out. " <>
                "#{inspect(standby)} taking over from phase `#{run.suspended_phase}`."

            {resumed_run,
             [
               {:gh_comment, run.issue_number, note},
               {:gh_label, run.issue_number, [], ["coordinator-unavailable"]},
               {:notify, {:coordinator_takeover, run.issue_number, standby}}
             ]}

          {:error, :no_suspended_phase} ->
            next_run = RoundRun.put_phase(run, :needs_human_input)

            {next_run,
             [
               {:gh_label, run.issue_number, ["needs-human-input"], ["coordinator-unavailable"]},
               {:notify, {:coordinator_unavailable, run.issue_number}}
             ]}
        end

      true ->
        # No standbys configured — escalate to human
        next_run = RoundRun.put_phase(run, :needs_human_input)

        {next_run,
         [
           {:gh_label, run.issue_number, ["needs-human-input"], ["coordinator-unavailable"]},
           {:notify, {:coordinator_unavailable, run.issue_number}}
         ]}
    end
  end

  def step(%RoundRun{phase: phase} = run, _issue, _opts)
      when phase in @terminal_phases do
    {run, []}
  end

  # ------------------------------------------------------------------
  # Effect executor
  # ------------------------------------------------------------------

  @doc """
  Applies a list of effects produced by `step/3`.

  `context` must contain `:brief`, `:gh_config`, and `:opts`. The
  `:issue` key should hold the current GitHub issue map (used to build
  agent prompts). `:round` (optional, default 1) is threaded into the
  `agent_turn` telemetry span.
  """
  @spec apply_effects([effect()], map()) :: :ok
  def apply_effects([], _context), do: :ok

  def apply_effects([effect | rest], context) do
    apply_effect(effect, context)
    apply_effects(rest, context)
  end

  # ------------------------------------------------------------------
  # Driver loop (private)
  # ------------------------------------------------------------------

  defp run_issue_loop(%RoundRun{phase: phase} = run, _context)
       when phase in @terminal_phases,
       do: run

  defp run_issue_loop(run, context) do
    Telemetry.issue_poll(run.issue_number, context.gh_config[:repo])

    case Gh.view_issue(run.issue_number, [], context.gh_config) do
      {:error, reason} ->
        notify(context.opts, {:gh_error, :view_issue, reason})
        fallback = RoundRun.put_phase(run, :needs_human_review)
        RoundRun.persist(fallback)
        fallback

      {:ok, issue} ->
        synced = sync_from_issue(run, issue)
        checked = maybe_detect_coordinator_timeout(synced)
        {next_run, effects} = step(checked, issue, context.opts)
        RoundRun.persist(next_run)
        apply_effects(effects, Map.put(context, :issue, issue))
        run_issue_loop(next_run, context)
    end
  end

  # If the coordinator lease has expired, enter :coordinator_unavailable before stepping.
  defp maybe_detect_coordinator_timeout(run) do
    now = DateTime.utc_now()

    if run.phase not in @terminal_phases and
         run.phase != :coordinator_unavailable and
         RoundRun.coordinator_timed_out?(run, now) do
      Telemetry.coordinator_timeout(run.issue_number, run.coordinator)
      RoundRun.enter_coordinator_unavailable(run)
    else
      run
    end
  end

  # ------------------------------------------------------------------
  # Individual effect handlers (private)
  # ------------------------------------------------------------------

  defp apply_effect({:run_agent, agent, issue_number}, context) do
    issue = Map.get(context, :issue, %{})
    gh_config = context.gh_config
    opts = context.opts
    brief = context.brief
    repo_root = Map.get(gh_config, :repo_root, File.cwd!())
    round = Keyword.get(opts, :_current_round, 1)
    lease_seconds = Keyword.get(opts, :coordinator_lease_seconds, @default_coordinator_lease_seconds)

    # IC claims coordinator lease; any other agent triggers a heartbeat.
    update_coordinator_lease(agent, issue_number, lease_seconds)

    prompt = Prompt.build(brief, issue, agent_role(agent))
    Telemetry.agent_turn(agent, issue_number, round)

    case RunCliAgent.run(
           %{agent: cli_agent_atom(agent), prompt: prompt, repo_root: repo_root},
           %{}
         ) do
      {:ok, %{stdout: raw}} ->
        text = extract_text(raw, agent)
        comment_body = format_comment(agent, text)
        Telemetry.gh_comment(issue_number, agent, byte_size(comment_body))

        case Gh.comment_issue(issue_number, comment_body, gh_config) do
          :ok ->
            # Attempt inline satisfaction detection; apply label immediately if found.
            # Agents without a marker will be handled in :triage_missing_markers.
            case Satisfaction.parse_marker(text) do
              nil ->
                :ok

              label ->
                Telemetry.satisfaction_parse(agent, label, :marker)
                remove = Map.get(@label_conflicts, label, [])
                Gh.edit_issue_labels(issue_number, [label], remove, gh_config)
            end

          {:error, reason} ->
            notify(opts, {:gh_error, :comment_issue, reason})
        end

      {:error, reason} ->
        notify(opts, {:agent_error, agent, reason})
    end
  end

  defp apply_effect({:triage_agent, agent, issue_number, text}, context) do
    gh_config = context.gh_config
    opts = context.opts
    repo_root = Map.get(gh_config, :repo_root, File.cwd!())

    result = triage_with_ic(issue_number, text, agent, %{repo_root: repo_root}, opts)
    Telemetry.ic_triage(issue_number, result)

    if result do
      # Post a short IC triage comment so sync_from_issue picks up the marker.
      triage_comment =
        "## Claude IC\n\nIC triage for #{agent_name(agent)}: #{result}\n\n[#{result}]"

      Telemetry.gh_comment(issue_number, :claude_ic, byte_size(triage_comment))
      Gh.comment_issue(issue_number, triage_comment, gh_config)
      apply_label(issue_number, result, gh_config)
    end
  end

  defp apply_effect({:gh_comment, issue_number, body}, context) do
    case Gh.comment_issue(issue_number, body, context.gh_config) do
      :ok -> :ok
      {:error, reason} -> notify(context.opts, {:gh_error, :comment_issue, reason})
    end
  end

  defp apply_effect({:gh_label, issue_number, add, remove}, context) do
    case Gh.edit_issue_labels(issue_number, add, remove, context.gh_config) do
      :ok -> :ok
      {:error, reason} -> notify(context.opts, {:gh_error, :edit_labels, reason})
    end
  end

  defp apply_effect({:gh_close, issue_number, comment}, context) do
    case Gh.close_issue(issue_number, [comment: comment], context.gh_config) do
      :ok -> :ok
      {:error, reason} -> notify(context.opts, {:gh_error, :close_issue, reason})
    end
  end

  defp apply_effect({:notify, event}, context) do
    notify(context.opts, event)
  end

  # ------------------------------------------------------------------
  # State sync helpers (pure)
  # ------------------------------------------------------------------

  # Updates completed_speakers and satisfaction_map from current issue comments.
  # Called at the start of each driver loop iteration so step() always sees
  # up-to-date state without performing any I/O.
  defp sync_from_issue(run, issue) do
    comments = Map.get(issue, "comments", [])
    {completed, sat_map, comment_ids} = RoundRun.parse_comments(comments)

    %{
      run
      | completed_speakers: completed,
        satisfaction_map: sat_map,
        last_comment_ids: comment_ids
    }
  end

  # Returns the text of the most recent comment posted by `agent`, or nil.
  defp find_latest_agent_comment(comments, agent) do
    agent_header = "## #{agent_name(agent)}"

    comments
    |> Enum.filter(fn c -> String.starts_with?(Map.get(c, "body", ""), agent_header) end)
    |> List.last()
    |> case do
      nil -> nil
      comment -> Map.get(comment, "body", "")
    end
  end

  # ------------------------------------------------------------------
  # Coordinator lease helpers
  # ------------------------------------------------------------------

  # IC claims a fresh coordinator lease; non-IC agents heartbeat the active lease.
  # Loads the run from ETS, updates, and persists — all side-effectful.
  defp update_coordinator_lease(agent, issue_number, lease_seconds) do
    case RoundRun.load(issue_number) do
      {:ok, run} ->
        updated =
          if agent == :claude_ic do
            case RoundRun.claim_coordinator(run, :claude_ic, lease_seconds) do
              {:ok, claimed} ->
                Telemetry.coordinator_lease_claim(
                  issue_number,
                  :claude_ic,
                  claimed.coordinator_lease_expires_at
                )

                claimed

              {:error, :coordinator_active} ->
                run
            end
          else
            refreshed = RoundRun.heartbeat(run, lease_seconds)
            Telemetry.coordinator_heartbeat(issue_number, refreshed.coordinator)
            refreshed
          end

        RoundRun.persist(updated)

      {:error, _} ->
        :ok
    end
  end

  # ------------------------------------------------------------------
  # Satisfaction helpers
  # ------------------------------------------------------------------

  defp satisfaction_to_label(:satisfied), do: "satisfied"
  defp satisfaction_to_label(:satisfied_conditional), do: "satisfied-conditional"
  defp satisfaction_to_label(:needs_more_evidence), do: "needs-more-evidence"
  defp satisfaction_to_label(other), do: to_string(other)

  # ------------------------------------------------------------------
  # Agent config helpers
  # ------------------------------------------------------------------

  @agent_roles %{
    codex:
      "You are Codex, an OpenAI-based agent with expertise in API design, code architecture, " <>
        "and implementation detail. Bring your perspective as an independent reviewer.",
    gemini:
      "You are Gemini, a Google-based agent with expertise in research, context synthesis, " <>
        "and system-level reasoning. Bring your perspective as an independent reviewer.",
    claude_ic:
      "You are the Incident Commander (IC), a Claude-based agent responsible for synthesising " <>
        "positions, identifying gaps, and deciding whether the question has reached consensus. " <>
        "You speak last each round."
  }

  defp agent_role(agent), do: Map.get(@agent_roles, agent, "You are an independent AI reviewer.")

  defp cli_agent_atom(:claude_ic), do: :claude
  defp cli_agent_atom(agent), do: agent

  defp agent_name(:claude_ic), do: "Claude IC"
  defp agent_name(:codex), do: "Codex"
  defp agent_name(:gemini), do: "Gemini"
  defp agent_name(other), do: other |> to_string() |> String.capitalize()

  defp format_comment(agent, text), do: "## #{agent_name(agent)}\n\n#{text}"

  # ------------------------------------------------------------------
  # Text extraction from agent JSON output
  # ------------------------------------------------------------------

  defp extract_text(raw, _agent) do
    case JSON.decode(raw) do
      {:ok, %{"result" => text}} when is_binary(text) -> text
      {:ok, %{"content" => text}} when is_binary(text) -> text
      {:ok, %{"message" => text}} when is_binary(text) -> text
      {:ok, %{"text" => text}} when is_binary(text) -> text
      {:ok, data} when is_list(data) -> extract_from_list(data)
      _ -> raw
    end
  end

  defp extract_from_list(items) do
    items
    |> Enum.filter(fn
      %{"type" => "text"} -> true
      %{"role" => "assistant"} -> true
      _ -> false
    end)
    |> Enum.map(fn
      %{"text" => t} -> t
      %{"content" => t} when is_binary(t) -> t
      _ -> ""
    end)
    |> Enum.join("\n")
    |> then(fn s -> if s == "", do: inspect(items), else: s end)
  end

  # ------------------------------------------------------------------
  # Config + misc helpers
  # ------------------------------------------------------------------

  defp phase_to_state(:closed), do: :satisfied
  defp phase_to_state(_), do: :needs_human_review

  defp build_gh_config(opts) do
    %{}
    |> maybe_put(:repo, Keyword.get(opts, :repo))
    |> maybe_put(:repo_root, Keyword.get(opts, :repo_root))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp notify(opts, event) do
    case Keyword.get(opts, :on_event) do
      nil -> :ok
      fun when is_function(fun, 1) -> fun.(event)
    end
  end
end

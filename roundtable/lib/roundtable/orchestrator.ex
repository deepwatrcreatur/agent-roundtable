defmodule Roundtable.Orchestrator do
  @moduledoc """
  Core orchestration loop for the roundtable discussion.

  Drives questions through agent rounds until all are satisfied or
  max_rounds is reached. Each question corresponds to one GitHub Issue.

  ## Agent turn order

  Default: `[:codex, :gemini, :claude_ic]` — IC runs last to synthesise.
  `:claude_ic` maps to the `:claude` CLI with an IC role prompt.

  ## Satisfaction detection

  After each agent posts, the orchestrator reads the satisfaction marker
  from the response text and applies it as a GitHub label. If no marker
  is detected, an IC triage call classifies the response.

  Consensus is reached when all active labels include `satisfied` or
  `satisfied-conditional` and none include `needs-more-evidence`.

  ## Events

  Pass `on_event: fn event -> ... end` in opts to receive progress
  notifications. Events: `{:round_start, id, n}`, `{:agent_done, agent, issue}`,
  `{:question_satisfied, id, round}`, `{:question_max_rounds, id}`,
  `{:agent_error, agent, reason}`.
  """

  alias Roundtable.Actions.Gh
  alias Roundtable.Actions.RunCliAgent
  alias Roundtable.Satisfaction
  alias Roundtable.Prompt

  @default_agents [:codex, :gemini, :claude_ic]
  @default_max_rounds 5

  # Maps each satisfaction label to the labels it replaces on the issue.
  @label_conflicts %{
    "satisfied" => ["needs-more-evidence", "satisfied-conditional"],
    "satisfied-conditional" => ["needs-more-evidence", "satisfied"],
    "needs-more-evidence" => ["satisfied", "satisfied-conditional"]
  }

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

  @doc """
  Runs the full discussion for all questions sequentially.

  Returns a list of result maps with `:id`, `:issue_number`, and `:state`.

  ## Options

    * `:repo` — GitHub repo slug (`owner/repo`) passed to `gh`
    * `:agents` — list of agent atoms; defaults to `#{inspect(@default_agents)}`
    * `:max_rounds` — integer; defaults to `#{@default_max_rounds}`
    * `:repo_root` — working directory for CLI agent invocations
    * `:on_event` — `(event -> any)` callback for progress notifications
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
  Runs a single question through rounds to completion.
  """
  @spec run_question(question(), String.t(), [atom()], pos_integer(), map(), keyword()) ::
          result()
  def run_question(question, brief, agents, max_rounds, gh_config, opts \\ []) do
    notify(opts, {:question_start, question.id, question.issue_number})
    result = do_rounds(question, brief, agents, max_rounds, gh_config, opts, 1)
    notify(opts, {:question_done, question.id, result.state})
    result
  end

  # ----- private -----

  defp do_rounds(question, _brief, _agents, max_rounds, gh_config, opts, round)
       when round > max_rounds do
    Gh.comment_issue(
      question.issue_number,
      "**Roundtable:** Max rounds (#{max_rounds}) reached without consensus. Flagging for human review.",
      gh_config
    )

    Gh.edit_issue_labels(question.issue_number, ["needs-human-review"], [], gh_config)
    notify(opts, {:question_max_rounds, question.id})
    %{question | state: :needs_human_review}
  end

  defp do_rounds(question, brief, agents, max_rounds, gh_config, opts, round) do
    notify(opts, {:round_start, question.id, round})

    {:ok, issue} = Gh.view_issue(question.issue_number, [], gh_config)

    final_issue =
      Enum.reduce(agents, issue, fn agent, current_issue ->
        case run_agent_turn(question.issue_number, current_issue, brief, agent, gh_config, opts) do
          {:ok, updated_issue} ->
            updated_issue

          {:error, reason} ->
            notify(opts, {:agent_error, agent, reason})
            current_issue
        end
      end)

    labels = extract_label_names(final_issue)

    if Satisfaction.consensus?(labels) do
      Gh.close_issue(
        question.issue_number,
        [comment: "All agents satisfied. Closed after #{round} round(s)."],
        gh_config
      )

      notify(opts, {:question_satisfied, question.id, round})
      %{question | state: :satisfied}
    else
      do_rounds(question, brief, agents, max_rounds, gh_config, opts, round + 1)
    end
  end

  defp run_agent_turn(issue_number, issue, brief, agent, gh_config, opts) do
    repo_root = Map.get(gh_config, :repo_root, File.cwd!())
    prompt = Prompt.build(brief, issue, agent_role(agent))

    notify(opts, {:agent_start, agent, issue_number})

    params = %{
      agent: cli_agent_atom(agent),
      prompt: prompt,
      repo_root: repo_root
    }

    case RunCliAgent.run(params, %{}) do
      {:ok, %{stdout: raw}} ->
        text = extract_text(raw, agent)
        :ok = Gh.comment_issue(issue_number, format_comment(agent, text), gh_config)
        notify(opts, {:agent_done, agent, issue_number})

        label = detect_or_triage_label(issue_number, text, agent, gh_config, opts)
        apply_label(issue_number, label, gh_config)

        Gh.view_issue(issue_number, [], gh_config)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ------------------------------------------------------------------
  # Label helpers
  # ------------------------------------------------------------------

  defp detect_or_triage_label(issue_number, text, agent, gh_config, opts) do
    case Satisfaction.parse_marker(text) do
      nil ->
        triage_with_ic(issue_number, text, agent, gh_config, opts)

      label ->
        label
    end
  end

  defp triage_with_ic(_issue_number, text, _agent, gh_config, opts) do
    repo_root = Map.get(gh_config, :repo_root, File.cwd!())
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

        cond do
          String.contains?(triage_text, "needs-more-evidence") -> "needs-more-evidence"
          String.contains?(triage_text, "satisfied-conditional") -> "satisfied-conditional"
          String.contains?(triage_text, "satisfied") -> "satisfied"
          true -> notify(opts, {:triage_unclear, triage_text}); nil
        end

      {:error, _} ->
        nil
    end
  end

  defp apply_label(_issue_number, nil, _gh_config), do: :ok

  defp apply_label(issue_number, label, gh_config) do
    remove = Map.get(@label_conflicts, label, [])
    Gh.edit_issue_labels(issue_number, [label], remove, gh_config)
  end

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
  # Agent config helpers
  # ------------------------------------------------------------------

  @agent_roles %{
    codex: "You are Codex, an OpenAI-based agent with expertise in API design, code architecture, and implementation detail. Bring your perspective as an independent reviewer.",
    gemini: "You are Gemini, a Google-based agent with expertise in research, context synthesis, and system-level reasoning. Bring your perspective as an independent reviewer.",
    claude_ic: "You are the Incident Commander (IC), a Claude-based agent responsible for synthesising positions, identifying gaps, and deciding whether the question has reached consensus. You speak last each round."
  }

  defp agent_role(agent), do: Map.get(@agent_roles, agent, "You are an independent AI reviewer.")

  # `:claude_ic` invokes the `:claude` CLI binary
  defp cli_agent_atom(:claude_ic), do: :claude
  defp cli_agent_atom(agent), do: agent

  defp agent_name(:claude_ic), do: "Claude IC"
  defp agent_name(:codex), do: "Codex"
  defp agent_name(:gemini), do: "Gemini"
  defp agent_name(other), do: to_string(other)

  defp format_comment(agent, text) do
    "## #{agent_name(agent)}\n\n#{text}"
  end

  # ------------------------------------------------------------------
  # Issue data helpers
  # ------------------------------------------------------------------

  defp extract_label_names(%{"labels" => labels}) when is_list(labels) do
    Enum.map(labels, fn
      %{"name" => name} -> name
      name when is_binary(name) -> name
      _ -> ""
    end)
  end

  defp extract_label_names(_), do: []

  # ------------------------------------------------------------------
  # Config helpers
  # ------------------------------------------------------------------

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

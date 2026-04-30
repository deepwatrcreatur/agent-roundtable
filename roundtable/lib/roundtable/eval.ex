defmodule Roundtable.Eval do
  @moduledoc """
  Evaluation harness for comparing vaglio multi-agent output against
  single-model baselines.

  Runs the same question through different modes and persists results
  as JSON in `state/eval/`.
  """

  alias Roundtable.Eval.Run
  alias Roundtable.Actions.RunCliAgent

  @agents [:codex, :gemini, :deepseek, :claude_ic]

  # ------------------------------------------------------------------
  # Public API
  # ------------------------------------------------------------------

  @doc """
  Run a question through the full vaglio multi-agent protocol.

  Invokes each agent sequentially (codex, gemini, deepseek, then claude_ic
  as synthesizer), accumulating turns. The IC's output becomes `final_output`.

  ## Options
  - `:agents` — override the agent roster (default: #{inspect(@agents)})
  - `:repo_root` — working directory for CLI agents
  """
  @spec run_vaglio(String.t(), String.t(), keyword()) :: {:ok, Run.t()} | {:error, term()}
  def run_vaglio(question, brief_context, opts \\ []) do
    agents = Keyword.get(opts, :agents, @agents)
    repo_root = Keyword.get(opts, :repo_root, File.cwd!())
    id = Run.generate_id(:vaglio)

    run = %Run{
      id: id,
      question: question,
      brief_context: brief_context,
      mode: :vaglio,
      started_at: DateTime.utc_now()
    }

    {turns, _buffer} =
      Enum.reduce(agents, {[], ""}, fn agent, {acc_turns, acc_buffer} ->
        prompt = build_vaglio_prompt(question, brief_context, acc_buffer, agent)

        case invoke_agent(agent, prompt, repo_root) do
          {:ok, text} ->
            turn = %{agent: Atom.to_string(agent), output: text}
            contribution = "\n## #{agent_label(agent)}\n\n#{text}\n"
            {acc_turns ++ [turn], acc_buffer <> contribution}

          {:error, reason} ->
            turn = %{agent: Atom.to_string(agent), error: inspect(reason)}
            {acc_turns ++ [turn], acc_buffer}
        end
      end)

    # The IC (last agent) output is the final synthesis
    final =
      turns
      |> List.last()
      |> case do
        %{output: text} -> text
        _ -> nil
      end

    completed = %Run{
      run
      | turns: turns,
        final_output: final,
        completed_at: DateTime.utc_now()
    }

    persist(completed)
    {:ok, completed}
  end

  @doc """
  Run a question through a single model baseline.

  ## Modes
  - `:naive` — plain question + context
  - `:structured` — question + full vaglio prompt instructions
  - `:debate` — generate three perspectives then synthesize

  ## Options
  - `:model` — which CLI agent to use (default: `:claude`)
  - `:repo_root` — working directory for CLI agent
  """
  @spec run_single(String.t(), String.t(), :naive | :structured | :debate, keyword()) ::
          {:ok, Run.t()} | {:error, term()}
  def run_single(question, brief_context, mode, opts \\ []) do
    model = Keyword.get(opts, :model, :claude)
    repo_root = Keyword.get(opts, :repo_root, File.cwd!())
    run_mode = :"single_#{mode}"
    id = Run.generate_id(run_mode)

    run = %Run{
      id: id,
      question: question,
      brief_context: brief_context,
      mode: run_mode,
      model: model,
      started_at: DateTime.utc_now()
    }

    prompt = build_single_prompt(question, brief_context, mode)

    case invoke_agent(model, prompt, repo_root) do
      {:ok, text} ->
        completed = %Run{
          run
          | turns: [%{agent: Atom.to_string(model), output: text}],
            final_output: text,
            completed_at: DateTime.utc_now()
        }

        persist(completed)
        {:ok, completed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Persist an Eval.Run to state/eval/ as JSON."
  @spec persist(Run.t()) :: :ok
  def persist(%Run{} = run) do
    dir = eval_dir()
    File.mkdir_p!(dir)
    path = Path.join(dir, "#{run.id}.json")
    File.write!(path, Jason.encode!(Run.to_map(run), pretty: true))
    :ok
  end

  @doc "Load a persisted Eval.Run by ID."
  @spec load(String.t()) :: {:ok, Run.t()} | {:error, :not_found}
  def load(id) do
    path = Path.join(eval_dir(), "#{id}.json")

    with {:ok, json} <- File.read(path),
         {:ok, data} <- Jason.decode(json) do
      {:ok, Run.from_map(data)}
    else
      _ -> {:error, :not_found}
    end
  end

  @doc "List all persisted eval runs, sorted by started_at descending."
  @spec list() :: [Run.t()]
  def list do
    dir = eval_dir()

    case File.ls(dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".json"))
        |> Enum.map(fn file ->
          path = Path.join(dir, file)

          with {:ok, json} <- File.read(path),
               {:ok, data} <- Jason.decode(json) do
            Run.from_map(data)
          else
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.sort_by(& &1.started_at, {:desc, DateTime})

      {:error, _} ->
        []
    end
  end

  @doc """
  Generate blind comparison files for a pair of runs on the same question.

  Writes `output_a.md`, `output_b.md`, and `manifest.json` to
  `state/eval/blind/<run_id>/`. Assignment of A/B is randomised so the
  reader cannot infer which is vaglio.

  Returns `{:ok, dir_path}`.
  """
  @spec blind_compare(Run.t(), Run.t()) :: {:ok, String.t()} | {:error, term()}
  def blind_compare(%Run{question: question_a}, %Run{question: question_b})
      when question_a != question_b do
    {:error, :question_mismatch}
  end

  def blind_compare(%Run{} = run_a, %Run{} = run_b) do
    {first, second} =
      if :rand.uniform() > 0.5,
        do: {run_a, run_b},
        else: {run_b, run_a}

    dir = Path.join([eval_dir(), "blind", run_a.id])
    File.mkdir_p!(dir)

    File.write!(Path.join(dir, "output_a.md"), first.final_output || "")
    File.write!(Path.join(dir, "output_b.md"), second.final_output || "")

    manifest = %{
      a: %{id: first.id, mode: Atom.to_string(first.mode)},
      b: %{id: second.id, mode: Atom.to_string(second.mode)},
      question: first.question
    }

    File.write!(Path.join(dir, "manifest.json"), Jason.encode!(manifest, pretty: true))

    {:ok, dir}
  end

  # ------------------------------------------------------------------
  # Prompt builders
  # ------------------------------------------------------------------

  defp build_vaglio_prompt(question, brief_context, buffer, agent) do
    role = agent_role(agent)
    prior = if buffer == "", do: "", else: "\n\n## Prior contributions this round\n\n#{buffer}"

    """
    #{role}

    ## Discussion Brief

    #{String.slice(brief_context, 0, 8000)}

    ## Question

    #{question}
    #{prior}

    ## Your turn

    Please respond with your position. Include typed provenance markers \
    ([observed], [inferred], [testimony]) for key claims. End your response \
    with one of:
    - `[satisfied]`
    - `[satisfied-conditional: <condition>]`
    - `[needs more evidence: <what>]`
    """
  end

  defp build_single_prompt(question, brief_context, :naive) do
    """
    Answer the following question:

    #{question}

    Context:
    #{brief_context}
    """
  end

  defp build_single_prompt(question, brief_context, :structured) do
    """
    You are a senior technical advisor. Answer the following question with the \
    same rigour as a multi-agent roundtable discussion.

    ## Instructions

    - Tag each claim with typed provenance: [observed], [inferred], or [testimony]
    - Challenge at least one premise of the question
    - For each recommendation, provide the warrant (the "because" linking evidence to claim)
    - End with satisfaction markers indicating your confidence level
    - Include a "Unique contribution" appendix listing considerations you believe \
      are non-obvious

    ## Question

    #{question}

    ## Context

    #{brief_context}
    """
  end

  defp build_single_prompt(question, brief_context, :debate) do
    """
    Generate three distinct perspectives on the following question, then \
    synthesize them into a single recommendation with satisfaction markers.

    For each perspective:
    1. State the perspective's core position
    2. Provide supporting evidence with provenance markers ([observed], [inferred], [testimony])
    3. Identify the main weakness of this perspective

    Then write a synthesis that:
    - Identifies areas of agreement
    - Resolves key disagreements
    - Provides a final recommendation

    ## Question

    #{question}

    ## Context

    #{brief_context}
    """
  end

  # ------------------------------------------------------------------
  # Agent invocation
  # ------------------------------------------------------------------

  defp invoke_agent(agent, prompt, repo_root) do
    cli_agent = cli_agent_atom(agent)

    case RunCliAgent.run(%{agent: cli_agent, prompt: prompt, repo_root: repo_root}, %{}) do
      {:ok, %{stdout: raw}} -> {:ok, extract_text(raw)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_text(raw) do
    case JSON.decode(raw) do
      {:ok, %{"result" => text}} when is_binary(text) -> text
      {:ok, %{"content" => text}} when is_binary(text) -> text
      {:ok, %{"message" => text}} when is_binary(text) -> text
      {:ok, %{"text" => text}} when is_binary(text) -> text
      _ -> raw
    end
  end

  # ------------------------------------------------------------------
  # Agent helpers
  # ------------------------------------------------------------------

  defp cli_agent_atom(:claude_ic), do: :claude
  defp cli_agent_atom(:deepseek), do: :deepseek
  defp cli_agent_atom(agent), do: agent

  defp agent_label(:claude_ic), do: "Claude IC"
  defp agent_label(:codex), do: "Codex"
  defp agent_label(:gemini), do: "Gemini"
  defp agent_label(:deepseek), do: "DeepSeek"
  defp agent_label(other), do: other |> to_string() |> String.capitalize()

  @agent_roles %{
    codex:
      "You are Codex, an OpenAI-based agent. Bring expertise in API design, code architecture, " <>
        "and implementation detail. Provide an independent review.",
    gemini:
      "You are Gemini, a Google-based agent. Bring expertise in research, context synthesis, " <>
        "and system-level reasoning. Provide an independent review.",
    deepseek:
      "You are DeepSeek, an AI agent by DeepSeek AI. Bring independent analytical perspective " <>
        "grounded in rigorous reasoning. Provide an independent review.",
    claude_ic:
      "You are the Incident Commander (IC). Synthesise the positions above, identify gaps, " <>
        "and decide whether consensus has been reached. You speak last."
  }

  defp agent_role(agent), do: Map.get(@agent_roles, agent, "You are an independent AI reviewer.")

  # ------------------------------------------------------------------
  # Paths
  # ------------------------------------------------------------------

  defp eval_dir do
    base = Application.get_env(:roundtable, :state_dir, "state")
    Path.join(base, "eval")
  end
end

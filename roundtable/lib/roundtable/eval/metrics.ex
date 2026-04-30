defmodule Roundtable.Eval.Metrics do
  @moduledoc """
  Compute and compare metrics for evaluation runs.

  Orchestrates calls to `Roundtable.Eval.Judge` to populate the metrics
  map on an `Eval.Run`.
  """

  alias Roundtable.Eval.{Judge, Run}

  @type metrics_map :: %{
          consideration_count: non_neg_integer(),
          unique_considerations: non_neg_integer(),
          self_consistent: boolean(),
          contradiction_count: non_neg_integer(),
          dissent_count: non_neg_integer(),
          diversity_ratio: float() | nil,
          tokens_used: non_neg_integer() | nil,
          cost_usd: float() | nil
        }

  @doc """
  Compute all metrics for an eval run, returning an updated run with
  `metrics` populated.

  ## Options
  - `:repo_root` — passed through to Judge calls
  """
  @spec compute(Run.t(), keyword()) :: {:ok, Run.t()} | {:error, term()}
  def compute(%Run{} = run, opts \\ []) do
    text = run.final_output || ""

    with {:ok, considerations} <- Judge.extract_considerations(text, opts),
         {:ok, consistency} <- Judge.check_consistency(text, opts),
         {:ok, dissent} <- Judge.count_dissent(text, opts) do
      diversity = compute_diversity_ratio(run)

      metrics = %{
        consideration_count: length(considerations),
        unique_considerations: count_unique(considerations),
        self_consistent: Map.get(consistency, "consistent", true),
        contradiction_count: length(Map.get(consistency, "contradictions", [])),
        dissent_count: Map.get(dissent, "dissent_count", 0),
        diversity_ratio: diversity,
        tokens_used: run.tokens_used,
        cost_usd: run.cost_usd
      }

      {:ok, %Run{run | metrics: metrics}}
    end
  end

  @doc """
  Compare metrics across a list of runs for the same question.

  Returns a map of `%{mode => metrics}` plus a `:comparison` key with
  ratios between modes.
  """
  @spec compare([Run.t()]) :: map()
  def compare(runs) when is_list(runs) do
    by_mode =
      Map.new(runs, fn run ->
        {run.mode, run.metrics || %{}}
      end)

    # Compute ratios relative to the first single-model baseline found
    baseline_mode =
      Enum.find([:single_structured, :single_naive, :single_debate], fn mode ->
        Map.has_key?(by_mode, mode)
      end)

    ratios =
      if baseline_mode && Map.has_key?(by_mode, :vaglio) do
        vaglio_m = Map.get(by_mode, :vaglio, %{})
        baseline_m = Map.get(by_mode, baseline_mode, %{})

        %{
          consideration_ratio: safe_ratio(vaglio_m[:consideration_count], baseline_m[:consideration_count]),
          cost_ratio: safe_ratio(vaglio_m[:cost_usd], baseline_m[:cost_usd])
        }
      else
        %{}
      end

    Map.put(by_mode, :comparison, ratios)
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  # For vaglio runs, compute how many considerations were raised by
  # exactly one agent vs. total. Requires per-agent turn data.
  defp compute_diversity_ratio(%Run{mode: :vaglio, turns: turns}) when is_list(turns) do
    agent_claims =
      turns
      |> Enum.filter(&Map.has_key?(&1, :output))
      |> Enum.flat_map(fn turn ->
        agent = Map.get(turn, :agent, Map.get(turn, "agent"))
        output = Map.get(turn, :output, Map.get(turn, "output", ""))
        claims = simple_extract_claims(output)
        Enum.map(claims, fn claim -> {claim, agent} end)
      end)

    if agent_claims == [] do
      nil
    else
      # Group by normalized claim, see how many agents raised each
      grouped =
        Enum.group_by(agent_claims, fn {claim, _} -> claim end, fn {_, agent} -> agent end)

      unique_to_one = Enum.count(grouped, fn {_claim, agents} -> length(Enum.uniq(agents)) == 1 end)
      total = map_size(grouped)
      if total > 0, do: unique_to_one / total, else: nil
    end
  end

  defp compute_diversity_ratio(_), do: nil

  # Quick local claim extraction (no LLM) — splits on sentence boundaries
  # and normalizes for grouping. This is a rough heuristic; the LLM judge
  # provides the authoritative count.
  defp simple_extract_claims(text) do
    text
    |> String.split(~r/[.!?]\s+/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(String.length(&1) < 20))
    |> Enum.map(&String.downcase/1)
  end

  defp count_unique(considerations) when is_list(considerations) do
    considerations
    |> Enum.map(fn c -> Map.get(c, "claim", Map.get(c, :claim, "")) end)
    |> Enum.map(&String.downcase(&1))
    |> Enum.map(&String.trim/1)
    |> Enum.uniq()
    |> length()
  end

  defp safe_ratio(_, nil), do: nil
  defp safe_ratio(_, 0), do: nil
  defp safe_ratio(nil, _), do: nil
  defp safe_ratio(a, b), do: Float.round(a / b, 2)
end

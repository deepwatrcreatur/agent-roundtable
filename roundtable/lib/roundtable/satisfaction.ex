defmodule Roundtable.Satisfaction do
  @moduledoc """
  Satisfaction protocol interpreter.
  Determines what label to apply to a GitHub Issue based on agent responses.
  """

  @doc """
  Parses a single agent response for satisfaction markers.

  Returns one of:
  - `{:satisfied, nil}`
  - `{:satisfied_conditional, "condition"}`
  - `{:no_objection, nil}`
  - `{:needs_more_evidence, "what is needed"}`
  - `{:unknown, response_text}`
  """
  def parse(text) do
    # Multi-marker handling: most conservative wins
    # needs_more_evidence > satisfied_conditional > no_objection > satisfied
    markers = [
      {:needs_more_evidence, ~r/\[\s*needs\s+more\s+evidence\s*:\s*(.*?)\s*\]/i},
      {:satisfied_conditional, ~r/\[\s*satisfied\s*-\s*conditional\s*:\s*(.*?)\s*\]/i},
      {:no_objection, ~r/\[\s*no\s+objection\s*\]/i},
      {:satisfied, ~r/\[\s*satisfied\s*\]/i}
    ]

    found = Enum.flat_map(markers, fn {type, regex} ->
      case Regex.run(regex, text) do
        [_, captured] -> [{type, String.trim(captured)}]
        [_] -> [{type, nil}]
        nil -> []
      end
    end)

    case found do
      [] -> {:unknown, text}
      [{type, detail} | _] -> {type, detail}
    end
  end

  @doc """
  Legacy parser that returns only the label string or nil.
  Used by Orchestrator and RoundRun.
  """
  def parse_marker(text) do
    case parse(text) do
      {:satisfied, _} -> "satisfied"
      {:satisfied_conditional, _} -> "satisfied-conditional"
      {:no_objection, _} -> "no-objection"
      {:needs_more_evidence, _} -> "needs-more-evidence"
      _ -> nil
    end
  end

  @doc """
  Determine overall question state from all agent responses in a round.

  Returns one of:
  - `:all_satisfied`
  - `:satisfied_conditional`
  - `:needs_more_evidence`
  - `:needs_ic_triage`
  - `:max_rounds_reached`
  """
  def question_state(responses, opts \\ []) do
    if Keyword.get(opts, :max_rounds_reached, false) do
      :max_rounds_reached
    else
      parsed = Enum.map(responses, &parse/1)
      
      cond do
        Enum.any?(parsed, fn {type, _} -> type == :unknown end) ->
          :needs_ic_triage

        Enum.any?(parsed, fn {type, _} -> type == :needs_more_evidence end) ->
          :needs_more_evidence

        Enum.any?(parsed, fn {type, _} -> type == :satisfied_conditional end) ->
          :satisfied_conditional

        Enum.any?(parsed, fn {type, _} -> type == :satisfied end) ->
          :all_satisfied

        true ->
          # Case where everyone said [no objection] or there are no responses
          # Consensus is reached only if at least one is satisfied or satisfied-conditional
          :needs_more_evidence
      end
    end
  end

  @doc """
  Determines if a question should be closed based on labels.

  Consensus is reached when:
  - At least one agent is `satisfied` or `satisfied-conditional`
  - No agent has `needs-more-evidence`
  - `no-objection` is non-blocking (does not prevent closure) but
    does not count as positive satisfaction on its own
  """
  def consensus?(labels) do
    has_satisfied? = "satisfied" in labels or "satisfied-conditional" in labels
    has_blocking? = "needs-more-evidence" in labels

    has_satisfied? and not has_blocking?
  end

  @doc """
  Returns the labels to add and remove based on the question state.
  """
  def label_changes(state) do
    case state do
      :all_satisfied ->
        %{add: ["satisfied"], remove: ["needs-more-evidence", "satisfied-conditional", "no-objection", "needs-ic-triage"]}

      :satisfied_conditional ->
        %{add: ["satisfied-conditional"], remove: ["needs-more-evidence", "no-objection", "needs-ic-triage"]}

      :needs_more_evidence ->
        %{add: ["needs-more-evidence"], remove: ["satisfied", "satisfied-conditional", "no-objection", "needs-ic-triage"]}

      :needs_ic_triage ->
        %{add: ["needs-ic-triage"], remove: []}

      :max_rounds_reached ->
        %{add: ["needs-human-review"], remove: []}
    end
  end
end

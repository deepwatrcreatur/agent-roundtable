defmodule Roundtable.RobustnessMetrics do
  @moduledoc """
  Computes discussion robustness signals for the dashboard.

  The robustness meter highlights whether consensus emerged from real heat or
  mostly from low-friction agreement.
  """

  alias Roundtable.Satisfaction

  @type meter_state :: :deep_green | :pale_green | :yellow | :active | :warming

  @type meter :: %{
          robustness_score: float(),
          round_count: non_neg_integer(),
          objection_count: non_neg_integer(),
          satisfied_count: non_neg_integer(),
          no_objection_count: non_neg_integer(),
          state: meter_state(),
          label: String.t()
        }

  @spec compute(map(), String.t()) :: %{optional(pos_integer()) => meter()}
  def compute(questions, decision_text) when is_map(questions) do
    decision_rounds = parse_decision_rounds(decision_text)

    Map.new(questions, fn {number, question} ->
      {number, build_meter(question, Map.get(decision_rounds, question_id(question)))}
    end)
  end

  @spec low_robustness_history(map(), map(), pos_integer()) :: [{pos_integer(), map(), meter()}]
  def low_robustness_history(questions, meters, limit \\ 5) do
    questions
    |> Enum.filter(fn {number, question} ->
      question[:state] == :closed and Map.has_key?(meters, number)
    end)
    |> Enum.sort_by(fn {number, _question} ->
      meters
      |> Map.fetch!(number)
      |> Map.get(:robustness_score)
    end)
    |> Enum.take(limit)
    |> Enum.map(fn {number, question} -> {number, question, Map.fetch!(meters, number)} end)
  end

  defp build_meter(question, decision_round_count) do
    agent_turns = agent_turns(Map.get(question, :comments, []))
    markers = Enum.map(agent_turns, &turn_marker/1)

    round_count =
      case decision_round_count do
        n when is_integer(n) and n >= 0 -> n
        _ -> estimate_round_count(agent_turns)
      end

    objection_count = Enum.count(markers, &(&1 == "needs-more-evidence"))
    satisfied_count = Enum.count(markers, &(&1 in ["satisfied", "satisfied-conditional"]))
    no_objection_count = Enum.count(markers, &(&1 == "no-objection"))

    round_factor = min(round_count / 3.0, 1.0)
    objection_factor = min(objection_count / 2.0, 1.0)

    ratio_factor =
      case satisfied_count + no_objection_count do
        0 -> if objection_count > 0, do: 0.45, else: 0.2
        total -> satisfied_count / total
      end

    robustness_score =
      0.4 * round_factor +
        0.35 * objection_factor +
        0.25 * ratio_factor

    state =
      classify_state(
        question[:state],
        round_count,
        objection_count,
        satisfied_count,
        no_objection_count,
        robustness_score
      )

    %{
      robustness_score: robustness_score,
      round_count: round_count,
      objection_count: objection_count,
      satisfied_count: satisfied_count,
      no_objection_count: no_objection_count,
      state: state,
      label: state_label(state)
    }
  end

  defp parse_decision_rounds(text) when text in [nil, ""], do: %{}

  defp parse_decision_rounds(text) do
    Regex.scan(~r/^##\s+(Q\d+)\s+\(Round\s+(\d+)/m, text)
    |> Enum.reduce(%{}, fn [_, qid, round], acc ->
      Map.put(acc, qid, String.to_integer(round))
    end)
  end

  defp agent_turns(comments) do
    comments
    |> Enum.filter(fn comment ->
      body = Map.get(comment, "body", "")
      body != "" and (String.contains?(body, "## ") or Satisfaction.parse_marker(body))
    end)
  end

  defp estimate_round_count([]), do: 0

  defp estimate_round_count(turns) do
    participants =
      turns
      |> Enum.map(&extract_agent/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> length()
      |> max(1)

    turns
    |> length()
    |> Kernel./(participants)
    |> Float.ceil()
    |> trunc()
  end

  defp extract_agent(comment) do
    case Regex.run(~r/^##\s+([^\n]+)/m, Map.get(comment, "body", "")) do
      [_, agent] -> String.trim(agent)
      _ -> nil
    end
  end

  defp turn_marker(comment), do: Satisfaction.parse_marker(Map.get(comment, "body", ""))

  defp question_id(question) do
    case Regex.run(~r/\bQ\d+\b/, Map.get(question, :title, "")) do
      [qid] -> qid
      _ -> nil
    end
  end

  defp classify_state(_status, _rounds, _objections, _satisfied, no_objection, _score)
       when no_objection > 0 do
    :yellow
  end

  defp classify_state(:closed, rounds, objections, satisfied, _no_objection, _score)
       when rounds <= 1 and objections == 0 and satisfied > 0 do
    :pale_green
  end

  defp classify_state(:closed, rounds, objections, satisfied, _no_objection, _score)
       when rounds >= 2 and objections > 0 and satisfied > 0 do
    :deep_green
  end

  defp classify_state(:open, _rounds, objections, _satisfied, _no_objection, _score)
       when objections > 0 do
    :active
  end

  defp classify_state(:open, _rounds, _objections, _satisfied, _no_objection, _score), do: :warming

  defp classify_state(_status, _rounds, _objections, _satisfied, _no_objection, score)
       when score >= 0.66 do
    :deep_green
  end

  defp classify_state(_status, _rounds, _objections, _satisfied, _no_objection, score)
       when score <= 0.35 do
    :pale_green
  end

  defp classify_state(_status, _rounds, _objections, _satisfied, _no_objection, _score),
    do: :warming

  defp state_label(:deep_green), do: "Deep Green"
  defp state_label(:pale_green), do: "Pale Green"
  defp state_label(:yellow), do: "Yellow"
  defp state_label(:active), do: "Active Heat"
  defp state_label(:warming), do: "Warming Up"
end

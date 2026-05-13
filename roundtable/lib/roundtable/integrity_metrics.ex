defmodule Roundtable.IntegrityMetrics do
  @moduledoc """
  Computes epistemic integrity metrics for completed discussion questions.

  The scorecard focuses on three signals:

  - divergence delta: how far the decision language moved away from the prompt
  - vocabulary innovation: how much novel language the discussion introduced
  - premise challenge rate: how often turns pushed back on the initial framing
  """

  alias Roundtable.Satisfaction

  @stopwords MapSet.new([
               "a",
               "an",
               "and",
               "are",
               "as",
               "at",
               "be",
               "but",
               "by",
               "for",
               "from",
               "how",
               "if",
               "in",
               "into",
               "is",
               "it",
               "its",
               "of",
               "on",
               "or",
               "that",
               "the",
               "their",
               "them",
               "there",
               "these",
               "this",
               "those",
               "to",
               "was",
               "we",
               "what",
               "when",
               "where",
               "which",
               "while",
               "who",
               "why",
               "with",
               "would"
             ])

  @type scorecard :: %{
          divergence_delta: float(),
          vocabulary_innovation: float(),
          premise_challenge_rate: float(),
          integrity_score: float(),
          sycophancy_warning: boolean(),
          premise_token_count: non_neg_integer(),
          novel_token_count: non_neg_integer(),
          challenge_turn_count: non_neg_integer(),
          total_turn_count: non_neg_integer()
        }

  @spec compute(map(), String.t(), String.t()) :: %{optional(pos_integer()) => scorecard()}
  def compute(questions, brief_text, decision_text) when is_map(questions) do
    brief_sections = parse_brief_sections(brief_text)
    decision_sections = parse_decision_sections(decision_text)

    questions
    |> Enum.reduce(%{}, fn {number, question}, acc ->
      if question[:state] == :closed do
        qid = question_id(question)
        premise_text = Map.get(brief_sections, qid, "")
        outcome_text = Map.get(decision_sections, qid, "")
        transcript_text = comments_text(Map.get(question, :comments, []))

        scorecard =
          build_scorecard(
            premise_text,
            outcome_text,
            transcript_text,
            Map.get(question, :comments, [])
          )

        Map.put(acc, number, scorecard)
      else
        acc
      end
    end)
  end

  defp build_scorecard(premise_text, outcome_text, transcript_text, comments) do
    premise_terms = terms(premise_text)
    response_terms = terms(transcript_text <> "\n" <> outcome_text)
    novel_terms = MapSet.difference(response_terms, premise_terms)

    divergence_delta = divergence_delta(premise_terms, terms(outcome_text))
    vocabulary_innovation = innovation_score(response_terms, novel_terms)

    {challenge_turn_count, total_turn_count} = challenge_counts(comments)

    premise_challenge_rate =
      ratio(challenge_turn_count, total_turn_count)

    integrity_score =
      0.4 * premise_challenge_rate +
        0.35 * divergence_delta +
        0.25 * vocabulary_innovation

    %{
      divergence_delta: divergence_delta,
      vocabulary_innovation: vocabulary_innovation,
      premise_challenge_rate: premise_challenge_rate,
      integrity_score: integrity_score,
      sycophancy_warning: integrity_score < 0.33,
      premise_token_count: MapSet.size(premise_terms),
      novel_token_count: MapSet.size(novel_terms),
      challenge_turn_count: challenge_turn_count,
      total_turn_count: total_turn_count
    }
  end

  defp question_id(question) do
    case Regex.run(~r/\bQ\d+\b/, Map.get(question, :title, "")) do
      [qid] -> qid
      _ -> nil
    end
  end

  defp parse_brief_sections(text) when text in [nil, ""], do: %{}

  defp parse_brief_sections(text) do
    Regex.scan(~r/###\s+(Q\d+[^\n]*)\n+(.*?)(?=\n###|\z)/ms, text)
    |> Enum.reduce(%{}, fn [_, title, body], acc ->
      case Regex.run(~r/\bQ\d+\b/, title) do
        [qid] -> Map.put(acc, qid, String.trim(body))
        _ -> acc
      end
    end)
  end

  defp parse_decision_sections(text) when text in [nil, ""], do: %{}

  defp parse_decision_sections(text) do
    Regex.scan(~r/^##\s+(Q\d+)[^\n]*\n+(.*?)(?=^##\s+Q\d+|\z)/ms, text)
    |> Enum.reduce(%{}, fn [_, qid, body], acc ->
      Map.put(acc, qid, String.trim(body))
    end)
  end

  defp comments_text(comments) do
    comments
    |> Enum.map(&Map.get(&1, "body", ""))
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp challenge_counts(comments) do
    turns =
      comments
      |> Enum.map(&Map.get(&1, "body", ""))
      |> Enum.reject(&(&1 == ""))

    challenges = Enum.count(turns, &challenge_turn?/1)
    {challenges, length(turns)}
  end

  defp challenge_turn?(body) do
    Satisfaction.parse_marker(body) == "needs-more-evidence" or
      Enum.any?(challenge_patterns(), &Regex.match?(&1, body))
  end

  defp challenge_patterns do
    [
      ~r/\[\s*needs more evidence/i,
      ~r/\b(assumption|assumptions|challenge|challenged|challenging|contradict|contradiction|counterexample|doubt|evidence|however|insufficient|premise|question that|question the|skeptic|unclear|verify)\b/i
    ]
  end

  defp divergence_delta(premise_terms, outcome_terms) do
    if MapSet.size(outcome_terms) == 0 do
      0.0
    else
      union = MapSet.union(premise_terms, outcome_terms)
      overlap = MapSet.intersection(premise_terms, outcome_terms)
      1.0 - MapSet.size(overlap) / MapSet.size(union)
    end
  end

  defp innovation_score(response_terms, novel_terms),
    do: ratio(MapSet.size(novel_terms), MapSet.size(response_terms))

  defp ratio(_num, 0), do: 0.0
  defp ratio(num, den), do: num / den

  defp terms(text) do
    text
    |> String.downcase()
    |> String.split(~r/[^a-z0-9\-_]+/u, trim: true)
    |> Enum.reject(&(String.length(&1) < 4))
    |> Enum.reject(&MapSet.member?(@stopwords, &1))
    |> MapSet.new()
  end
end

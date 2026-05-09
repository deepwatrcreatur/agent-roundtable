defmodule Roundtable.RedTeamHighlights do
  @moduledoc """
  Builds transcript-level red-team and premise-collision highlights.
  """

  alias Roundtable.Satisfaction

  @agent_headers [
    {"## Claude IC", {:claude_ic, "Claude IC"}},
    {"## Claude", {:claude, "Claude"}},
    {"## Codex", {:codex, "Codex"}},
    {"## Gemini", {:gemini, "Gemini"}},
    {"## DeepSeek", {:deepseek, "DeepSeek"}}
  ]

  @stopwords MapSet.new([
               "about",
               "after",
               "also",
               "assume",
               "because",
               "before",
               "being",
               "brief",
               "could",
               "does",
               "from",
               "have",
               "into",
               "just",
               "more",
               "must",
               "only",
               "other",
               "over",
               "same",
               "should",
               "than",
               "that",
               "their",
               "there",
               "these",
               "they",
               "this",
               "those",
               "through",
               "under",
               "very",
               "what",
               "when",
               "where",
               "which",
               "while",
               "will",
               "with",
               "without"
             ])

  @type turn :: %{
          agent: atom() | nil,
          agent_name: String.t(),
          body: String.t(),
          marker: String.t() | nil,
          observed_evidence: [String.t()],
          red_team?: boolean(),
          disconfirmation_pass?: boolean(),
          premise_collision?: boolean()
        }

  @type question_view :: %{
          turns: [turn()],
          red_team_turns: [turn()],
          premise_collision_count: non_neg_integer(),
          hard_truth_count: non_neg_integer()
        }

  @spec build(map(), String.t()) :: %{optional(pos_integer()) => question_view()}
  def build(questions, brief_text) when is_map(questions) do
    brief_sections = parse_brief_sections(brief_text)

    Map.new(questions, fn {number, question} ->
      qid = question_id(question)
      premise_text = Map.get(brief_sections, qid, "")
      turns = parse_turns(Map.get(question, :comments, []), premise_text)
      red_team_turns = Enum.filter(turns, & &1.red_team?)

      {number,
       %{
         turns: turns,
         red_team_turns: red_team_turns,
         premise_collision_count: Enum.count(turns, & &1.premise_collision?),
         hard_truth_count: length(red_team_turns)
       }}
    end)
  end

  defp parse_turns(comments, premise_text) do
    premise_terms = terms(premise_text)

    comments
    |> Enum.map(&parse_turn(&1, premise_terms))
    |> Enum.reject(&is_nil/1)
  end

  defp parse_turn(comment, premise_terms) do
    body = Map.get(comment, "body", "")

    case detect_agent(body) do
      nil ->
        nil

      {agent, agent_name} ->
        marker = Satisfaction.parse_marker(body)
        observed_evidence = extract_observed_evidence(body)
        skeptic? = skeptic_turn?(body, marker)

        %{
          agent: agent,
          agent_name: agent_name,
          body: body,
          marker: marker,
          observed_evidence: observed_evidence,
          red_team?: skeptic?,
          disconfirmation_pass?: skeptic?,
          premise_collision?: premise_collision?(body, premise_terms, observed_evidence)
        }
    end
  end

  defp detect_agent(body) do
    Enum.find_value(@agent_headers, fn {header, identity} ->
      if String.starts_with?(body, header), do: identity
    end)
  end

  defp skeptic_turn?(_body, "needs-more-evidence"), do: true

  defp skeptic_turn?(body, _marker) do
    Enum.any?(skeptic_patterns(), &Regex.match?(&1, body))
  end

  defp premise_collision?(body, premise_terms, observed_evidence) do
    observed_text = Enum.join(observed_evidence, " ")
    observed_terms = terms(observed_text <> " " <> body)
    premise_overlap? = MapSet.size(MapSet.intersection(premise_terms, observed_terms)) > 0
    contradiction? = Enum.any?(collision_patterns(), &Regex.match?(&1, body))

    premise_overlap? and contradiction? and observed_evidence != []
  end

  defp extract_observed_evidence(body) do
    Regex.scan(~r/\[\s*observed(?:\s*:\s*([^\]]+))?\]/i, body)
    |> Enum.map(fn
      [full, ""] -> String.trim(full)
      [_, evidence] -> String.trim(evidence)
      [full] -> String.trim(full)
    end)
  end

  defp skeptic_patterns do
    [
      ~r/\b(assumption|challenge|challenged|contradict|counterexample|disconfirm|doubt|however|insufficient|skeptic|stress test|unsafe|verify|weak)\b/i
    ]
  end

  defp collision_patterns do
    [
      ~r/\b(contradict|contradiction|fails|failed|false|invalid|breaks|unsafe|does not hold|no longer true)\b/i
    ]
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

  defp question_id(question) do
    case Regex.run(~r/\bQ\d+\b/, Map.get(question, :title, "")) do
      [qid] -> qid
      _ -> nil
    end
  end

  defp terms(text) do
    text
    |> String.downcase()
    |> String.split(~r/[^a-z0-9\-_]+/u, trim: true)
    |> Enum.reject(&(String.length(&1) < 4))
    |> Enum.reject(&MapSet.member?(@stopwords, &1))
    |> MapSet.new()
  end
end

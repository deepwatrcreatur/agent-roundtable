defmodule Roundtable.ProvenanceMap do
  @moduledoc """
  Parses provenance tags from transcript turns and builds evidence views.
  """

  @agent_headers [
    {"## Claude IC", {:claude_ic, "Claude IC"}},
    {"## Claude", {:claude, "Claude"}},
    {"## Codex", {:codex, "Codex"}},
    {"## Gemini", {:gemini, "Gemini"}},
    {"## DeepSeek", {:deepseek, "DeepSeek"}}
  ]

  @kinds ~w(observed testimony inferred)

  @type claim :: %{
          kind: String.t(),
          claim_text: String.t(),
          evidence: String.t(),
          agent_name: String.t()
        }

  @type turn_view :: %{
          agent: atom() | nil,
          agent_name: String.t(),
          body: String.t(),
          claims: [claim()]
        }

  @type question_view :: %{
          turns: [turn_view()],
          evidence_map: [claim()],
          chain: %{observed: [claim()], testimony: [claim()], inferred: [claim()]},
          provenance_claim_count: non_neg_integer()
        }

  @spec build(map()) :: %{optional(pos_integer()) => question_view()}
  def build(questions) when is_map(questions) do
    Map.new(questions, fn {number, question} ->
      turns =
        question
        |> Map.get(:comments, [])
        |> Enum.map(&parse_turn/1)
        |> Enum.reject(&is_nil/1)

      all_claims = Enum.flat_map(turns, & &1.claims)

      {number,
       %{
         turns: turns,
         evidence_map: Enum.filter(all_claims, &(&1.kind == "observed")),
         chain: %{
           inferred: Enum.filter(all_claims, &(&1.kind == "inferred")),
           testimony: Enum.filter(all_claims, &(&1.kind == "testimony")),
           observed: Enum.filter(all_claims, &(&1.kind == "observed"))
         },
         provenance_claim_count: length(all_claims)
       }}
    end)
  end

  defp parse_turn(comment) do
    body = Map.get(comment, "body", "")

    case detect_agent(body) do
      nil ->
        nil

      {agent, agent_name} ->
        %{
          agent: agent,
          agent_name: agent_name,
          body: body,
          claims: parse_claims(body, agent_name)
        }
    end
  end

  defp detect_agent(body) do
    Enum.find_value(@agent_headers, fn {header, identity} ->
      if String.starts_with?(body, header), do: identity
    end)
  end

  defp parse_claims(body, agent_name) do
    body
    |> transcript_lines()
    |> Enum.flat_map(&claims_from_line(&1, agent_name))
  end

  defp transcript_lines(body) do
    body
    |> String.split("\n")
    |> Enum.drop(1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reject(&String.starts_with?(&1, "[satisfied"))
    |> Enum.reject(&String.starts_with?(&1, "[needs more evidence"))
    |> Enum.reject(&String.starts_with?(&1, "[no objection"))
  end

  defp claims_from_line(line, agent_name) do
    Regex.scan(~r/\[(observed|testimony|inferred)(?::\s*([^\]]+))?\]/i, line)
    |> Enum.flat_map(fn
      [_, kind, evidence] ->
        [claim(kind, line, evidence, agent_name)]

      [_, kind] ->
        [claim(kind, line, "", agent_name)]

      _ ->
        []
    end)
  end

  defp claim(kind, line, evidence, agent_name) do
    cleaned =
      line
      |> String.replace(~r/\[(observed|testimony|inferred)(?::\s*[^\]]+)?\]/i, "")
      |> String.trim()

    %{
      kind: String.downcase(kind),
      claim_text: if(cleaned == "", do: default_claim_text(kind, evidence), else: cleaned),
      evidence: String.trim(evidence),
      agent_name: agent_name
    }
  end

  defp default_claim_text(kind, evidence) when kind in @kinds and evidence != "", do: evidence
  defp default_claim_text(kind, _evidence), do: String.capitalize(kind)
end

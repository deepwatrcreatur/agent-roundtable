defmodule Roundtable.Provenance do
  @moduledoc """
  Helpers for extracting provenance-tagged claims from agent transcript text.
  """

  @tag_regex ~r/(?<claim>[^\n\[]+?)\s*\[(?<tag>observed|testimony|inferred)(?::\s*(?<detail>[^\]]*))?\]/i

  @type claim :: %{
          claim: String.t(),
          tag: :observed | :testimony | :inferred,
          detail: String.t() | nil,
          agent: atom() | nil
        }

  @spec parse_claims(String.t(), atom() | nil) :: [claim()]
  def parse_claims(text, agent \\ nil) when is_binary(text) do
    Regex.scan(@tag_regex, text)
    |> Enum.map(fn [match | _captures] ->
      captures = Regex.named_captures(@tag_regex, match) || %{}

      %{
        claim: captures["claim"] |> clean_claim(),
        tag: captures["tag"] |> String.downcase() |> String.to_atom(),
        detail: normalize_detail(captures["detail"]),
        agent: agent
      }
    end)
    |> Enum.reject(&(&1.claim == ""))
  end

  defp clean_claim(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.replace(~r/^[\s\-\.\:\;\,\)\]]+/, "")
    |> String.trim()
  end

  defp normalize_detail(""), do: nil
  defp normalize_detail(detail), do: String.trim(detail)
end

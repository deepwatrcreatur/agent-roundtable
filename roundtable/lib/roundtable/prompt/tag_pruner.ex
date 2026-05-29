defmodule Roundtable.Prompt.TagPruner do
  @moduledoc """
  Prunes agent context windows based on subject tag overlap.

  Given the tags on the current question and the full set of prior turns,
  returns a "Surgical History" containing only turns whose tags overlap
  with the current topic — plus any turns tagged with Global Invariants
  (tags that are never pruned regardless of topic).
  """

  alias Roundtable.Tagging
  alias Roundtable.Vcs.Dolt

  require Logger

  @global_invariant_kinds ["governance", "risk"]

  @doc """
  Builds a pruned context string from prior discussion turns, keeping only
  turns whose tags overlap with the current question's tags.

  Returns `{pruned_context, stats}` where stats contains token efficiency info.

  Options:
    - `:repo_path` — path to the Dolt repo (required)
    - `:max_tokens` — approximate token budget for pruned context (default 6000)
  """
  def prune_by_tags(issue_id, prior_turns, opts \\ []) do
    repo_path = Keyword.fetch!(opts, :repo_path)
    max_chars = Keyword.get(opts, :max_tokens, 6000) * 4

    with {:ok, question_tags} <- Tagging.list_issue_tags(repo_path, issue_id),
         {:ok, invariant_tags} <- list_invariant_tags(repo_path) do
      relevant_tags = MapSet.new(question_tags ++ invariant_tags)

      {kept, dropped} =
        prior_turns
        |> Enum.split_with(fn turn ->
          turn_tags = Map.get(turn, :tags, [])
          turn_is_invariant = Enum.any?(turn_tags, &(&1 in invariant_tags))
          turn_overlaps = Enum.any?(turn_tags, &MapSet.member?(relevant_tags, &1))
          turn_is_invariant or turn_overlaps or turn_tags == []
        end)

      pruned_text =
        kept
        |> Enum.map(&format_turn/1)
        |> Enum.join("\n\n---\n\n")
        |> String.slice(0, max_chars)

      full_size =
        prior_turns |> Enum.map(&format_turn/1) |> Enum.join("\n\n---\n\n") |> byte_size()

      pruned_size = byte_size(pruned_text)

      stats = %{
        total_turns: length(prior_turns),
        kept_turns: length(kept),
        dropped_turns: length(dropped),
        full_bytes: full_size,
        pruned_bytes: pruned_size,
        savings_pct:
          if(full_size > 0,
            do: Float.round((1 - pruned_size / full_size) * 100, 1),
            else: 0.0
          ),
        question_tags: question_tags,
        invariant_tags: invariant_tags
      }

      Logger.info(
        "[TagPruner] issue=#{issue_id} kept=#{stats.kept_turns}/#{stats.total_turns} " <>
          "savings=#{stats.savings_pct}% tags=#{inspect(question_tags)}"
      )

      {pruned_text, stats}
    else
      {:error, reason} ->
        Logger.warning("[TagPruner] falling back to full context: #{inspect(reason)}")
        full_text = prior_turns |> Enum.map(&format_turn/1) |> Enum.join("\n\n---\n\n")

        stats = %{
          total_turns: length(prior_turns),
          kept_turns: length(prior_turns),
          dropped_turns: 0,
          full_bytes: byte_size(full_text),
          pruned_bytes: byte_size(full_text),
          savings_pct: 0.0,
          question_tags: [],
          invariant_tags: []
        }

        {full_text, stats}
    end
  end

  @doc """
  Extracts tags from a question's title and body by matching `#tag` patterns
  and known tag IDs from the Dolt tags table.

  This is a lightweight alternative to requiring all questions to be pre-tagged
  in Dolt — it infers tags from content.
  """
  def infer_tags_from_content(text, opts \\ []) do
    repo_path = Keyword.get(opts, :repo_path)

    explicit =
      Regex.scan(~r/#([a-z][a-z0-9_-]+)/, text || "")
      |> Enum.map(fn [_, tag] -> tag end)

    known =
      if repo_path do
        case Dolt.query("SELECT id FROM tags", repo_path: repo_path) do
          {:ok, rows} ->
            all_tags = Enum.map(rows, & &1["id"])
            text_lower = String.downcase(text || "")
            Enum.filter(all_tags, &String.contains?(text_lower, String.downcase(&1)))

          _ ->
            []
        end
      else
        []
      end

    (explicit ++ known) |> Enum.uniq()
  end

  defp list_invariant_tags(repo_path) do
    kinds = Enum.map_join(@global_invariant_kinds, ", ", &"'#{&1}'")
    sql = "SELECT id FROM tags WHERE kind IN (#{kinds})"

    case Dolt.query(sql, repo_path: repo_path) do
      {:ok, rows} -> {:ok, Enum.map(rows, & &1["id"])}
      {:error, _} -> {:ok, []}
    end
  end

  defp format_turn(%{author: author, body: body}) do
    "**#{author}**:\n#{body}"
  end

  defp format_turn(%{body: body}), do: body
  defp format_turn(turn) when is_binary(turn), do: turn
end

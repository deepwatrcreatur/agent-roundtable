defmodule Roundtable.Prompt.EvolutionAssembler do
  @moduledoc """
  Assembles evolution-based context from JJ deltas for token efficiency.
  """

  alias Roundtable.Vcs.Jujutsu

  @doc """
  Assembles the logical evolution of a decision for the given revset.
  Returns a string of combined diffs (deltas).
  """
  def assemble_evolution(repo_path, revset, opts \\ []) do
    case Jujutsu.query(revset, repo_path: repo_path) do
      {:ok, revisions} ->
        revisions
        |> maybe_limit(opts)
        |> Enum.map(fn rev -> fetch_delta(repo_path, rev) end)
        |> Enum.join("\n\n---\n\n")

      {:error, _} ->
        "(No logical evolution found for revset: #{revset})"
    end
  end

  defp fetch_delta(repo_path, %{commit_id: id, description: desc, author: author}) do
    case Jujutsu.diff(id, repo_path: repo_path) do
      {:ok, diff} ->
        "Intent: #{desc} (by #{author})\nDelta:\n#{diff}"

      _ ->
        "Intent: #{desc} (by #{author})\n(Delta unavailable)"
    end
  end

  defp maybe_limit(list, opts) do
    case Keyword.get(opts, :limit) do
      nil -> list
      # Take most recent N evolutions
      n -> Enum.take(list, -n)
    end
  end
end

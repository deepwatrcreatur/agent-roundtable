defmodule Roundtable.Prompt.Pruner do
  @moduledoc """
  Surgically prunes the design repository context using JJ Revsets.
  """

  alias Roundtable.Vcs.Jujutsu

  @doc """
  Prunes the repository context based on the given revset.
  Returns a string containing the content of all files in the matching revisions.
  """
  def prune_context(repo_path, revset) do
    case Jujutsu.query(revset, repo_path: repo_path) do
      {:ok, revisions} ->
        revisions
        |> Enum.map(fn rev -> fetch_revision_context(repo_path, rev) end)
        |> Enum.join("\n\n---\n\n")

      {:error, _} ->
        "(No matching context found for revset: #{revset})"
    end
  end

  defp fetch_revision_context(repo_path, %{commit_id: id, description: desc}) do
    # For now, we fetch all files in that revision.
    # In a later iteration of #38, we could prune to specific files/diffs.
    case Jujutsu.read_file(".", repo_path: repo_path, revision: id) do
      {:ok, content} ->
        "Revision: #{id}\nDescription: #{desc}\n\n#{content}"

      _ ->
        "Revision: #{id}\nDescription: #{desc}\n(Content unavailable)"
    end
  end
end

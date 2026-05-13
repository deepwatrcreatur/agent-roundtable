defmodule Roundtable.Tagging do
  @moduledoc """
  High-level API for multidimensional tagging of issues.
  Uses Dolt for relational storage and jj for historical evolution.
  """

  alias Roundtable.Vcs.Dolt
  alias Roundtable.Vcs.Jujutsu

  @doc """
  Add a tag to an issue.
  """
  def add_tag(repo_path, issue_id, tag_id, opts \\ []) do
    created_by = Keyword.get(opts, :created_by, "system")

    # 1. Update Dolt (Relational Layer)
    sql =
      "INSERT IGNORE INTO issue_tags (issue_id, tag_id, created_by) VALUES ('#{issue_id}', '#{tag_id}', '#{created_by}')"

    with {:ok, _} <- Dolt.query(sql, repo_path: repo_path),
         {:ok, _} <-
           Dolt.write_files(
             %{
               message: "feat(tag): add tag #{tag_id} to issue #{issue_id}",
               branch: "main",
               changes: []
             },
             repo_path: repo_path
           ) do
      # 2. Update jj (Evolution Layer)
      # We represent tags as virtual bookmarks or description markers.
      # For now, we'll just log the protocol event.
      # In a real implementation, we might move a bookmark: tags/<tag_id>

      :ok
    end
  end

  @doc """
  Remove a tag from an issue.
  """
  def remove_tag(repo_path, issue_id, tag_id) do
    sql = "DELETE FROM issue_tags WHERE issue_id = '#{issue_id}' AND tag_id = '#{tag_id}'"

    with {:ok, _} <- Dolt.query(sql, repo_path: repo_path),
         {:ok, _} <-
           Dolt.write_files(
             %{
               message: "feat(tag): remove tag #{tag_id} from issue #{issue_id}",
               branch: "main",
               changes: []
             },
             repo_path: repo_path
           ) do
      :ok
    end
  end

  @doc """
  List tags for a specific issue.
  """
  def list_issue_tags(repo_path, issue_id) do
    sql = "SELECT tag_id FROM issue_tags WHERE issue_id = '#{issue_id}'"

    with {:ok, rows} <- Dolt.query(sql, repo_path: repo_path) do
      {:ok, Enum.map(rows, & &1["tag_id"])}
    end
  end

  @doc """
  List all issues for a given tag.
  """
  def list_tagged_issues(repo_path, tag_id) do
    sql = "SELECT issue_id FROM issue_tags WHERE tag_id = '#{tag_id}'"

    with {:ok, rows} <- Dolt.query(sql, repo_path: repo_path) do
      {:ok, Enum.map(rows, & &1["issue_id"])}
    end
  end
end

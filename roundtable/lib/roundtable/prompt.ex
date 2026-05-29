defmodule Roundtable.Prompt do
  @moduledoc """
  Assembles BRIEF + issue JSON + agent role into a prompt.

  Supports tag-based context pruning: when an issue has subject tags, prior
  discussion turns are filtered to those with overlapping tags plus any
  Global Invariant tags (governance, risk) that are never pruned.
  """

  alias Roundtable.Prompt.TagPruner

  @doc """
  Builds a prompt for the given agent and question context.

  Options:
    - `:repo_path` — Dolt repo path; enables tag-based context pruning
    - `:issue_id` — issue identifier for tag lookup
  """
  def build(brief_content, issue_data, agent_role, opts \\ []) do
    comments_section = build_comments_section(issue_data, opts)

    """
    You are participating in a multi-agent roundtable discussion.

    ### Your Role
    #{agent_role}

    ### Context: Design Brief
    #{brief_content}

    ### Current Discussion State (GitHub Issue)
    Title: #{issue_data["title"]}
    Body: #{issue_data["body"]}

    Comments:
    #{comments_section}

    ### Instructions
    1. Read the brief and the current discussion carefully.
    2. Provide your signed position on the current question.
    3. When you make factual or evidentiary claims, annotate them inline where possible with:
       [observed: <command output, file read, or direct observation>]
       [testimony: <reported source or witness>]
       [inferred: <reasoning basis>]
       Keep the supporting source text concise but specific.
    4. You MUST end your response with exactly one of these markers for the current question:
       [satisfied]
       [satisfied-conditional: <condition>]
       [needs more evidence: <what>]

    Your response:
    """
  end

  defp build_comments_section(issue_data, opts) do
    repo_path = Keyword.get(opts, :repo_path)
    issue_id = Keyword.get(opts, :issue_id)
    comments = issue_data["comments"]

    if repo_path && issue_id && is_list(comments) && comments != [] do
      turns =
        Enum.map(comments, fn c ->
          inferred_tags =
            TagPruner.infer_tags_from_content(c["body"], repo_path: repo_path)

          %{
            author: get_in(c, ["author", "login"]) || "unknown",
            body: c["body"] || "",
            tags: inferred_tags
          }
        end)

      {pruned, _stats} = TagPruner.prune_by_tags(issue_id, turns, repo_path: repo_path)
      pruned
    else
      render_comments(comments)
    end
  end

  defp render_comments(nil), do: "(No comments yet)"
  defp render_comments([]), do: "(No comments yet)"

  defp render_comments(comments) do
    comments
    |> Enum.map(fn c ->
      "--- #{c["author"]["login"]} at #{c["createdAt"]} ---\n#{c["body"]}"
    end)
    |> Enum.join("\n\n")
  end
end

defmodule Roundtable.Prompt do
  @moduledoc """
  Assembles BRIEF + issue JSON + agent role into a prompt.
  """

  @doc """
  Builds a prompt for the given agent and question context.
  """
  def build(brief_content, issue_data, agent_role) do
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
    #{render_comments(issue_data["comments"])}

    ### Instructions
    1. Read the brief and the current discussion carefully.
    2. Provide your signed position on the current question.
    3. You MUST end your response with exactly one of these markers for the current question:
       [satisfied]
       [satisfied-conditional: <condition>]
       [needs more evidence: <what>]

    Your response:
    """
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

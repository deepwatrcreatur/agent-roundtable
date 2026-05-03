defmodule Roundtable.Prompt do
  @moduledoc """
  Assembles BRIEF + issue JSON + agent role into a prompt.
  """

  @doc """
  Builds a prompt for the given agent and question context.

  ## Options
  - `:join` — boolean, if true produces a fuller orientation prompt (default: false)
  """
  def build(brief_content, issue_data, agent_role, opts \\ []) do
    is_join = Keyword.get(opts, :join, false)

    sections = [
      render_preamble(agent_role, is_join),
      render_brief(brief_content),
      render_question(issue_data),
      render_discussion(issue_data["comments"], is_join),
      render_task(agent_role, is_join)
    ]

    Enum.join(sections, "\n\n")
  end

  defp render_preamble(agent_role, true) do
    """
    ### Your Role
    #{agent_role}

    You are joining an ongoing multi-agent roundtable discussion. Your goal is to provide \
    independent research and critical analysis.
    """
  end

  defp render_preamble(agent_role, false) do
    """
    ### Your Role
    #{agent_role}
    """
  end

  defp render_brief(content) do
    """
    === BRIEF ===
    #{content}
    """
  end

  defp render_question(data) do
    """
    === QUESTION ===
    Title: #{data["title"]}
    URL: #{data["url"] || data["html_url"]}
    """
  end

  defp render_discussion(nil, _), do: "=== DISCUSSION SO FAR ===\n(No comments yet)"
  defp render_discussion([], _), do: "=== DISCUSSION SO FAR ===\n(No comments yet)"

  defp render_discussion(comments, is_join) do
    # Cap comments: N=5 for join, N=10 for turn
    limit = if is_join, do: 5, else: 10

    rendered =
      comments
      |> Enum.take(-limit)
      |> Enum.map(fn c ->
        author = get_in(c, ["author", "login"]) || "Unknown"
        time = c["createdAt"] || c["updated_at"] || "recent"
        "## #{author} at #{time}\n#{c["body"]}"
      end)
      |> Enum.join("\n\n")

    "=== DISCUSSION SO FAR ===\n#{rendered}"
  end

  defp render_task(agent_role, is_join) do
    role_instruction =
      cond do
        String.contains?(agent_role, "Incident Commander") ->
          "Synthesise the positions above, identify gaps, and decide whether consensus has been reached."

        true ->
          "Research the question and provide your independent position."
      end

    satisfaction_reminder = """
    You MUST end your response with exactly one of these markers for the current question:
    - `[satisfied]`
    - `[satisfied-conditional: <condition>]`
    - `[needs more evidence: <what>]`
    """

    orientation =
      if is_join do
        "\nThis is a headless orchestration. Do not post to GitHub directly; \
        your response will be captured and posted by the system."
      else
        ""
      end

    """
    === YOUR TASK ===
    #{role_instruction}

    #{satisfaction_reminder}#{orientation}
    """
  end
end

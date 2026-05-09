defmodule Roundtable.RoundArchive do
  @moduledoc """
  Mirrors legacy GitHub-issue discussions into `docs/design/rounds/`.
  """

  alias Roundtable.Actions.Gh

  @default_view_fields [:number, :title, :body, :labels, :state, :comments, :url]

  @spec mirror_issue(pos_integer(), map(), keyword()) :: :ok | {:error, term()}
  def mirror_issue(issue_number, gh_config, opts \\ []) do
    with {:ok, archive_root} <- archive_root(gh_config, opts),
         {:ok, issue} <- Gh.view_issue(issue_number, [fields: @default_view_fields], gh_config),
         :ok <- File.mkdir_p(Path.join([archive_root, "docs", "design", "rounds"])),
         :ok <- File.write(output_path(archive_root, issue), render_issue(issue)) do
      :ok
    end
  end

  defp archive_root(gh_config, opts) do
    candidates = [
      Keyword.get(opts, :archive_repo_root),
      Map.get(gh_config, :archive_repo_root),
      Map.get(gh_config, :repo_root)
    ]

    case Enum.find_value(candidates, &normalize_archive_root/1) do
      nil -> {:error, :archive_repo_root_not_configured}
      root -> {:ok, root}
    end
  end

  defp normalize_archive_root(nil), do: nil

  defp normalize_archive_root(path) do
    expanded = Path.expand(path)

    cond do
      File.dir?(Path.join([expanded, "docs", "design", "rounds"])) ->
        expanded

      Path.basename(expanded) == "roundtable" and
          File.dir?(Path.join([Path.dirname(expanded), "docs", "design", "rounds"])) ->
        Path.dirname(expanded)

      true ->
        nil
    end
  end

  defp output_path(archive_root, issue) do
    Path.join([archive_root, "docs", "design", "rounds", archive_filename(issue)])
  end

  defp archive_filename(issue) do
    case issue_round_number(issue) do
      {:ok, round_number, q_id} -> "round-#{pad_round(round_number)}-#{String.downcase(q_id)}.md"
      :error -> "round-issue-#{issue["number"]}.md"
    end
  end

  defp issue_round_number(issue) do
    case Regex.run(~r/\b(Q(\d+))\b/, issue["title"] || "") do
      [_, q_id, number] -> {:ok, String.to_integer(number), q_id}
      _ -> :error
    end
  end

  defp pad_round(number) when number < 10, do: "0#{number}"
  defp pad_round(number), do: Integer.to_string(number)

  defp render_issue(issue) do
    labels =
      issue
      |> Map.get("labels", [])
      |> Enum.map(&label_name/1)
      |> Enum.join(", ")

    comments = Map.get(issue, "comments", [])
    heading = archive_heading(issue)

    [
      heading,
      "",
      "**Issue:** ##{issue["number"] || "?"}  ",
      "**Status:** #{issue["state"] || "OPEN"}  ",
      "**Labels:** #{labels}  ",
      "**URL:** #{issue["url"] || ""}",
      "",
      "### Round question",
      "",
      issue["body"] || "",
      "",
      "### Transcript",
      "",
      render_comments(comments)
    ]
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp archive_heading(issue) do
    title = issue["title"] || "Untitled"

    case issue_round_number(issue) do
      {:ok, round_number, _q_id} ->
        stripped = String.replace(title, ~r/^\s*Q\d+\s*[—-]\s*/u, "")
        "## Round #{round_number} — #{stripped}"

      :error ->
        "## #{title}"
    end
  end

  defp render_comments([]), do: "_No comments yet._"

  defp render_comments(comments) do
    Enum.map_join(comments, "\n\n", fn comment ->
      """
      #### #{comment_author(comment)} — #{Map.get(comment, "createdAt", "")}

      #{Map.get(comment, "body", "")}
      """
      |> String.trim_trailing()
    end)
  end

  defp comment_author(%{"author" => %{"login" => login}}), do: login
  defp comment_author(%{"author" => login}) when is_binary(login), do: login
  defp comment_author(_comment), do: "unknown"

  defp label_name(%{"name" => name}), do: name
  defp label_name(name) when is_binary(name), do: name
  defp label_name(_other), do: "unknown"
end

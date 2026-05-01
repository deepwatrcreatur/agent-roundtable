defmodule Roundtable.CLI do
  @moduledoc """
  Public API and CLI entry point for the roundtable orchestrator.

  This module exposes three functions used by both the Mix task entry point
  and the Phoenix LiveView web dashboard (item 10):

    * `start_discussion/2` — parse BRIEF.md, load or create GitHub Issues for
      each question, then run the orchestrator loop.
    * `get_discussion_state/1` — return current satisfaction state for all open
      issues in the given repo, keyed by issue number.
    * `inject_question/3` — create a new GitHub Issue from a question string
      and return its issue number.

  ## Mix task entry point

      mix run -e 'Roundtable.CLI.main(["docs/design/BRIEF.md"])'
      # or via flake app wrapper:
      roundtable docs/design/BRIEF.md
  """

  alias Roundtable.Actions.Gh
  alias Roundtable.{DiscussionRepo, Orchestrator}

  @issue_index_start "<!-- ROUNDTABLE_ISSUE_INDEX_START -->"
  @issue_index_end "<!-- ROUNDTABLE_ISSUE_INDEX_END -->"

  # ----------------------------------------------------------------
  # Mix task / shell entry point
  # ----------------------------------------------------------------

  @doc false
  def main(args) do
    case parse_args(args) do
      {:ok, {brief_path, opts}} ->
        case start_discussion(brief_path, opts) do
          {:ok, results} ->
            IO.puts("\nDiscussion complete.")
            Enum.each(results, fn r ->
              IO.puts("  #{r.id} (issue ##{r.issue_number}): #{r.state}")
            end)

          {:error, reason} ->
            IO.puts("Error: #{inspect(reason)}")
            System.halt(1)
        end

      {:error, reason} ->
        IO.puts("Error: #{reason}")
        IO.puts("Usage: roundtable <brief.md> [--repo owner/repo] [--max-rounds N]")
        System.halt(1)
    end
  end

  defp parse_args([]), do: {:error, "brief path required"}

  defp parse_args([brief_path | rest]) do
    opts = parse_flags(rest, [])
    {:ok, {brief_path, opts}}
  end

  defp parse_flags([], acc), do: acc
  defp parse_flags(["--repo", repo | rest], acc), do: parse_flags(rest, [{:repo, repo} | acc])
  defp parse_flags(["--max-rounds", n | rest], acc) do
    case Integer.parse(n) do
      {int, ""} -> parse_flags(rest, [{:max_rounds, int} | acc])
      _ -> parse_flags(rest, acc)
    end
  end
  defp parse_flags([_ | rest], acc), do: parse_flags(rest, acc)

  # ----------------------------------------------------------------
  # Public module API (used by web dashboard)
  # ----------------------------------------------------------------

  @doc """
  Starts a discussion.

  `source` is either:
  - A **GitHub repo slug** (`"owner/repo"`) — uses the file-based discussion
    repo model (Protocol Update 10). Reads `BRIEF.md` from the repo via the
    GitHub API. Does not require local `gh` Issues unless `issues_enabled` is
    true in `roundtable.toml`.
  - A **local file path** to `BRIEF.md` — legacy mode; uses GitHub Issues as
    the state medium.

  ## Options

    * `:repo` — GitHub repo slug; overrides the `source` parameter for the
      legacy path
    * `:token` — GitHub PAT; used when `source` is a repo slug
    * `:local_path` — local clone path for the discussion repo (enables
      `.roundtable/state/` persistence)
    * `:max_rounds` — integer (default from `roundtable.toml` or 5)
    * `:agents` — list of agent atoms (default from `roundtable.toml`)
    * `:on_event` — `(event -> any)` progress callback
  """
  @spec start_discussion(String.t(), keyword()) :: {:ok, list()} | {:error, term()}
  def start_discussion(source, opts \\ []) do
    orchestrator_module = Keyword.get(opts, :orchestrator_module, Orchestrator)

    if repo_slug?(source) do
      repo =
        DiscussionRepo.new(source,
          token: Keyword.get(opts, :token),
          local_path: Keyword.get(opts, :local_path),
          issues_enabled: Keyword.get(opts, :issues_enabled, false)
        )

      orchestrator_module.run_with_repo(repo, opts)
    else
      # Legacy: brief_path → GitHub Issues
      with {:ok, questions} <- load_or_create_issues(source, opts) do
        {:ok, orchestrator_module.run(source, questions, opts)}
      end
    end
  end

  # Returns true if `s` looks like "owner/repo" rather than a file path.
  defp repo_slug?(s) do
    Regex.match?(~r/\A[A-Za-z0-9_.\-]+\/[A-Za-z0-9_.\-]+\z/, s) and
      not String.starts_with?(s, "/") and
      not String.starts_with?(s, ".")
  end

  @doc """
  Returns the current discussion state for a repo.

  Queries all open GitHub Issues labelled with roundtable markers and
  returns a map of `issue_number => state_map` where `state_map` has:

    * `:title` — issue title
    * `:state` — `:open` | `:closed`
    * `:labels` — list of label name strings
    * `:comment_count` — integer
    * `:satisfaction` — `:satisfied | :satisfied_conditional | :needs_more_evidence | :unknown`
    * `:url` — issue URL
  """
  @spec get_discussion_state(String.t()) :: {:ok, map()} | {:error, term()}
  def get_discussion_state(repo) do
    gh_config = %{repo: repo}

    case Gh.list_issues([state: "all", label: "roundtable"], gh_config) do
      {:ok, issues} ->
        state =
          Map.new(issues, fn issue ->
            labels = Enum.map(issue["labels"] || [], & &1["name"])
            {
              issue["number"],
              %{
                title: issue["title"],
                state: if(issue["state"] == "OPEN", do: :open, else: :closed),
                labels: labels,
                comment_count: length(issue["comments"] || []),
                satisfaction: infer_satisfaction(labels),
                url: issue["url"]
              }
            }
          end)

        {:ok, state}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Creates a new GitHub Issue for an injected question and returns its number.

  The issue is labelled `roundtable` so it is discoverable by
  `get_discussion_state/1`.
  """
  @spec inject_question(String.t(), String.t(), keyword()) ::
          {:ok, pos_integer()} | {:error, term()}
  def inject_question(repo, question_text, opts \\ [])
  def inject_question(nil, _question_text, _opts), do: {:error, :no_repo_configured}

  def inject_question(repo, question_text, opts) do
    gh_config = %{repo: repo}
    title = question_text |> String.split("\n") |> List.first() |> String.slice(0, 120)
    body = "#{question_text}\n\n*Injected via roundtable web interface.*"

    case Gh.create_issue(title, body, ["roundtable", "needs-more-evidence"], gh_config) do
      {:ok, issue_number} ->
        on_event = Keyword.get(opts, :on_event)
        if on_event, do: on_event.({:question_injected, issue_number, title})
        {:ok, issue_number}

      {:error, _} = err ->
        err
    end
  end

  # ----------------------------------------------------------------
  # Private helpers
  # ----------------------------------------------------------------

  # Reads BRIEF.md for existing issue mappings in ACTIVE_DISCUSSION.md
  # or creates new issues for questions that have no issue yet.
  defp load_or_create_issues(brief_path, opts) do
    repo = Keyword.get(opts, :repo)
    gh_module = Keyword.get(opts, :gh_module, Gh)
    gh_config = %{repo: repo}

    # Look for ACTIVE_DISCUSSION.md next to BRIEF.md
    discussion_path = Path.join(Path.dirname(brief_path), "ACTIVE_DISCUSSION.md")

    existing = load_issue_index(discussion_path)

    if map_size(existing) > 0 do
      questions =
        Enum.map(existing, fn {id, issue_number} ->
          %{id: id, issue_number: issue_number, state: :open}
        end)

      update_issue_index(discussion_path, repo, questions)
      {:ok, questions}
    else
      # No index found — create issues from BRIEF.md questions
      with {:ok, questions} <- create_issues_from_brief(brief_path, gh_module, gh_config) do
        update_issue_index(discussion_path, repo, questions)
        {:ok, questions}
      end
    end
  end

  # Parses ACTIVE_DISCUSSION.md for lines like:
  #   | Q1 | #12 | ... |
  # Returns %{"Q1" => 12, ...}
  defp load_issue_index(path) do
    case File.read(path) do
      {:ok, content} ->
        Regex.scan(~r/\|\s*(Q\d+)\s*\|\s*#(\d+)/, content)
        |> Enum.into(%{}, fn [_, id, num] -> {id, String.to_integer(num)} end)

      {:error, _} ->
        %{}
    end
  end

  # Creates GitHub Issues for each ### Q\d+ section heading in BRIEF.md.
  defp create_issues_from_brief(brief_path, gh_module, gh_config) do
    case File.read(brief_path) do
      {:ok, content} ->
        existing_issues =
          case gh_module.list_issues([state: "all", label: "roundtable"], gh_config) do
            {:ok, issues} -> issues
            {:error, _} -> []
          end

        questions =
          Regex.scan(~r/###\s+(Q\d+[^\n]*)\n+(.*?)(?=\n###|\z)/ms, content)
          |> Enum.map(fn [_, title, body] ->
            trimmed_title = String.trim(title)
            trimmed_body = String.trim(body)
            id = question_id(trimmed_title)

            case find_existing_issue(id, trimmed_title, existing_issues) do
              {:ok, issue_number} ->
                {:ok, %{id: id, issue_number: issue_number, state: :open}}

              :not_found ->
                case gh_module.create_issue(
                       trimmed_title,
                       trimmed_body,
                       ["roundtable", "needs-more-evidence"],
                       gh_config
                     ) do
                  {:ok, issue_number} ->
                    IO.puts("Created issue ##{issue_number} for #{trimmed_title}")
                    {:ok, %{id: id, issue_number: issue_number, state: :open}}

                  {:error, reason} ->
                    {:error, reason}
                end
            end
          end)

        errors = Enum.filter(questions, &match?({:error, _}, &1))

        if errors == [] do
          {:ok, Enum.map(questions, fn {:ok, q} -> q end)}
        else
          {:error, {:issue_creation_failed, errors}}
        end

      {:error, reason} ->
        {:error, {:brief_read_failed, reason}}
    end
  end

  defp infer_satisfaction(labels) do
    cond do
      "needs-more-evidence" in labels -> :needs_more_evidence
      "satisfied-conditional" in labels -> :satisfied_conditional
      "satisfied" in labels -> :satisfied
      "no-objection" in labels -> :no_objection
      true -> :unknown
    end
  end

  defp question_id(title) do
    case Regex.run(~r/Q\d+/, title) do
      [match | _] -> match
      _ -> String.trim(title)
    end
  end

  defp find_existing_issue(id, title, issues) do
    Enum.find_value(issues, :not_found, fn issue ->
      issue_title = issue["title"] || ""
      issue_number = issue["number"]

      cond do
        String.starts_with?(issue_title, id) -> {:ok, issue_number}
        issue_title == title -> {:ok, issue_number}
        true -> false
      end
    end)
  end

  defp update_issue_index(path, repo, questions) do
    block = issue_index_block(repo, questions)

    content =
      case File.read(path) do
        {:ok, existing} -> upsert_issue_index(existing, block)
        {:error, _} -> "# Active Discussion\n\n" <> block <> "\n"
      end

    File.write!(path, content)
  end

  defp upsert_issue_index(content, block) do
    if String.contains?(content, @issue_index_start) and String.contains?(content, @issue_index_end) do
      Regex.replace(
        ~r/#{Regex.escape(@issue_index_start)}.*?#{Regex.escape(@issue_index_end)}/ms,
        content,
        block
      )
    else
      content <> "\n\n" <> block
    end
  end

  defp issue_index_block(repo, questions) do
    rows =
      questions
      |> Enum.sort_by(& &1.id)
      |> Enum.map(fn %{id: id, issue_number: issue_number} ->
        url = issue_url(repo, issue_number)
        "| #{id} | ##{issue_number} | #{url} |"
      end)
      |> Enum.join("\n")

    [
      @issue_index_start,
      "## Issue Index",
      "",
      "| Question | Issue | URL |",
      "|---|---|---|",
      rows,
      @issue_index_end
    ]
    |> Enum.join("\n")
  end

  defp issue_url(nil, issue_number), do: "##{issue_number}"
  defp issue_url("", issue_number), do: "##{issue_number}"
  defp issue_url(repo, issue_number), do: "https://github.com/#{repo}/issues/#{issue_number}"
end

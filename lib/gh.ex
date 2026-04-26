defmodule Roundtable.Actions.Gh do
  @moduledoc """
  Standalone GitHub CLI wrappers for all Issue interactions.
  """

  @view_fields ["title", "body", "labels", "state", "comments", "url"]
  @list_fields ["number", "title", "state"]

  @type issue_number :: pos_integer()
  @type repo :: String.t()
  @type label :: String.t()

  # Command runner injection for testing
  defp runner do
    Application.get_env(:roundtable, :gh_runner, System)
  end

  @doc "gh issue view <n> --json title,body,comments,labels,state"
  def view_issue(repo, number) do
    args = ["issue", "view", to_string(number), "-R", repo, "--json", Enum.join(@view_fields, ",")]
    case run_gh(args) do
      {:ok, stdout} -> decode_json(stdout)
      error -> error
    end
  end

  @doc "gh issue list --label <l> --json number,title,state"
  def list_issues(repo, label) do
    args = ["issue", "list", "-R", repo, "--label", label, "--json", Enum.join(@list_fields, ",")]
    case run_gh(args) do
      {:ok, stdout} -> decode_json(stdout)
      error -> error
    end
  end

  @doc "gh issue comment <n> --body-file -"
  def post_comment(repo, number, body) do
    args = ["issue", "comment", to_string(number), "-R", repo, "--body-file", "-"]
    case run_gh(args, body) do
      {:ok, _stdout} -> :ok
      error -> error
    end
  end

  @doc "gh issue edit --add-label / --remove-label"
  def set_labels(repo, number, opts) do
    add = Keyword.get(opts, :add, [])
    remove = Keyword.get(opts, :remove, [])

    args = ["issue", "edit", to_string(number), "-R", repo]
    args = if add != [], do: args ++ ["--add-label", Enum.join(add, ",")], else: args
    args = if remove != [], do: args ++ ["--remove-label", Enum.join(remove, ",")], else: args

    case run_gh(args) do
      {:ok, _stdout} -> :ok
      error -> error
    end
  end

  @doc "gh issue close"
  def close_issue(repo, number, comment \\ nil) do
    args = ["issue", "close", to_string(number), "-R", repo]
    args = if comment, do: args ++ ["-c", comment], else: args

    case run_gh(args) do
      {:ok, _stdout} -> :ok
      error -> error
    end
  end

  @doc "gh issue create"
  def create_issue(repo, title, body, labels \\ []) do
    args = ["issue", "create", "-R", repo, "-t", title, "-b", body]
    args = if labels != [], do: args ++ ["-l", Enum.join(labels, ",")], else: args

    case run_gh(args) do
      {:ok, _stdout} -> :ok
      error -> error
    end
  end

  @doc "Validates that gh auth status succeeds"
  def auth_status do
    case run_gh(["auth", "status"]) do
      {:ok, _stdout} -> :ok
      error -> error
    end
  end

  defp run_gh(args, input \\ nil) do
    exec_opts = [stderr_to_stdout: true]
    exec_opts = if input, do: [{:input, input} | exec_opts], else: exec_opts

    case runner().cmd("gh", args, exec_opts) do
      {stdout, 0} -> {:ok, stdout}
      {stdout, status} -> {:error, {:command_failed, status, stdout}}
    end
  end

  defp decode_json(stdout) do
    case JSON.decode(stdout) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, reason} -> {:error, {:invalid_json, reason}}
    end
  end
end

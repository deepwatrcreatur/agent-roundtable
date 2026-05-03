defmodule Roundtable.Actions.Gh do
  @moduledoc """
  Thin wrappers around `gh issue ...` commands.

  The module keeps command construction, stdin wiring, and JSON decoding in one
  place so later Jido actions can stay focused on orchestration logic.
  """

  alias Roundtable.SystemCmdRunner

  @default_view_fields ["title", "body", "labels", "state", "comments", "url"]

  @type issue_number :: pos_integer()
  @type label :: String.t()

  @type config :: %{
          optional(:repo) => String.t(),
          optional(:runner) => module(),
          optional(:gh_bin) => String.t()
        }

  @type error_reason ::
          {:command_failed, non_neg_integer(), String.t()}
          | {:invalid_json, term()}
          | {:auth_failed, non_neg_integer(), String.t()}
          | {:runner_error, term()}
          | {:unexpected_output, String.t()}

  @spec validate_auth(config()) :: :ok | {:error, error_reason()}
  def validate_auth(config \\ %{}) do
    case run(["auth", "status"], config) do
      {:ok, _stdout} -> :ok
      {:error, {:command_failed, status, output}} -> {:error, {:auth_failed, status, output}}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec view_issue(issue_number(), keyword(), config()) :: {:ok, map()} | {:error, error_reason()}
  def view_issue(issue_number, opts \\ [], config \\ %{}) do
    fields = Keyword.get(opts, :fields, @default_view_fields)
    include_comments? = Keyword.get(opts, :comments, true)

    args =
      ["issue", "view", Integer.to_string(issue_number)]
      |> maybe_add_repo(config[:repo])
      |> maybe_add_comments(include_comments?)
      |> add_json_fields(fields)

    with {:ok, stdout} <- run(args, config),
         {:ok, decoded} <- decode_json(stdout) do
      {:ok, decoded}
    end
  end

  @spec comment_issue(issue_number(), String.t(), config()) :: :ok | {:error, error_reason()}
  def comment_issue(issue_number, body, config \\ %{}) when is_binary(body) do
    args =
      ["issue", "comment", Integer.to_string(issue_number), "--body-file", "-"]
      |> maybe_add_repo(config[:repo])

    case run(args, Map.put(config, :input, body)) do
      {:ok, _stdout} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @spec edit_issue_labels(issue_number(), [label()], [label()], config()) ::
          :ok | {:error, error_reason()}
  def edit_issue_labels(issue_number, add_labels, remove_labels, config \\ %{}) do
    args =
      ["issue", "edit", Integer.to_string(issue_number)]
      |> maybe_add_repo(config[:repo])
      |> maybe_add_label_flag("--add-label", add_labels)
      |> maybe_add_label_flag("--remove-label", remove_labels)

    case run(args, config) do
      {:ok, _stdout} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @spec list_issues(keyword(), config()) :: {:ok, [map()]} | {:error, error_reason()}
  def list_issues(opts \\ [], config \\ %{}) do
    state = Keyword.get(opts, :state, "open")
    label = Keyword.get(opts, :label)

    args =
      ["issue", "list", "--state", state, "--json",
       "number,title,state,labels,url,comments"]
      |> maybe_add_repo(config[:repo])
      |> maybe_add_option("--label", label)

    with {:ok, stdout} <- run(args, config),
         {:ok, decoded} <- decode_json(stdout) do
      {:ok, decoded}
    end
  end

  @spec create_issue(String.t(), String.t(), [label()], config()) ::
          {:ok, pos_integer()} | {:error, error_reason()}
  def create_issue(title, body, labels, config \\ %{}) do
    label_flag = if labels != [], do: ["--label", Enum.join(labels, ",")], else: []

    args =
      ["issue", "create", "--title", title, "--body", body] ++
        label_flag ++
        maybe_repo_args(config[:repo])

    with {:ok, stdout} <- run(args, config) do
      # gh issue create outputs the issue URL; extract the number from it
      case Regex.run(~r|/issues/(\d+)|, String.trim(stdout)) do
        [_, n] -> {:ok, String.to_integer(n)}
        _ -> {:error, {:unexpected_output, stdout}}
      end
    end
  end

  @spec close_issue(issue_number(), keyword(), config()) :: :ok | {:error, error_reason()}
  def close_issue(issue_number, opts \\ [], config \\ %{}) do
    args =
      ["issue", "close", Integer.to_string(issue_number)]
      |> maybe_add_repo(config[:repo])
      |> maybe_add_option("-r", Keyword.get(opts, :reason))
      |> maybe_add_option("-c", Keyword.get(opts, :comment))

    case run(args, config) do
      {:ok, _stdout} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp run(args, config) do
    runner = Map.get(config, :runner, SystemCmdRunner)
    gh_bin = Map.get(config, :gh_bin, "gh")

    exec_opts =
      []
      |> maybe_put_stdin(config[:input])
      |> Keyword.put(:stderr_to_stdout, true)

    case runner.cmd(gh_bin, args, exec_opts) do
      {stdout, 0} -> {:ok, stdout}
      {:error, reason} -> {:error, {:runner_error, reason}}
      {stdout, status} -> {:error, {:command_failed, status, stdout}}
    end
  end

  defp decode_json(stdout) do
    case Jason.decode(stdout) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, reason} -> {:error, {:invalid_json, reason}}
    end
  end

  defp maybe_repo_args(nil), do: []
  defp maybe_repo_args(repo), do: ["-R", repo]

  defp maybe_add_repo(args, repo), do: args ++ maybe_repo_args(repo)

  defp maybe_add_comments(args, true), do: args ++ ["--comments"]
  defp maybe_add_comments(args, false), do: args

  defp add_json_fields(args, fields), do: args ++ ["--json", Enum.join(fields, ",")]

  defp maybe_add_label_flag(args, _flag, []), do: args
  defp maybe_add_label_flag(args, flag, labels), do: args ++ [flag, Enum.join(labels, ",")]

  defp maybe_add_option(args, _flag, nil), do: args
  defp maybe_add_option(args, _flag, ""), do: args
  defp maybe_add_option(args, flag, value), do: args ++ [flag, value]

  defp maybe_put_stdin(opts, nil), do: opts
  defp maybe_put_stdin(opts, input), do: Keyword.put(opts, :input, input)
end

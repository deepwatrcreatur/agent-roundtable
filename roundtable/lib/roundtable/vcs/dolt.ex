defmodule Roundtable.Vcs.Dolt do
  @moduledoc """
  Local `dolt` (Git for Data) implementation of `Roundtable.Vcs`.

  Required options:

  - `:repo_path` — path to a local dolt repository

  Optional options:

  - `:runner` — command runner module (defaults to `Roundtable.SystemCmdRunner`)
  - `:dolt_bin` — dolt executable name (defaults to `"dolt"`)
  """

  @behaviour Roundtable.Vcs

  alias Roundtable.SystemCmdRunner

  @impl true
  def current_head(branch, opts) when is_binary(branch) do
    with {:ok, repo_path} <- fetch_repo_path(opts),
         {:ok, head} <- dolt(["rev-parse", branch], repo_path, opts) do
      {:ok, String.trim(head)}
    end
  end

  @impl true
  def read_file(path, opts) when is_binary(path) do
    # Dolt primarily versions tables, but it can version files via 'dolt table export'
    # or if we are using it to version raw files (less common).
    # For now, we'll assume read_file for Dolt means reading a table as JSON/CSV.
    with {:ok, repo_path} <- fetch_repo_path(opts) do
      revision = Keyword.get(opts, :revision, "HEAD")
      # Example: dolt sql -q "SELECT * FROM <table>"
      case dolt(["sql", "-r", revision, "-q", "SELECT * FROM `#{path}`", "-r", "json"], repo_path, opts) do
        {:ok, content} -> {:ok, content}
        {:error, _} -> {:error, :not_found}
      end
    end
  end

  @impl true
  def conflicts(opts) do
    with {:ok, repo_path} <- fetch_repo_path(opts),
         {:ok, output} <- dolt(["conflicts", "ls"], repo_path, opts) do
      paths =
        output
        |> String.split("\n", trim: true)
        |> Enum.map(fn table -> %{path: table, type: :file} end)

      {:ok, paths}
    end
  end

  @impl true
  def query(sql, opts) when is_binary(sql) do
    with {:ok, repo_path} <- fetch_repo_path(opts) do
      revision = Keyword.get(opts, :revision, "HEAD")
      case dolt(["sql", "-r", revision, "-q", sql, "-r", "json"], repo_path, opts) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, %{"rows" => rows}} -> {:ok, rows}
            {:ok, []} -> {:ok, []}
            {:ok, _} -> {:ok, []}
            {:error, _} = err -> err
          end
        {:error, _} = err -> err
      end
    end
  end

  @impl true
  def diff(_revision, _opts), do: {:ok, ""}

  @impl true
  def write_files(%{message: message, branch: branch, changes: _changes} = params, opts)
      when is_binary(message) and is_binary(branch) do
    # For Dolt, write_files is a logical commit of the CURRENT database state.
    # We assume the caller has already performed SQL updates via a separate action.
    with {:ok, repo_path} <- fetch_repo_path(opts),
         {:ok, _} <- dolt(["add", "."], repo_path, opts),
         {:ok, _} <- dolt(commit_args(params), repo_path, opts),
         {:ok, commit_sha} <- current_head(branch, opts) do
      {:ok, %{commit_id: commit_sha, change_id: nil, branch: branch}}
    end
  end

  defp commit_args(%{message: message} = params) do
    ["commit"] ++ signing_args(params) ++ ["-m", message]
  end

  defp signing_args(%{sign?: true, signing_key: key}) when is_binary(key) and key != "", do: ["-S", key]
  defp signing_args(%{sign?: true}), do: ["-S"]
  defp signing_args(_params), do: []

  defp fetch_repo_path(opts) do
    case Keyword.get(opts, :repo_path) do
      path when is_binary(path) and path != "" -> {:ok, path}
      _ -> {:error, {:missing_option, :repo_path}}
    end
  end

  defp dolt(args, repo_path, opts) do
    runner = Keyword.get(opts, :runner, SystemCmdRunner)
    dolt_bin = Keyword.get(opts, :dolt_bin, "dolt")

    exec_opts = [cd: repo_path, stderr_to_stdout: true]

    case runner.cmd(dolt_bin, args, exec_opts) do
      {output, 0} ->
        {:ok, output}

      {output, status} ->
        {:error, {:command_failed, status, output}}
    end
  end
end

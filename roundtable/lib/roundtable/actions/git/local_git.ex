defmodule Roundtable.Actions.Git.LocalGit do
  @moduledoc """
  Local `git` implementation of `Roundtable.Actions.Git`.

  Required options:

  - `:repo_path` — path to a local git working tree

  Optional options:

  - `:runner` — command runner module (defaults to `Roundtable.SystemCmdRunner`)
  - `:git_bin` — git executable name (defaults to `"git"`)
  - `:push?` — whether to push after commit (defaults to `false`)
  - `:remote` — remote name used when `push?: true` (defaults to `"origin"`)
  """

  @behaviour Roundtable.Actions.Git

  alias Roundtable.SystemCmdRunner

  @impl true
  def current_head(branch, opts) when is_binary(branch) do
    with {:ok, repo_path} <- fetch_repo_path(opts),
         {:ok, head} <- git(["rev-parse", branch], repo_path, opts) do
      {:ok, String.trim(head)}
    end
  end

  @impl true
  def read_file(path, opts) when is_binary(path) do
    with {:ok, repo_path} <- fetch_repo_path(opts) do
      branch = Keyword.get(opts, :branch)

      case branch do
        nil ->
          File.read(Path.join(repo_path, path))

        branch_name ->
          case git(["show", "#{branch_name}:#{path}"], repo_path, opts) do
            {:ok, content} -> {:ok, content}
            {:error, {:command_failed, 128, _}} -> {:error, :not_found}
            {:error, reason} -> {:error, reason}
          end
      end
    end
  end

  @impl true
  def write_files(%{message: message, branch: branch, changes: changes} = request, opts)
      when is_binary(message) and is_binary(branch) and is_list(changes) do
    with {:ok, repo_path} <- fetch_repo_path(opts),
         :ok <- ensure_index_unlocked(repo_path),
         {:ok, actual_head} <- current_head(branch, opts),
         :ok <- ensure_expected_head(request[:expected_head], actual_head),
         :ok <- checkout_branch(branch, repo_path, opts),
         :ok <- apply_changes(repo_path, changes),
         {:ok, _} <- stage_paths(repo_path, changes, opts),
         {:ok, commit_sha} <- commit_if_needed(message, branch, repo_path, opts),
         :ok <- maybe_push(branch, repo_path, opts) do
      {:ok, %{commit_sha: commit_sha, branch: branch}}
    end
  end

  def write_files(_request, _opts), do: {:error, :invalid_commit_request}

  defp fetch_repo_path(opts) do
    case Keyword.get(opts, :repo_path) do
      path when is_binary(path) and path != "" -> {:ok, path}
      _ -> {:error, {:missing_option, :repo_path}}
    end
  end

  defp ensure_expected_head(nil, _actual_head), do: :ok

  defp ensure_expected_head(expected_head, actual_head) when expected_head == actual_head, do: :ok

  defp ensure_expected_head(expected_head, actual_head) do
    {:error, {:expected_head_mismatch, expected_head, actual_head}}
  end

  defp ensure_index_unlocked(repo_path) do
    lock_path = Path.join([repo_path, ".git", "index.lock"])

    if File.exists?(lock_path) do
      {:error, {:index_locked, lock_path}}
    else
      :ok
    end
  end

  defp checkout_branch(branch, repo_path, opts) do
    case git(["checkout", branch], repo_path, opts) do
      {:ok, _} ->
        :ok

      {:error, {:command_failed, 1, output}} ->
        case git(["checkout", "-b", branch], repo_path, opts) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, normalize_git_error(reason, output)}
        end

      {:error, reason} ->
        {:error, normalize_git_error(reason)}
    end
  end

  defp apply_changes(repo_path, changes) do
    Enum.reduce_while(changes, :ok, fn
      {:put, %{path: path, content: content}}, :ok when is_binary(path) and is_binary(content) ->
        full_path = Path.join(repo_path, path)
        File.mkdir_p!(Path.dirname(full_path))

        case File.write(full_path, content) do
          :ok -> {:cont, :ok}
          {:error, reason} -> {:halt, {:error, {:write_failed, path, reason}}}
        end

      {:delete, %{path: path}}, :ok when is_binary(path) ->
        full_path = Path.join(repo_path, path)

        case File.rm(full_path) do
          :ok -> {:cont, :ok}
          {:error, :enoent} -> {:cont, :ok}
          {:error, reason} -> {:halt, {:error, {:delete_failed, path, reason}}}
        end

      invalid_change, :ok ->
        {:halt, {:error, {:invalid_change, invalid_change}}}
    end)
  end

  defp stage_paths(repo_path, changes, opts) do
    paths =
      changes
      |> Enum.map(fn
        {_, %{path: path}} -> path
      end)
      |> Enum.uniq()

    git(["add", "--all", "--"] ++ paths, repo_path, opts)
  end

  defp commit_if_needed(message, branch, repo_path, opts) do
    case git(["diff", "--cached", "--quiet"], repo_path, opts) do
      {:ok, _} ->
        current_head(branch, opts)

      {:error, {:command_failed, 1, _}} ->
        with {:ok, _} <- git(["commit", "-m", message], repo_path, opts),
             {:ok, commit_sha} <- current_head(branch, opts) do
          {:ok, commit_sha}
        end

      {:error, reason} ->
        {:error, normalize_git_error(reason)}
    end
  end

  defp maybe_push(branch, repo_path, opts) do
    if Keyword.get(opts, :push?, false) do
      remote = Keyword.get(opts, :remote, "origin")

      case git(["push", remote, branch], repo_path, opts) do
        {:ok, _} -> :ok
        {:error, {:command_failed, _status, output}} -> {:error, {:push_rejected, output}}
        {:error, reason} -> {:error, normalize_git_error(reason)}
      end
    else
      :ok
    end
  end

  defp git(args, repo_path, opts) do
    runner = Keyword.get(opts, :runner, SystemCmdRunner)
    git_bin = Keyword.get(opts, :git_bin, "git")

    exec_opts = [cd: repo_path, stderr_to_stdout: true]

    case runner.cmd(git_bin, args, exec_opts) do
      {output, 0} ->
        {:ok, output}

      {output, status} ->
        {:error, normalize_git_error({:command_failed, status, output})}
    end
  end

  defp normalize_git_error(reason, fallback_output \\ nil)

  defp normalize_git_error({:command_failed, _status, output} = error, fallback_output) do
    combined =
      [output, fallback_output]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    if String.contains?(combined, "index.lock") do
      {:index_locked, combined}
    else
      error
    end
  end

  defp normalize_git_error(reason, _fallback_output), do: reason
end

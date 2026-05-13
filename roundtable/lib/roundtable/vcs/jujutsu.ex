defmodule Roundtable.Vcs.Jujutsu do
  @moduledoc """
  Local `jj` (Jujutsu) implementation of `Roundtable.Vcs`.

  Required options:

  - `:repo_path` — path to a local jj repository

  Optional options:

  - `:runner` — command runner module (defaults to `Roundtable.SystemCmdRunner`)
  - `:jj_bin` — jj executable name (defaults to `"jj"`)
  """

  @behaviour Roundtable.Vcs

  alias Roundtable.SystemCmdRunner

  @impl true
  def current_head(revision, opts) when is_binary(revision) do
    with {:ok, repo_path} <- fetch_repo_path(opts),
         {:ok, head} <-
           jj(["log", "-r", revision, "--no-graph", "-T", "commit_id"], repo_path, opts) do
      {:ok, String.trim(head)}
    end
  end

  def current_change_id(revision, opts) when is_binary(revision) do
    with {:ok, repo_path} <- fetch_repo_path(opts),
         {:ok, change_id} <-
           jj(["log", "-r", revision, "--no-graph", "-T", "change_id"], repo_path, opts) do
      {:ok, String.trim(change_id)}
    end
  end

  @impl true
  def read_file(path, opts) when is_binary(path) do
    with {:ok, repo_path} <- fetch_repo_path(opts) do
      revision = Keyword.get(opts, :revision, "@")

      case jj(["file", "show", "-r", revision, path], repo_path, opts) do
        {:ok, content} -> {:ok, content}
        {:error, {:command_failed, _, _}} -> {:error, :not_found}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @impl true
  def conflicts(opts) do
    with {:ok, repo_path} <- fetch_repo_path(opts),
         {:ok, output} <-
           jj(
             ["log", "-r", "conflicts()", "--no-graph", "-T", "separate(\"\\n\", commit_id)"],
             repo_path,
             opts
           ) do
      ids =
        output
        |> String.split("\n", trim: true)
        |> Enum.map(fn id -> %{path: id, type: :other} end)

      {:ok, ids}
    end
  end

  @impl true
  def query(revset, opts) when is_binary(revset) do
    with {:ok, repo_path} <- fetch_repo_path(opts) do
      # Use separate() for reliable template formatting.
      # We append a newline to ensure each revision is on a new line.
      template =
        "separate('|', commit_id, change_id, author.email(), description.first_line()) ++ '\n'"

      cmd_args = ["log", "-r", revset, "--no-graph", "--color", "never", "-T", template]

      case jj(cmd_args, repo_path, opts) do
        {:ok, output} ->
          results =
            output
            |> String.split("\n", trim: true)
            |> Enum.map(fn line ->
              parts = String.split(line, "|")

              case parts do
                [commit_id, change_id, author, description] ->
                  %{
                    commit_id: commit_id,
                    change_id: change_id,
                    author: author,
                    description: description
                  }

                [commit_id, change_id, description] ->
                  %{
                    commit_id: commit_id,
                    change_id: change_id,
                    author: "unknown",
                    description: description
                  }

                _ ->
                  %{
                    commit_id: "unknown",
                    change_id: "unknown",
                    author: "unknown",
                    description: line
                  }
              end
            end)

          {:ok, results}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @impl true
  def diff(revision, opts) when is_binary(revision) do
    with {:ok, repo_path} <- fetch_repo_path(opts) do
      # jj diff --git -r <rev> provides a standard unified diff.
      case jj(["diff", "--git", "-r", revision, "--color", "never"], repo_path, opts) do
        {:ok, content} -> {:ok, content}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @impl true
  def write_files(%{message: message, branch: _branch, changes: changes}, opts)
      when is_binary(message) and is_list(changes) do
    with {:ok, repo_path} <- fetch_repo_path(opts),
         :ok <- apply_changes(repo_path, changes),
         {:ok, _} <- jj(["describe", "-m", message], repo_path, opts),
         {:ok, commit_id} <- current_head("@", opts),
         {:ok, change_id} <- current_change_id("@", opts) do
      # In jj, we often work on the anonymous "working copy" commit (@).
      # Describing it effectively 'commits' the current changes with a message.
      # A new empty working copy commit is then created automatically.
      {:ok, %{commit_id: commit_id, change_id: change_id, branch: "main"}}
    end
  end

  defp fetch_repo_path(opts) do
    case Keyword.get(opts, :repo_path) do
      path when is_binary(path) and path != "" -> {:ok, path}
      _ -> {:error, {:missing_option, :repo_path}}
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

  defp jj(args, repo_path, opts) do
    runner = Keyword.get(opts, :runner, SystemCmdRunner)
    jj_bin = Keyword.get(opts, :jj_bin, "jj")

    exec_opts = [cd: repo_path, stderr_to_stdout: true]

    case runner.cmd(jj_bin, args, exec_opts) do
      {output, 0} ->
        {:ok, output}

      {output, status} ->
        {:error, {:command_failed, status, output}}
    end
  end
end

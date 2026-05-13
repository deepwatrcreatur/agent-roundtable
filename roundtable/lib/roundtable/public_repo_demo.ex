defmodule Roundtable.PublicRepoDemo do
  @moduledoc """
  Builds reproducible public-repo demo snapshots from the curated investor demo
  catalog.

  The first pass does not clone full repositories. Instead, it resolves the
  public source's advertised refs with `git ls-remote`, samples shallow history
  from the tracked branch, then combines that live source metadata with the
  curated Vaglio analysis payload.
  """

  alias Roundtable.{InvestorDemo, SystemCmdRunner}

  @type options :: keyword()

  @spec snapshot(String.t(), options()) :: {:ok, map()} | {:error, term()}
  def snapshot(id, opts \\ []) do
    runner = Keyword.get(opts, :runner, SystemCmdRunner)
    base_url = Keyword.get(opts, :base_url, "https://codeberg.org")
    sample_depth = Keyword.get(opts, :sample_depth, 40)

    with {:ok, demo} <- InvestorDemo.import(id, base_url: base_url),
         {:ok, source_snapshot} <-
           source_snapshot(demo, runner: runner, sample_depth: sample_depth) do
      {:ok,
       %{
         generated_at: Keyword.get(opts, :generated_at, DateTime.utc_now() |> DateTime.to_iso8601()),
         demo: %{
           id: demo.id,
           name: demo.name,
           teaser: demo.teaser
         },
         source: source_snapshot,
         imported_repo: demo.imported_repo,
         shell_inputs: demo.shell_inputs,
         import_steps: demo.import_steps,
         dashboard: demo.dashboard
       }}
    end
  end

  @spec snapshot_with_timeout(String.t(), options()) :: {:ok, map()} | {:error, term()}
  def snapshot_with_timeout(id, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 5_000)
    task = Task.async(fn -> snapshot(id, Keyword.delete(opts, :timeout_ms)) end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      nil -> {:error, :timeout}
    end
  end

  @spec cached_snapshot(String.t(), options()) :: {:ok, map()} | {:error, term()}
  def cached_snapshot(id, opts \\ []) do
    ttl_ms = Keyword.get(opts, :ttl_ms, 15 * 60_000)
    timeout_ms = Keyword.get(opts, :timeout_ms, 5_000)
    cache_root = Keyword.get(opts, :cache_root, default_cache_root())
    snapshot_opts = Keyword.drop(opts, [:ttl_ms, :timeout_ms, :cache_root])

    with :ok <- File.mkdir_p(cache_root) do
      case read_cached_snapshot(cache_path(cache_root, id), ttl_ms) do
        {:ok, snapshot} ->
          {:ok, snapshot}

        {:stale, snapshot} ->
          case snapshot_with_timeout(id, Keyword.merge(snapshot_opts, timeout_ms: timeout_ms)) do
            {:ok, fresh_snapshot} ->
              write_cached_snapshot(cache_path(cache_root, id), fresh_snapshot)
              {:ok, fresh_snapshot}

            {:error, _reason} ->
              {:ok, snapshot}
          end

        :miss ->
          case snapshot_with_timeout(id, Keyword.merge(snapshot_opts, timeout_ms: timeout_ms)) do
            {:ok, fresh_snapshot} ->
              write_cached_snapshot(cache_path(cache_root, id), fresh_snapshot)
              {:ok, fresh_snapshot}

            {:error, _reason} = error ->
              error
          end
      end
    end
  end

  @spec export_snapshot(String.t(), options()) :: {:ok, Path.t()} | {:error, term()}
  def export_snapshot(id, opts \\ []) do
    output_root = Keyword.get(opts, :output_root, "reports/public-repo-demos")

    with {:ok, snapshot} <- snapshot(id, opts) do
      File.mkdir_p!(output_root)
      path = Path.join(output_root, "#{id}.json")
      File.write!(path, Jason.encode_to_iodata!(snapshot, pretty: true))
      {:ok, path}
    end
  end

  defp source_snapshot(demo, opts) do
    runner = Keyword.fetch!(opts, :runner)
    sample_depth = Keyword.get(opts, :sample_depth, 40)
    source = demo.source
    clone_url = clone_url(source.url)
    tracked_ref = "refs/heads/#{demo.shell_inputs.default_branch}"

    with {ls_remote_output, 0} <-
           runner.cmd("git", ["ls-remote", clone_url, "HEAD", tracked_ref], stderr_to_stdout: true),
         {:ok, history_summary} <-
           shallow_history_summary(clone_url, tracked_ref, sample_depth, runner) do
      {:ok,
       %{
         label: source.label,
         slug: source.slug,
         url: source.url,
         clone_url: clone_url,
         tracked_ref: tracked_ref,
         refs: parse_ls_remote(ls_remote_output),
         history_summary: history_summary
       }}
    else
      {output, status} when is_integer(status) ->
        {:error, {:ls_remote_failed, status, output}}

      {:error, _reason} = error ->
        error
    end
  end

  defp shallow_history_summary(clone_url, tracked_ref, sample_depth, runner) do
    repo_dir = Path.join(System.tmp_dir!(), "roundtable-public-demo-#{System.unique_integer([:positive])}")
    depth = Integer.to_string(sample_depth)

    try do
      with {_out, 0} <- runner.cmd("git", ["init", repo_dir], stderr_to_stdout: true),
           {_out, 0} <-
             runner.cmd("git", ["-C", repo_dir, "remote", "add", "origin", clone_url],
               stderr_to_stdout: true
             ),
           {_out, 0} <-
             runner.cmd("git", ["-C", repo_dir, "fetch", "--depth", depth, "origin", tracked_ref],
               stderr_to_stdout: true
             ),
           {count_output, 0} <-
             runner.cmd("git", ["-C", repo_dir, "rev-list", "--count", "FETCH_HEAD"],
               stderr_to_stdout: true
             ),
           {shortlog_output, 0} <-
             runner.cmd("git", ["-C", repo_dir, "shortlog", "-sne", "FETCH_HEAD"],
               stderr_to_stdout: true
             ),
           {log_output, 0} <-
             runner.cmd(
               "git",
               ["-C", repo_dir, "log", "--format=%ct\t%an\t%H", "--max-count=12", "FETCH_HEAD"],
               stderr_to_stdout: true
             ),
           {paths_output, 0} <-
             runner.cmd(
               "git",
               ["-C", repo_dir, "log", "--format=", "--name-only", "--max-count=30", "FETCH_HEAD"],
               stderr_to_stdout: true
             ) do
          parsed_shortlog = parse_shortlog(shortlog_output)
          parsed_recent_commits = parse_recent_commits(log_output)

          {:ok,
           %{
             sample_depth: sample_depth,
             sampled_commit_count: parse_integer(count_output),
             contributor_count: length(parsed_shortlog),
             top_contributors: Enum.take(parsed_shortlog, 5),
             recent_commits: parsed_recent_commits,
             path_hotspots: parse_path_hotspots(paths_output),
             derived_signals:
               build_derived_signals(
                 parse_integer(count_output),
                 parsed_shortlog,
                 parsed_recent_commits
               )
           }}
      else
        {output, status} ->
          {:error, {:history_sampling_failed, status, output}}
      end
    after
      File.rm_rf(repo_dir)
    end
  end

  defp parse_ls_remote(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      case String.split(line, "\t", parts: 2) do
        [sha, ref] -> %{ref: ref, sha: sha}
        [sha] -> %{ref: "unknown", sha: sha}
      end
    end)
  end

  defp clone_url(url) do
    if String.ends_with?(url, ".git"), do: url, else: url <> ".git"
  end

  defp default_cache_root do
    System.get_env(
      "ROUNDTABLE_PUBLIC_REPO_CACHE_DIR",
      Path.join(
        System.get_env("ROUNDTABLE_STATE_DIR", Path.join(System.tmp_dir!(), "roundtable-state")),
        "public-repo-cache"
      )
    )
  end

  defp cache_path(cache_root, id), do: Path.join(cache_root, "#{id}.term")

  defp read_cached_snapshot(path, ttl_ms) do
    with true <- File.exists?(path),
         {:ok, binary} <- File.read(path),
         %{generated_at: generated_at} = snapshot <- :erlang.binary_to_term(binary),
         {:ok, generated_at_dt, _offset} <- DateTime.from_iso8601(generated_at) do
      age_ms = DateTime.diff(DateTime.utc_now(), generated_at_dt, :millisecond)

      if age_ms <= ttl_ms do
        {:ok, snapshot}
      else
        {:stale, snapshot}
      end
    else
      false -> :miss
      _ -> :miss
    end
  end

  defp write_cached_snapshot(path, snapshot) do
    File.write!(path, :erlang.term_to_binary(snapshot))
  end

  defp parse_integer(output) do
    output
    |> String.trim()
    |> Integer.parse()
    |> case do
      {value, _rest} -> value
      :error -> 0
    end
  end

  defp parse_shortlog(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      case Regex.run(~r/^\s*(\d+)\s+(.+?)\s+<([^>]+)>$/, line) do
        [_, count, name, email] ->
          %{
            commits: String.to_integer(count),
            author: String.trim(name),
            email: email
          }

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_recent_commits(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      case String.split(line, "\t", parts: 3) do
        [timestamp, author, sha] ->
          %{
            committed_at_unix: String.to_integer(timestamp),
            author: author,
            sha: sha
          }

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp build_derived_signals(sampled_commit_count, contributors, recent_commits) do
    top_commit_count =
      contributors
      |> Enum.take(3)
      |> Enum.map(& &1.commits)
      |> Enum.sum()

    top_author_share =
      if sampled_commit_count > 0 do
        Float.round(top_commit_count / sampled_commit_count, 2)
      else
        0.0
      end

    commit_velocity =
      case recent_commits do
        [%{committed_at_unix: newest} | _] = commits ->
          oldest = commits |> List.last() |> Map.fetch!(:committed_at_unix)
          span_days = max((newest - oldest) / 86_400, 1.0)
          Float.round(length(commits) / span_days, 2)

        _ ->
          0.0
      end

    %{
      top_author_share: top_author_share,
      commits_per_day_window: commit_velocity,
      contributor_concentration:
        cond do
          top_author_share >= 0.65 -> "high"
          top_author_share >= 0.45 -> "medium"
          true -> "low"
        end
    }
  end

  defp parse_path_hotspots(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.reject(&(&1 == ""))
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_path, count} -> -count end)
    |> Enum.take(8)
    |> Enum.map(fn {path, count} -> %{path: path, mentions: count} end)
  end
end

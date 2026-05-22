defmodule Roundtable.PublicRepoDemoReportEntriesTest do
  use ExUnit.Case, async: true

  alias Roundtable.PublicRepoDemo

  defmodule FakeCommandRunner do
    @behaviour Roundtable.CommandRunner
    @handler_key {__MODULE__, :handler}

    @impl true
    def cmd(command, args, opts) do
      handler = :persistent_term.get(@handler_key, nil) || raise "missing fake command handler"
      handler.(command, args, opts)
    end
  end

  setup do
    :persistent_term.put({FakeCommandRunner, :handler}, fn
      "git", ["ls-remote", _clone_url, "HEAD", tracked_ref], _opts ->
        {"123abc\tHEAD\n456def\t#{tracked_ref}\n", 0}

      "git", ["init", _repo_dir], _opts ->
        {"Initialized empty Git repository\n", 0}

      "git", ["-C", _repo_dir, "remote", "add", "origin", _clone_url], _opts ->
        {"", 0}

      "git", ["-C", _repo_dir, "fetch", "--depth", _depth, "origin", _tracked_ref], _opts ->
        {"", 0}

      "git", ["-C", _repo_dir, "rev-list", "--count", "FETCH_HEAD"], _opts ->
        {"40\n", 0}

      "git", ["-C", _repo_dir, "shortlog", "-sne", "FETCH_HEAD"], _opts ->
        {"   22  Alice Example <alice@example.com>\n   11  Bob Example <bob@example.com>\n    7  Carol Example <carol@example.com>\n", 0}

      "git", ["-C", _repo_dir, "log", "--format=%ct\t%an\t%H", "--max-count=" <> _limit, "FETCH_HEAD"], _opts ->
        {"1715616000\tAlice Example\tdeadbeef\n1715529600\tBob Example\tcafebabe\n", 0}

      "git", ["-C", _repo_dir, "log", "--format=", "--name-only", "--max-count=" <> _limit, "FETCH_HEAD"], _opts ->
        {"pkg/a\npkg/a\npkg/b\n", 0}
    end)

    :ok
  end

  test "builds report entries from cached snapshots" do
    cache_root = Path.join(System.tmp_dir!(), "roundtable-public-reports-#{System.unique_integer()}")

    assert {:ok, _snapshot} =
             PublicRepoDemo.cached_snapshot("forgejo",
        runner: FakeCommandRunner,
        cache_root: cache_root,
        ttl_ms: 60_000,
        timeout_ms: 100
      )

    entries =
      PublicRepoDemo.report_entries(
        runner: FakeCommandRunner,
        cache_root: cache_root
      )

    forgejo = Enum.find(entries, &(&1.demo.id == "forgejo"))

    assert forgejo.cache_status == :cached
    assert forgejo.source.slug == "forgejo/forgejo"
    assert forgejo.source.history_summary.sampled_commit_count == 40
  end
end

defmodule Roundtable.PublicRepoDemoTest do
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

  defmodule SlowCommandRunner do
    @behaviour Roundtable.CommandRunner

    @impl true
    def cmd(_command, _args, _opts) do
      Process.sleep(50)
      {"", 0}
    end
  end

  setup do
    :persistent_term.put({FakeCommandRunner, :handler}, fn
      "git", ["ls-remote", clone_url, "HEAD", tracked_ref], _opts ->
        assert clone_url == "https://github.com/NixOS/nixpkgs.git"
        assert tracked_ref == "refs/heads/master"

        {"123abc\tHEAD\n456def\trefs/heads/master\n", 0}

      "git", ["init", repo_dir], _opts ->
        assert String.contains?(repo_dir, "roundtable-public-demo-")
        {"Initialized empty Git repository\n", 0}

      "git", ["-C", repo_dir, "remote", "add", "origin", clone_url], _opts ->
        assert String.contains?(repo_dir, "roundtable-public-demo-")
        assert clone_url == "https://github.com/NixOS/nixpkgs.git"
        {"", 0}

      "git", ["-C", repo_dir, "fetch", "--depth", depth, "origin", tracked_ref], _opts ->
        assert String.contains?(repo_dir, "roundtable-public-demo-")
        assert depth == "40"
        assert tracked_ref == "refs/heads/master"
        {"", 0}

      "git", ["-C", repo_dir, "rev-list", "--count", "FETCH_HEAD"], _opts ->
        assert String.contains?(repo_dir, "roundtable-public-demo-")
        {"40\n", 0}

      "git", ["-C", repo_dir, "shortlog", "-sne", "FETCH_HEAD"], _opts ->
        assert String.contains?(repo_dir, "roundtable-public-demo-")
        {"   22  Alice Example <alice@example.com>\n   11  Bob Example <bob@example.com>\n    7  Carol Example <carol@example.com>\n", 0}

      "git", ["-C", repo_dir, "log", "--format=%ct\t%an\t%H", "--max-count=12", "FETCH_HEAD"], _opts ->
        assert String.contains?(repo_dir, "roundtable-public-demo-")
        {"1715616000\tAlice Example\tdeadbeef\n1715529600\tBob Example\tcafebabe\n1715443200\tCarol Example\t8badf00d\n", 0}

      "git", ["-C", repo_dir, "log", "--format=", "--name-only", "--max-count=30", "FETCH_HEAD"], _opts ->
        assert String.contains?(repo_dir, "roundtable-public-demo-")
        {"pkgs/top-level/all-packages.nix\npkgs/top-level/all-packages.nix\nnixos/modules/services/networking/firewall.nix\nnixos/modules/services/networking/firewall.nix\nnixos/modules/services/networking/firewall.nix\n", 0}

      command, args, _opts ->
        flunk("unexpected command: #{inspect({command, args})}")
    end)

    :ok
  end

  test "builds a reproducible snapshot with live source refs" do
    assert {:ok, snapshot} = PublicRepoDemo.snapshot("nixpkgs", runner: FakeCommandRunner)

    assert snapshot.demo.id == "nixpkgs"
    assert snapshot.source.clone_url == "https://github.com/NixOS/nixpkgs.git"
    assert snapshot.source.tracked_ref == "refs/heads/master"
    assert Enum.any?(snapshot.source.refs, &(&1.ref == "HEAD"))
    assert Enum.any?(snapshot.source.refs, &(&1.ref == "refs/heads/master"))
    assert snapshot.source.history_summary.sampled_commit_count == 40
    assert snapshot.source.history_summary.contributor_count == 3
    assert Enum.at(snapshot.source.history_summary.path_hotspots, 0) == %{
             path: "nixos/modules/services/networking/firewall.nix",
             mentions: 3
           }
    assert snapshot.source.history_summary.derived_signals.top_author_share == 1.0
    assert snapshot.source.history_summary.derived_signals.contributor_concentration == "high"
    assert snapshot.dashboard.stress.headline =~ "Prediction error"
  end

  test "exports the snapshot as JSON" do
    output_root = Path.join(System.tmp_dir!(), "roundtable-public-repo-demo-#{System.unique_integer()}")

    assert {:ok, path} =
             PublicRepoDemo.export_snapshot("nixpkgs",
               runner: FakeCommandRunner,
               output_root: output_root,
               generated_at: "2026-05-13T16:00:00Z"
             )

    assert path == Path.join(output_root, "nixpkgs.json")
    assert File.exists?(path)

    payload = Jason.decode!(File.read!(path))
    assert get_in(payload, ["demo", "id"]) == "nixpkgs"
    assert get_in(payload, ["source", "tracked_ref"]) == "refs/heads/master"
    assert get_in(payload, ["source", "history_summary", "sampled_commit_count"]) == 40
    assert get_in(payload, ["source", "history_summary", "path_hotspots"]) != []
    assert get_in(payload, ["dashboard", "stress", "headline"]) =~ "Prediction error"
  end

  test "times out slow snapshots for interactive surfaces" do
    assert {:error, :timeout} =
             PublicRepoDemo.snapshot_with_timeout("nixpkgs",
               runner: SlowCommandRunner,
               timeout_ms: 1
             )
  end

  test "reuses a fresh cached snapshot without running git again" do
    cache_root = Path.join(System.tmp_dir!(), "roundtable-public-cache-#{System.unique_integer()}")

    assert {:ok, first_snapshot} =
             PublicRepoDemo.cached_snapshot("nixpkgs",
               runner: FakeCommandRunner,
               cache_root: cache_root,
               ttl_ms: 60_000,
               timeout_ms: 100
             )

    :persistent_term.put({FakeCommandRunner, :handler}, fn command, args, _opts ->
      flunk("cache should have avoided command execution: #{inspect({command, args})}")
    end)

    assert {:ok, second_snapshot} =
             PublicRepoDemo.cached_snapshot("nixpkgs",
               runner: FakeCommandRunner,
               cache_root: cache_root,
               ttl_ms: 60_000,
               timeout_ms: 100
             )

    assert second_snapshot.source == first_snapshot.source
  end

  test "falls back to stale cache when refresh times out" do
    cache_root = Path.join(System.tmp_dir!(), "roundtable-public-cache-#{System.unique_integer()}")
    cache_file = Path.join(cache_root, "nixpkgs.term")

    File.mkdir_p!(cache_root)

    stale_snapshot = %{
      generated_at: "2026-05-12T16:00:00Z",
      demo: %{id: "nixpkgs", name: "Nixpkgs", teaser: "cached"},
      source: %{slug: "cached/source", history_summary: %{sampled_commit_count: 9}},
      imported_repo: %{},
      shell_inputs: %{},
      import_steps: [],
      dashboard: %{stress: %{headline: "cached"}}
    }

    File.write!(cache_file, :erlang.term_to_binary(stale_snapshot))

    assert {:ok, snapshot} =
             PublicRepoDemo.cached_snapshot("nixpkgs",
               runner: SlowCommandRunner,
               cache_root: cache_root,
               ttl_ms: 1,
               timeout_ms: 1
             )

    assert snapshot.source.slug == "cached/source"
    assert snapshot.source.history_summary.sampled_commit_count == 9
  end
end

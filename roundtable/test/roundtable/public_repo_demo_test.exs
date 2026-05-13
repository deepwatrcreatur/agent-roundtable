defmodule Roundtable.PublicRepoDemoTest do
  use ExUnit.Case, async: true

  alias Roundtable.PublicRepoDemo

  defmodule FakeCommandRunner do
    @behaviour Roundtable.CommandRunner

    @impl true
    def cmd(command, args, opts) do
      handler = Process.get({__MODULE__, :handler}) || raise "missing fake command handler"
      handler.(command, args, opts)
    end
  end

  setup do
    Process.put({FakeCommandRunner, :handler}, fn
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
    assert get_in(payload, ["dashboard", "stress", "headline"]) =~ "Prediction error"
  end
end

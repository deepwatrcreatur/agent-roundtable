defmodule Roundtable.PublicRepoSnaReportsTest do
  use ExUnit.Case, async: false

  alias Roundtable.{PublicRepoDemo, PublicRepoSnaReports}

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

  test "renders a markdown report from a snapshot" do
    assert {:ok, snapshot} =
             PublicRepoDemo.snapshot("forgejo",
               runner: FakeCommandRunner,
               generated_at: "2026-05-22T13:00:00Z"
             )

    report = PublicRepoSnaReports.render_report(snapshot)

    assert report =~ "# forgejo/forgejo — Project Mind Report"
    assert report =~ "## Project Mind Heatmap"
    assert report =~ "## Contributor Concentration"
    assert report =~ "## Path Hotspots"
    assert report =~ "Investigate and adversarially review"
    assert report =~ "Alice Example"
  end

  test "exports a markdown bundle and index" do
    output_root = Path.join(System.tmp_dir!(), "roundtable-sna-reports-#{System.unique_integer()}")
    snapshot_output_root = Path.join(System.tmp_dir!(), "roundtable-sna-snapshots-#{System.unique_integer()}")

    assert {:ok, paths} =
             PublicRepoSnaReports.export_all(
               runner: FakeCommandRunner,
               output_root: output_root,
               snapshot_output_root: snapshot_output_root
             )

    assert Enum.any?(paths, &String.ends_with?(&1, "README.md"))
    assert File.exists?(Path.join(output_root, "forgejo.md"))
    assert File.exists?(Path.join(output_root, "kubernetes.md"))
    assert File.exists?(Path.join(output_root, "nixpkgs.md"))
    assert File.exists?(Path.join(snapshot_output_root, "forgejo.json"))
  end

  test "renders safely when sampled hotspots or contributors are empty" do
    snapshot = %{
      generated_at: "2026-05-22T13:00:00Z",
      demo: %{id: "demo", name: "demo/repo"},
      source: %{
        history_summary: %{
          sampled_commit_count: 0,
          contributor_count: 0,
          top_contributors: [],
          path_hotspots: [],
          recent_commits: [],
          derived_signals: %{
            contributor_concentration: "low",
            top_author_share: 0.0
          }
        }
      },
      dashboard: %{
        headline: "headline",
        narrative: "narrative",
        stress: %{
          metrics: [
            %{label: "Branch stress", value: "0.10"},
            %{label: "History heat", value: "1 peak"},
            %{label: "Active-inference confidence", value: "low"}
          ],
          hotspots: []
        }
      }
    }

    report = PublicRepoSnaReports.render_report(snapshot)

    assert report =~ "no sampled hotspot"
    assert report =~ "No dominant contributor"
  end
end

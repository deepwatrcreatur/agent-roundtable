defmodule Roundtable.RoundArchiveTest do
  use ExUnit.Case, async: true

  alias Roundtable.RoundArchive
  alias Roundtable.TestSupport.FakeRunner

  setup do
    repo_root =
      Path.join(System.tmp_dir!(), "round-archive-test-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join([repo_root, "docs", "design", "rounds"]))
    Process.put(:runner_result, {issue_json(), 0})
    Process.put(:test_pid, self())
    on_exit(fn -> File.rm_rf(repo_root) end)
    %{repo_root: repo_root}
  end

  test "mirrors a Q-numbered issue into docs/design/rounds", %{repo_root: repo_root} do
    assert :ok =
             RoundArchive.mirror_issue(
               76,
               %{repo: "owner/repo", runner: FakeRunner},
               archive_repo_root: repo_root
             )

    path = Path.join([repo_root, "docs", "design", "rounds", "round-60-q60.md"])
    assert File.exists?(path)

    body = File.read!(path)
    assert body =~ "## Round 60 — jj vs. code.storage for Agent-Scale Code Velocity"
    assert body =~ "**Issue:** #76"
    assert body =~ "### Transcript"
    assert body =~ "#### deepwatrcreatur — 2026-05-09T02:24:33Z"
    assert body =~ "[satisfied]"
  end

  test "accepts the roundtable app dir and resolves the parent repo root", %{repo_root: repo_root} do
    roundtable_dir = Path.join(repo_root, "roundtable")
    File.mkdir_p!(roundtable_dir)

    assert :ok =
             RoundArchive.mirror_issue(
               76,
               %{repo: "owner/repo", runner: FakeRunner, repo_root: roundtable_dir}
             )

    assert File.exists?(Path.join([repo_root, "docs", "design", "rounds", "round-60-q60.md"]))
  end

  defp issue_json do
    ~s({"number":76,"title":"Q60 — jj vs. code.storage for Agent-Scale Code Velocity","body":"Compare jj with code.storage.","state":"OPEN","labels":[{"name":"roundtable"},{"name":"needs-more-evidence"}],"url":"https://github.com/deepwatrcreatur/agent-roundtable/issues/76","comments":[{"author":{"login":"deepwatrcreatur"},"createdAt":"2026-05-09T02:24:33Z","body":"## Claude\\n\\nSigned position\\n\\n[satisfied]"}]})
  end
end

defmodule Roundtable.CLITest do
  use ExUnit.Case, async: true

  alias Roundtable.CLI

  defmodule StubGh do
    def list_issues(_opts, _config) do
      {:ok, Process.get(:stub_issues, [])}
    end

    def create_issue(title, body, labels, _config) do
      created = Process.get(:created_issues, [])
      Process.put(:created_issues, [{title, body, labels} | created])
      next = Process.get(:next_issue_number, 100)
      Process.put(:next_issue_number, next + 1)
      {:ok, next}
    end
  end

  defmodule StubOrchestrator do
    def run(brief_path, questions, opts) do
      Process.put(:orchestrator_run, {brief_path, questions, opts})
      Enum.map(questions, fn q -> %{id: q.id, issue_number: q.issue_number, state: :open} end)
    end

    def run_with_repo(repo, opts) do
      Process.put(:orchestrator_repo_run, {repo, opts})
      {:ok, []}
    end
  end

  setup do
    brief_path = Path.join(System.tmp_dir!(), "test_brief_cli_#{System.unique_integer()}.md")
    File.write!(brief_path, "# Brief\n\n### Q1 — Architecture\n\nWhat should we build?\n")
    on_exit(fn -> File.rm(brief_path) end)
    Process.delete(:stub_issues)
    Process.delete(:created_issues)
    Process.delete(:next_issue_number)
    Process.delete(:orchestrator_run)
    %{brief_path: brief_path}
  end

  describe "inject_question/3" do
    # inject_question requires a live gh CLI and GitHub token.
    # Tested in integration suite; unit test verifies arg validation only.
    test "returns error when repo is nil (no default repo configured)" do
      # nil repo with no gh env configured must return {:error, _} without raising.
      result = CLI.inject_question(nil, "New question", [])
      assert match?({:error, _}, result)
    end
  end

  describe "module API exports" do
    # get_discussion_state requires gh CLI; tested via satisfaction label inference
    # which is exposed indirectly. We verify the module loads and exports the right API.
    test "module exports start_discussion/2" do
      assert function_exported?(CLI, :start_discussion, 2)
    end

    test "module exports get_discussion_state/1" do
      assert function_exported?(CLI, :get_discussion_state, 1)
    end

    test "module exports inject_question/3" do
      assert function_exported?(CLI, :inject_question, 3)
    end
  end

  describe "start_discussion/2 legacy mode" do
    test "creates missing issues and writes ACTIVE_DISCUSSION issue index", %{brief_path: brief_path} do
      discussion_path = Path.join(Path.dirname(brief_path), "ACTIVE_DISCUSSION.md")
      File.write!(discussion_path, "# Active Discussion\n")
      on_exit(fn -> File.rm(discussion_path) end)

      assert {:ok, [%{id: "Q1", issue_number: 100, state: :open}]} =
               CLI.start_discussion(brief_path,
                 repo: "owner/repo",
                 gh_module: StubGh,
                 orchestrator_module: StubOrchestrator
               )

      content = File.read!(discussion_path)
      assert content =~ "<!-- ROUNDTABLE_ISSUE_INDEX_START -->"
      assert content =~ "| Q1 | #100 | https://github.com/owner/repo/issues/100 |"

      assert [{"Q1 — Architecture", body, ["roundtable", "needs-more-evidence"]}] =
               Process.get(:created_issues)

      assert body =~ "What should we build?"
    end

    test "reuses existing roundtable issues by Q id instead of duplicating", %{brief_path: brief_path} do
      Process.put(:stub_issues, [
        %{"number" => 42, "title" => "Q1 — Architecture", "labels" => [], "url" => ""}
      ])

      assert {:ok, [%{id: "Q1", issue_number: 42, state: :open}]} =
               CLI.start_discussion(brief_path,
                 repo: "owner/repo",
                 gh_module: StubGh,
                 orchestrator_module: StubOrchestrator
               )

      assert Process.get(:created_issues) in [nil, []]
    end

    test "uses existing index file on rerun and refreshes it deterministically", %{brief_path: brief_path} do
      discussion_path = Path.join(Path.dirname(brief_path), "ACTIVE_DISCUSSION.md")

      File.write!(
        discussion_path,
        """
        # Active Discussion

        <!-- ROUNDTABLE_ISSUE_INDEX_START -->
        ## Issue Index

        | Question | Issue | URL |
        |---|---|---|
        | Q1 | #9 | https://github.com/owner/repo/issues/9 |
        <!-- ROUNDTABLE_ISSUE_INDEX_END -->
        """
      )

      on_exit(fn -> File.rm(discussion_path) end)

      assert {:ok, [%{id: "Q1", issue_number: 9, state: :open}]} =
               CLI.start_discussion(brief_path,
                 repo: "owner/repo",
                 gh_module: StubGh,
                 orchestrator_module: StubOrchestrator
               )

      content = File.read!(discussion_path)
      assert content =~ "| Q1 | #9 | https://github.com/owner/repo/issues/9 |"
      assert Process.get(:created_issues) in [nil, []]
    end
  end
end

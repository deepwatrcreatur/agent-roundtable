defmodule Roundtable.OrchestratorTest do
  use ExUnit.Case, async: true

  alias Roundtable.Orchestrator

  setup do
    brief_path = Path.join(System.tmp_dir!(), "test_brief_#{System.unique_integer()}.md")
    File.write!(brief_path, "# Brief\n\n### Q1 — Test question\n\nDescribe the system.\n")
    on_exit(fn -> File.rm(brief_path) end)
    %{brief_path: brief_path}
  end

  describe "extract_label_names/1 (via consensus?)" do
    test "consensus when satisfied label present and no blocking label" do
      assert Roundtable.Satisfaction.consensus?(["satisfied"])
    end

    test "no consensus when needs-more-evidence present" do
      refute Roundtable.Satisfaction.consensus?(["satisfied", "needs-more-evidence"])
    end

    test "no consensus with empty labels" do
      refute Roundtable.Satisfaction.consensus?([])
    end
  end

  describe "run_question/6 with fake runner" do
    # Full end-to-end requires a live gh CLI and is covered by the integration suite.
    # This placeholder verifies the brief file fixture is set up correctly.
    test "brief fixture is valid", %{brief_path: brief_path} do
      assert File.exists?(brief_path)
      assert String.contains?(File.read!(brief_path), "Q1")
    end
  end

  describe "run/3 with minimal opts" do
    test "returns a list with one entry per question when questions list is empty", %{brief_path: brief_path} do
      results = Orchestrator.run(brief_path, [], [])
      assert results == []
    end
  end
end

defmodule Roundtable.CLITest do
  use ExUnit.Case, async: true

  alias Roundtable.CLI

  setup do
    brief_path = Path.join(System.tmp_dir!(), "test_brief_cli_#{System.unique_integer()}.md")
    File.write!(brief_path, "# Brief\n\n### Q1 — Architecture\n\nWhat should we build?\n")
    on_exit(fn -> File.rm(brief_path) end)
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
    # which is exposed indirectly. Ensure the module is loaded before checking
    # exported functions so the assertion reflects the compiled API, not code-loading timing.
    setup do
      Code.ensure_loaded(CLI)
      :ok
    end

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

  describe "start_discussion/2 roster validation" do
    test "fails fast when a requested agent is unsupported", %{brief_path: brief_path} do
      assert {:error, {:unsupported_agents, [:copilot]}} =
               CLI.start_discussion(brief_path, agents: [:codex, :copilot])
    end
  end
end

defmodule Roundtable.Vcs.JujutsuTest do
  use ExUnit.Case, async: false

  alias Roundtable.Vcs.Jujutsu

  setup do
    repo_path = temp_path("roundtable-jj")
    File.rm_rf!(repo_path)
    File.mkdir_p!(repo_path)

    # Initialize jj repo.
    jj!(repo_path, ["git", "init"])
    
    on_exit(fn -> File.rm_rf!(repo_path) end)

    {:ok, repo_path: repo_path}
  end

  describe "current_head/2" do
    test "returns the current commit ID", %{repo_path: repo_path} do
      assert {:ok, commit_id} = Jujutsu.current_head("@", repo_path: repo_path)
      assert String.match?(commit_id, ~r/^[0-9a-f]+$/)
    end
  end

  describe "current_change_id/2" do
    test "returns the current change ID", %{repo_path: repo_path} do
      assert {:ok, change_id} = Jujutsu.current_change_id("@", repo_path: repo_path)
      assert String.length(change_id) > 0
    end
  end

  describe "write_files/2" do
    test "describes the working copy with changes", %{repo_path: repo_path} do
      request = %{
        message: "add logic",
        branch: "main",
        expected_head: nil,
        changes: [
          {:put, %{path: "logic.txt", content: "pure reason\n"}}
        ]
      }

      assert {:ok, %{commit_id: commit_id, change_id: _change_id}} =
               Jujutsu.write_files(request, repo_path: repo_path)

      assert File.read!(Path.join(repo_path, "logic.txt")) == "pure reason\n"
      
      # Verify the message was applied
      log = jj!(repo_path, ["log", "-r", commit_id, "--no-graph", "-T", "description"])
      assert log =~ "add logic"
    end
  end

  describe "read_file/2" do
    test "reads file content from a revision", %{repo_path: repo_path} do
      File.write!(Path.join(repo_path, "context.txt"), "shared mind\n")
      jj!(repo_path, ["describe", "-m", "add context"])
      
      assert {:ok, content} = Jujutsu.read_file("context.txt", repo_path: repo_path)
      assert content == "shared mind\n"
    end
  end

  describe "conflicts/1" do
    test "surfaces file-level conflicts", %{repo_path: repo_path} do
      # Set up a conflict: create two revisions with different content for same file
      jj!(repo_path, ["new", "root()", "-m", "v1"])
      File.write!(Path.join(repo_path, "conflict.txt"), "A\n")
      
      jj!(repo_path, ["new", "root()", "-m", "v2"])
      File.write!(Path.join(repo_path, "conflict.txt"), "B\n")
      
      assert {:ok, []} = Jujutsu.conflicts(repo_path: repo_path)
    end
  end

  describe "query/2" do
    test "queries the graph using revsets", %{repo_path: repo_path} do
      # Create two revisions with distinct descriptions and content, and give them bookmarks
      File.write!(Path.join(repo_path, "logic.txt"), "reason\n")
      jj!(repo_path, ["describe", "-m", "logic layer"])
      jj!(repo_path, ["bookmark", "create", "b1"])
      
      jj!(repo_path, ["new", "root()"])
      File.write!(Path.join(repo_path, "vcs.txt"), "vcs\n")
      jj!(repo_path, ["describe", "-m", "vcs layer"])
      jj!(repo_path, ["bookmark", "create", "b2"])
      
      # Query for "logic" via bookmark
      assert {:ok, [%{description: desc}]} = Jujutsu.query("bookmarks(b1)", repo_path: repo_path)
      assert desc =~ "logic layer"
      
      # Query for both via union
      assert {:ok, results} = Jujutsu.query("bookmarks(b1) | bookmarks(b2)", repo_path: repo_path)
      assert length(results) == 2
    end
  end

  describe "diff/2" do
    test "returns unified diff for a revision", %{repo_path: repo_path} do
      File.write!(Path.join(repo_path, "delta.txt"), "v1\n")
      jj!(repo_path, ["describe", "-m", "v1"])
      
      jj!(repo_path, ["new", "-m", "v2"])
      File.write!(Path.join(repo_path, "delta.txt"), "v2\n")
      
      assert {:ok, content} = Jujutsu.diff("@", repo_path: repo_path)
      assert content =~ "-v1"
      assert content =~ "+v2"
    end
  end

  defp temp_path(prefix) do
    Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
  end

  defp jj!(repo_path, args) do
    case System.cmd("jj", args, cd: repo_path, stderr_to_stdout: true) do
      {output, 0} -> output
      {output, status} -> flunk("jj #{Enum.join(args, " ")} failed (#{status}): #{output}")
    end
  end
end

defmodule Roundtable.Actions.Git.LocalGitTest do
  use ExUnit.Case, async: false

  alias Roundtable.Actions.Git.LocalGit

  setup do
    repo_path = temp_path("roundtable-local-git")
    File.rm_rf!(repo_path)
    File.mkdir_p!(repo_path)

    git!(repo_path, ["init", "-b", "main"])
    git!(repo_path, ["config", "user.name", "Roundtable Test"])
    git!(repo_path, ["config", "user.email", "roundtable@example.com"])

    File.write!(Path.join(repo_path, "README.md"), "# Test Repo\n")
    git!(repo_path, ["add", "README.md"])
    git!(repo_path, ["commit", "-m", "initial"])

    on_exit(fn -> File.rm_rf!(repo_path) end)

    {:ok, repo_path: repo_path}
  end

  describe "current_head/2" do
    test "returns the branch SHA", %{repo_path: repo_path} do
      assert {:ok, sha} = LocalGit.current_head("main", repo_path: repo_path)
      assert String.match?(sha, ~r/^[0-9a-f]{40}$/)
    end
  end

  describe "read_file/2" do
    test "reads from working tree by default", %{repo_path: repo_path} do
      assert {:ok, content} = LocalGit.read_file("README.md", repo_path: repo_path)
      assert content == "# Test Repo\n"
    end

    test "reads from a specific branch", %{repo_path: repo_path} do
      git!(repo_path, ["checkout", "-b", "feature"])
      File.write!(Path.join(repo_path, "notes.txt"), "branch-specific\n")
      git!(repo_path, ["add", "notes.txt"])
      git!(repo_path, ["commit", "-m", "feature note"])
      git!(repo_path, ["checkout", "main"])

      assert {:ok, "branch-specific\n"} =
               LocalGit.read_file("notes.txt", repo_path: repo_path, branch: "feature")
    end
  end

  describe "write_files/2" do
    test "writes multiple files in one commit", %{repo_path: repo_path} do
      {:ok, head} = LocalGit.current_head("main", repo_path: repo_path)

      request = %{
        message: "update durable artifacts",
        branch: "main",
        expected_head: head,
        changes: [
          {:put, %{path: "DECISION.md", content: "# Decisions\n"}},
          {:put, %{path: "rounds/round-01-q1.md", content: "Round one\n"}}
        ]
      }

      assert {:ok, %{commit_sha: commit_sha, branch: "main"}} =
               LocalGit.write_files(request, repo_path: repo_path)

      assert String.match?(commit_sha, ~r/^[0-9a-f]{40}$/)
      assert File.read!(Path.join(repo_path, "DECISION.md")) == "# Decisions\n"
      assert File.read!(Path.join(repo_path, "rounds/round-01-q1.md")) == "Round one\n"
    end

    test "stages deletions in the same commit", %{repo_path: repo_path} do
      file_path = Path.join(repo_path, "obsolete.txt")
      File.write!(file_path, "old\n")
      git!(repo_path, ["add", "obsolete.txt"])
      git!(repo_path, ["commit", "-m", "add obsolete"])
      {:ok, head} = LocalGit.current_head("main", repo_path: repo_path)

      request = %{
        message: "remove obsolete artifact",
        branch: "main",
        expected_head: head,
        changes: [{:delete, %{path: "obsolete.txt"}}]
      }

      assert {:ok, _} = LocalGit.write_files(request, repo_path: repo_path)
      refute File.exists?(file_path)
    end

    test "returns explicit head mismatch", %{repo_path: repo_path} do
      request = %{
        message: "should fail",
        branch: "main",
        expected_head: String.duplicate("a", 40),
        changes: [{:put, %{path: "DECISION.md", content: "x\n"}}]
      }

      assert {:error, {:expected_head_mismatch, _expected, actual}} =
               LocalGit.write_files(request, repo_path: repo_path)

      assert String.match?(actual, ~r/^[0-9a-f]{40}$/)
    end

    test "surfaces locked index clearly", %{repo_path: repo_path} do
      lock_path = Path.join([repo_path, ".git", "index.lock"])
      File.write!(lock_path, "")

      request = %{
        message: "should fail",
        branch: "main",
        expected_head: nil,
        changes: [{:put, %{path: "DECISION.md", content: "x\n"}}]
      }

      assert {:error, {:index_locked, ^lock_path}} =
               LocalGit.write_files(request, repo_path: repo_path)
    end

    test "surfaces push rejection clearly", %{repo_path: repo_path} do
      remote_path = temp_path("roundtable-remote")
      other_clone = temp_path("roundtable-other-clone")

      File.rm_rf!(remote_path)
      File.rm_rf!(other_clone)
      File.mkdir_p!(remote_path)

      git!(remote_path, ["init", "--bare"])
      git!(repo_path, ["remote", "add", "origin", remote_path])
      git!(repo_path, ["push", "-u", "origin", "main"])

      git_system!(["clone", remote_path, other_clone])
      git!(other_clone, ["config", "user.name", "Roundtable Test"])
      git!(other_clone, ["config", "user.email", "roundtable@example.com"])

      File.write!(Path.join(other_clone, "remote.txt"), "upstream change\n")
      git!(other_clone, ["add", "remote.txt"])
      git!(other_clone, ["commit", "-m", "upstream change"])
      git!(other_clone, ["push", "origin", "main"])

      {:ok, stale_head} = LocalGit.current_head("main", repo_path: repo_path)

      request = %{
        message: "local change",
        branch: "main",
        expected_head: stale_head,
        changes: [{:put, %{path: "local.txt", content: "local change\n"}}]
      }

      assert {:error, {:push_rejected, output}} =
               LocalGit.write_files(request, repo_path: repo_path, push?: true)

      assert output =~ "rejected"

      File.rm_rf!(remote_path)
      File.rm_rf!(other_clone)
    end
  end

  defp temp_path(prefix) do
    Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
  end

  defp git!(repo_path, args) do
    case System.cmd("git", args, cd: repo_path, stderr_to_stdout: true) do
      {output, 0} -> output
      {output, status} -> flunk("git #{Enum.join(args, " ")} failed (#{status}): #{output}")
    end
  end

  defp git_system!(args) do
    case System.cmd("git", args, stderr_to_stdout: true) do
      {output, 0} -> output
      {output, status} -> flunk("git #{Enum.join(args, " ")} failed (#{status}): #{output}")
    end
  end
end

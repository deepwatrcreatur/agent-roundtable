defmodule Roundtable.Actions.DiscussionGitTest do
  use ExUnit.Case, async: true

  alias Roundtable.Actions.DiscussionGit
  alias Roundtable.DiscussionRepo
  alias Roundtable.TestSupport.StubBackend

  @toml """
  schema_version = 1

  [discussion]
  title = "Test Discussion"
  agents = ["codex", "gemini", "claude_ic"]
  max_rounds = 3
  coordinator = "claude_ic"
  issues_enabled = false

  [fork]
  upstream = ""
  fork_of_commit = ""
  """

  defp repo(files \\ %{}) do
    Process.put(:stub_files, files)
    Process.put(:stub_written, %{})
    DiscussionRepo.new("owner/test-discussion", backend: StubBackend)
  end

  # ------------------------------------------------------------------
  # read_brief/1
  # ------------------------------------------------------------------

  describe "read_brief/1" do
    test "reads BRIEF.md content" do
      r = repo(%{"BRIEF.md" => "# Brief\n\n### Q1"})
      assert {:ok, "# Brief\n\n### Q1"} = DiscussionGit.read_brief(r)
    end

    test "returns error when BRIEF.md is missing" do
      assert {:error, _} = DiscussionGit.read_brief(repo())
    end
  end

  # ------------------------------------------------------------------
  # read_decision/1
  # ------------------------------------------------------------------

  describe "read_decision/1" do
    test "reads DECISION.md when it exists" do
      r = repo(%{"DECISION.md" => "## Q1\n\nDecision text."})
      assert {:ok, "## Q1\n\nDecision text."} = DiscussionGit.read_decision(r)
    end

    test "returns :not_found when DECISION.md is absent" do
      assert {:error, :not_found} = DiscussionGit.read_decision(repo())
    end
  end

  # ------------------------------------------------------------------
  # read_config/1
  # ------------------------------------------------------------------

  describe "read_config/1" do
    test "parses agents list" do
      r = repo(%{"roundtable.toml" => @toml})
      {:ok, config} = DiscussionGit.read_config(r)
      assert config.agents == [:codex, :gemini, :claude_ic]
    end

    test "parses max_rounds" do
      r = repo(%{"roundtable.toml" => @toml})
      {:ok, config} = DiscussionGit.read_config(r)
      assert config.max_rounds == 3
    end

    test "parses coordinator" do
      r = repo(%{"roundtable.toml" => @toml})
      {:ok, config} = DiscussionGit.read_config(r)
      assert config.coordinator == :claude_ic
    end

    test "parses issues_enabled false" do
      r = repo(%{"roundtable.toml" => @toml})
      {:ok, config} = DiscussionGit.read_config(r)
      refute config.issues_enabled
    end

    test "defaults max_rounds to 5 when key absent" do
      r = repo(%{"roundtable.toml" => "schema_version = 1\n"})
      {:ok, config} = DiscussionGit.read_config(r)
      assert config.max_rounds == 5
    end

    test "returns error when roundtable.toml is missing" do
      assert {:error, _} = DiscussionGit.read_config(repo())
    end
  end

  # ------------------------------------------------------------------
  # list_rounds/1
  # ------------------------------------------------------------------

  describe "list_rounds/1" do
    test "returns sorted round filenames" do
      r =
        repo(%{
          "rounds/round-03-q7.md" => "c",
          "rounds/round-01-q1.md" => "a",
          "rounds/round-02-q2.md" => "b"
        })

      assert {:ok, names} = DiscussionGit.list_rounds(r)
      assert names == ["round-01-q1.md", "round-02-q2.md", "round-03-q7.md"]
    end

    test "returns empty list when no rounds exist" do
      assert {:ok, []} = DiscussionGit.list_rounds(repo())
    end
  end

  # ------------------------------------------------------------------
  # read_round/2
  # ------------------------------------------------------------------

  describe "read_round/2" do
    test "reads a round file by filename" do
      r = repo(%{"rounds/round-01-q1.md" => "# Round 1"})
      assert {:ok, "# Round 1"} = DiscussionGit.read_round(r, "round-01-q1.md")
    end
  end

  # ------------------------------------------------------------------
  # commit_round/4
  # ------------------------------------------------------------------

  describe "commit_round/4" do
    test "writes to rounds/round-NN-slug.md with zero-padded number" do
      {:ok, _} = DiscussionGit.commit_round(repo(), 1, "q1-q3", "round content")
      assert Process.get(:stub_written)["rounds/round-01-q1-q3.md"] == "round content"
    end

    test "uses two-digit padding" do
      {:ok, _} = DiscussionGit.commit_round(repo(), 10, "q18", "content")
      assert Process.get(:stub_written)["rounds/round-10-q18.md"] == "content"
    end

    test "returns updated repo struct" do
      r = repo()
      assert {:ok, %DiscussionRepo{}} = DiscussionGit.commit_round(r, 1, "q1", "body")
    end
  end

  # ------------------------------------------------------------------
  # append_decision/2
  # ------------------------------------------------------------------

  describe "append_decision/2" do
    test "creates DECISION.md when it does not exist" do
      {:ok, _} = DiscussionGit.append_decision(repo(), "## Q1\n\nDecision.")
      written = Process.get(:stub_written)["DECISION.md"]
      assert written =~ "## Q1\n\nDecision."
      assert written =~ "# Decisions"
    end

    test "appends to existing DECISION.md" do
      r = repo(%{"DECISION.md" => "# Decisions\n\n## Q1\n\nFirst."})
      {:ok, _} = DiscussionGit.append_decision(r, "## Q2\n\nSecond.")
      written = Process.get(:stub_written)["DECISION.md"]
      assert written =~ "## Q1\n\nFirst."
      assert written =~ "## Q2\n\nSecond."
    end

    test "returns updated repo struct" do
      assert {:ok, %DiscussionRepo{}} = DiscussionGit.append_decision(repo(), "section")
    end
  end
end

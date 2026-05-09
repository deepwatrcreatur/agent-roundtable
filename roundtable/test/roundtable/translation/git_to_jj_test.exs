defmodule Roundtable.Translation.GitToJjTest do
  use ExUnit.Case, async: true

  alias Roundtable.Translation.GitToJj

  describe "ref_to_bookmark/1" do
    test "maps branch refs into the git bookmark namespace" do
      assert {:ok, translation} = GitToJj.ref_to_bookmark("refs/heads/main")

      assert translation.git == %{kind: :branch_ref, ref: "refs/heads/main", branch: "main"}

      assert translation.jj == %{
               kind: :bookmark_projection,
               bookmark: "git/heads/main",
               writable: true
             }

      assert translation.provenance.lossy == false
    end

    test "maps tags as read-only projections" do
      assert {:ok, translation} = GitToJj.ref_to_bookmark("refs/tags/v1.0.0")
      assert translation.jj.bookmark == "git/tags/v1.0.0"
      assert translation.jj.writable == false
      assert Enum.any?(translation.provenance.notes, &String.contains?(&1, "read-only"))
    end

    test "rejects unsupported refs" do
      assert {:error, {:unsupported_git_ref, "refs/pull/42/head"}} =
               GitToJj.ref_to_bookmark("refs/pull/42/head")
    end
  end

  describe "bookmark_to_ref/1" do
    test "round-trips branch bookmark projections" do
      assert {:ok, translation} = GitToJj.bookmark_to_ref("git/heads/feature/auth")
      assert translation.git.ref == "refs/heads/feature/auth"
      assert translation.jj.bookmark == "git/heads/feature/auth"
    end

    test "rejects non-projection bookmarks" do
      assert {:error, {:unsupported_bookmark_projection, "consensus/q60"}} =
               GitToJj.bookmark_to_ref("consensus/q60")
    end
  end

  describe "commit_to_revset/1" do
    test "maps a git sha to an explicit jj revset selector" do
      assert {:ok, translation} = GitToJj.commit_to_revset("deadbeef")
      assert translation.jj.revset == ~s|commit_id("deadbeef")|
      assert Enum.any?(translation.provenance.notes, &String.contains?(&1, "revset selectors"))
    end

    test "rejects invalid commit ids" do
      assert {:error, {:invalid_commit_id, "not-a-sha"}} =
               GitToJj.commit_to_revset("not-a-sha")
    end
  end

  describe "pull_request_to_change/1" do
    test "projects a pull request into a jj change proposal envelope" do
      assert {:ok, translation} =
               GitToJj.pull_request_to_change(%{
                 number: 67,
                 head_ref: "feature/gateway",
                 base_ref: "main",
                 title: "Translation gateway",
                 state: :open
               })

      assert translation.git.kind == :pull_request
      assert translation.jj.change_key == "git/pr/67"
      assert translation.jj.head_bookmark == "git/pr/67/head"
      assert translation.jj.base_bookmark == "git/heads/main"
      assert translation.jj.source_branch_bookmark == "git/heads/feature/gateway"
      assert translation.jj.review_state == :open
      assert translation.provenance.lossy == false
    end
  end

  describe "merge_event_to_bookmark_move/1" do
    test "keeps non-squash merges non-lossy" do
      assert {:ok, translation} =
               GitToJj.merge_event_to_bookmark_move(%{
                 base_ref: "main",
                 merged_commit_sha: "abc1234",
                 strategy: :merge,
                 pull_request_number: 67
               })

      assert translation.jj.bookmark == "git/heads/main"
      assert translation.jj.target_revset == ~s|commit_id("abc1234")|
      assert translation.provenance.lossy == false
    end

    test "surfaces squash merges as lossy" do
      assert {:ok, translation} =
               GitToJj.merge_event_to_bookmark_move(%{
                 base_ref: "main",
                 merged_commit_sha: "abc1234",
                 strategy: :squash
               })

      assert translation.provenance.lossy == true

      assert Enum.any?(
               translation.provenance.notes,
               &String.contains?(&1, "Squash merges are lossy")
             )
    end

    test "surfaces rebase merges as lossy" do
      assert {:ok, translation} =
               GitToJj.merge_event_to_bookmark_move(%{
                 base_ref: "main",
                 merged_commit_sha: "abc1234",
                 strategy: :rebase
               })

      assert translation.provenance.lossy == true

      assert Enum.any?(
               translation.provenance.notes,
               &String.contains?(&1, "Rebase merges are lossy")
             )
    end
  end
end

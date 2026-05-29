defmodule Roundtable.Prompt.TagPrunerTest do
  use ExUnit.Case, async: true

  alias Roundtable.Prompt.TagPruner

  describe "infer_tags_from_content/2" do
    test "extracts explicit #hashtag patterns" do
      text = "This is about #networking and #security concerns"
      assert tags = TagPruner.infer_tags_from_content(text)
      assert "networking" in tags
      assert "security" in tags
    end

    test "ignores uppercase and special characters" do
      text = "Check #valid-tag but not #123invalid"
      tags = TagPruner.infer_tags_from_content(text)
      assert "valid-tag" in tags
      refute "123invalid" in tags
    end

    test "returns empty list for nil input" do
      assert [] == TagPruner.infer_tags_from_content(nil)
    end

    test "deduplicates tags" do
      text = "#networking and again #networking"
      tags = TagPruner.infer_tags_from_content(text)
      assert length(Enum.filter(tags, &(&1 == "networking"))) == 1
    end
  end

  describe "prune_by_tags/3" do
    test "falls back to full context when Dolt is unavailable" do
      turns = [
        %{author: "alice", body: "First point about networking", tags: ["networking"]},
        %{author: "bob", body: "Second point about security", tags: ["security"]},
        %{author: "carol", body: "Third about licensing", tags: ["license"]}
      ]

      {text, stats} = TagPruner.prune_by_tags("issue-1", turns, repo_path: "/nonexistent")

      assert stats.total_turns == 3
      assert stats.kept_turns == 3
      assert stats.savings_pct == 0.0
      assert String.contains?(text, "alice")
      assert String.contains?(text, "bob")
      assert String.contains?(text, "carol")
    end

    test "formats turns with author and body" do
      turns = [
        %{author: "alice", body: "Hello world", tags: []},
        %{body: "No author turn", tags: []}
      ]

      {text, _stats} = TagPruner.prune_by_tags("issue-1", turns, repo_path: "/nonexistent")

      assert String.contains?(text, "**alice**:")
      assert String.contains?(text, "Hello world")
      assert String.contains?(text, "No author turn")
    end

    test "formats plain string turns" do
      turns = ["plain text turn"]

      {text, _stats} = TagPruner.prune_by_tags("issue-1", turns, repo_path: "/nonexistent")

      assert String.contains?(text, "plain text turn")
    end
  end
end

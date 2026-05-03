defmodule Roundtable.PromptTest do
  use ExUnit.Case, async: true

  alias Roundtable.Prompt

  @brief "Test brief content"
  @issue %{
    "title" => "Test question",
    "url" => "https://github.com/owner/repo/issues/1",
    "comments" => []
  }
  @role "You are Codex."

  describe "build/4" do
    test "produces a well-formed turn prompt (default)" do
      prompt = Prompt.build(@brief, @issue, @role)

      assert String.contains?(prompt, "### Your Role\nYou are Codex.")
      assert String.contains?(prompt, "=== BRIEF ===\nTest brief content")
      assert String.contains?(prompt, "=== QUESTION ===\nTitle: Test question")
      assert String.contains?(prompt, "=== DISCUSSION SO FAR ===\n(No comments yet)")
      assert String.contains?(prompt, "=== YOUR TASK ===\nResearch the question")
    end

    test "produces a fuller join prompt when :join is true" do
      prompt = Prompt.build(@brief, @issue, @role, join: true)

      assert String.contains?(prompt, "You are joining an ongoing multi-agent roundtable discussion.")
      assert String.contains?(prompt, "Do not post to GitHub directly")
    end

    test "caps comments for turn and join prompts" do
      comments = Enum.map(1..15, fn i ->
        %{"author" => %{"login" => "agent"}, "body" => "comment #{i}", "createdAt" => "now"}
      end)
      issue = Map.put(@issue, "comments", comments)

      # Turn: caps at 10
      turn_prompt = Prompt.build(@brief, issue, @role)
      assert String.contains?(turn_prompt, "## agent at now\ncomment 6")
      refute String.contains?(turn_prompt, "comment 5")

      # Join: caps at 5
      join_prompt = Prompt.build(@brief, issue, @role, join: true)
      assert String.contains?(join_prompt, "## agent at now\ncomment 11")
      refute String.contains?(join_prompt, "comment 10")
    end

    test "adjusts task instruction for Incident Commander" do
      ic_role = "You are the Incident Commander (IC)."
      prompt = Prompt.build(@brief, @issue, ic_role)

      assert String.contains?(prompt, "Synthesise the positions above")
    end
  end
end

defmodule Roundtable.Actions.GhTest do
  use ExUnit.Case, async: true

  alias Roundtable.Actions.Gh
  alias Roundtable.TestSupport.FakeRunner

  setup do
    Process.put(:runner_result, {"", 0})
    Process.put(:test_pid, self())
    :ok
  end

  test "view_issue builds gh issue view command with json fields and comments" do
    Process.put(
      :runner_result,
      {~s({"title":"Q1","state":"OPEN","labels":[],"comments":[],"body":"","url":"u"}), 0}
    )

    assert {:ok, %{"title" => "Q1", "state" => "OPEN"}} =
             Gh.view_issue(12, [], %{repo: "owner/repo", runner: FakeRunner})

    assert_received {:cmd, "gh",
                     [
                       "issue",
                       "view",
                       "12",
                       "-R",
                       "owner/repo",
                       "--comments",
                       "--json",
                       "title,body,labels,state,comments,url"
                     ],
                     [stderr_to_stdout: true]}
  end

  test "comment_issue writes the comment to a temporary body file" do
    assert :ok = Gh.comment_issue(7, "Signed position", %{runner: FakeRunner})

    assert_received {:cmd, "gh", ["issue", "comment", "7", "--body-file", body_file],
                     [stderr_to_stdout: true]}

    assert String.starts_with?(body_file, System.tmp_dir!())
    refute body_file == "-"
  end

  test "edit_issue_labels includes add and remove label flags" do
    assert :ok =
             Gh.edit_issue_labels(
               4,
               ["satisfied", "triaged"],
               ["needs-more-evidence"],
               %{repo: "owner/repo", runner: FakeRunner}
             )

    assert_received {:cmd, "gh",
                     [
                       "issue",
                       "edit",
                       "4",
                       "-R",
                       "owner/repo",
                       "--add-label",
                       "satisfied,triaged",
                       "--remove-label",
                       "needs-more-evidence"
                     ], [stderr_to_stdout: true]}
  end

  test "close_issue includes reason and optional closing comment" do
    assert :ok =
             Gh.close_issue(
               9,
               [reason: "completed", comment: "Consensus reached"],
               %{runner: FakeRunner}
             )

    assert_received {:cmd, "gh",
                     [
                       "issue",
                       "close",
                       "9",
                       "-r",
                       "completed",
                       "-c",
                       "Consensus reached"
                     ], [stderr_to_stdout: true]}
  end

  test "returns a command_failed error on non-zero exit" do
    Process.put(:runner_result, {"bad token", 1})

    assert {:error, {:command_failed, 1, "bad token"}} =
             Gh.view_issue(1, [], %{runner: FakeRunner})
  end

  test "returns an invalid_json error when gh output cannot be decoded" do
    Process.put(:runner_result, {"not-json", 0})

    assert {:error, {:invalid_json, _reason}} =
             Gh.view_issue(1, [], %{runner: FakeRunner})
  end
end

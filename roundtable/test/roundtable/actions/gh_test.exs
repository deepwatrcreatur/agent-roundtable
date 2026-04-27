defmodule Roundtable.Actions.GhTest do
  use ExUnit.Case, async: true
  alias Roundtable.Actions.Gh

  # Fake runner that stores its calls in a process mailbox
  defmodule FakeRunner do
    def cmd(bin, args, opts) do
      # Fetch the pre-configured result from the process dictionary
      result = Process.get(:runner_result) || {"", 0}
      # Send the call back to the test process for assertion
      send(Process.get(:test_pid), {:cmd, bin, args, opts})
      result
    end
  end

  setup do
    Process.put(:test_pid, self())
    Application.put_env(:roundtable, :gh_runner, FakeRunner)
    :ok
  end

  test "view_issue builds the correct gh command" do
    json = ~s({"title": "Q1", "body": "...", "labels": [], "state": "OPEN", "comments": [], "url": "..."})
    Process.put(:runner_result, {json, 0})

    assert {:ok, %{"title" => "Q1"}} = Gh.view_issue("owner/repo", 1)

    assert_received {:cmd, "gh", ["issue", "view", "1", "-R", "owner/repo", "--json", "title,body,labels,state,comments,url"], [stderr_to_stdout: true]}
  end

  test "list_issues builds the correct gh command" do
    json = ~s([{"number": 1, "title": "Q1", "state": "OPEN"}])
    Process.put(:runner_result, {json, 0})

    assert {:ok, [%{"number" => 1}]} = Gh.list_issues("owner/repo", "satisfied")

    assert_received {:cmd, "gh", ["issue", "list", "-R", "owner/repo", "--label", "satisfied", "--json", "number,title,state"], [stderr_to_stdout: true]}
  end

  test "post_comment sends body over stdin" do
    Process.put(:runner_result, {"", 0})

    assert :ok = Gh.post_comment("owner/repo", 1, "My comment")

    assert_received {:cmd, "gh", ["issue", "comment", "1", "-R", "owner/repo", "--body-file", "-"], [input: "My comment", stderr_to_stdout: true]}
  end

  test "set_labels handles add and remove" do
    Process.put(:runner_result, {"", 0})

    assert :ok = Gh.set_labels("owner/repo", 1, add: ["a", "b"], remove: ["c"])

    assert_received {:cmd, "gh", ["issue", "edit", "1", "-R", "owner/repo", "--add-label", "a,b", "--remove-label", "c"], [stderr_to_stdout: true]}
  end

  test "close_issue builds the correct gh command" do
    Process.put(:runner_result, {"", 0})

    assert :ok = Gh.close_issue("owner/repo", 1, "Closing now")

    assert_received {:cmd, "gh", ["issue", "close", "1", "-R", "owner/repo", "-c", "Closing now"], [stderr_to_stdout: true]}
  end

  test "create_issue returns the issue url" do
    url = "https://github.com/owner/repo/issues/10"
    Process.put(:runner_result, {url <> "\n", 0})

    assert {:ok, ^url} = Gh.create_issue("owner/repo", "T", "B", ["l1"])

    assert_received {:cmd, "gh", ["issue", "create", "-R", "owner/repo", "-t", "T", "-b", "B", "-l", "l1"], [stderr_to_stdout: true]}
  end

  test "auth_status returns ok on 0 exit" do
    Process.put(:runner_result, {"logged in", 0})
    assert :ok = Gh.auth_status()
  end

  test "returns error on non-zero exit" do
    Process.put(:runner_result, {"failed", 1})
    assert {:error, {:command_failed, 1, "failed"}} = Gh.auth_status()
  end

  test "returns error on invalid json" do
    Process.put(:runner_result, {"not json", 0})
    assert {:error, {:invalid_json, _}} = Gh.view_issue("r", 1)
  end

  test "returns error on network timeout/failure" do
    error_msg = "error connecting to github.com: timeout"
    Process.put(:runner_result, {error_msg, 1})

    assert {:error, {:command_failed, 1, ^error_msg}} = Gh.view_issue("r", 1)
  end
end

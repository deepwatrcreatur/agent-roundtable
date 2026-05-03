defmodule Roundtable.Actions.RunCliAgentTest do
  use ExUnit.Case, async: true

  alias Roundtable.Actions.RunCliAgent
  alias Roundtable.TestSupport.FakeRunner

  setup do
    Process.put(:test_pid, self())
    :ok
  end

  describe "run/2" do
    test "invokes claude CLI correctly" do
      Process.put(:runner_result, {"{\"result\": \"ok\"}", 0})

      params = %{
        agent: :claude,
        prompt: "hi",
        repo_root: "/tmp",
        runner: FakeRunner
      }

      assert {:ok, %{stdout: "{\"result\": \"ok\"}"}} = RunCliAgent.run(params, %{})

      assert_received {:cmd, "claude", ["-p", "--output-format", "json", "hi"],
                       [cd: "/tmp", stderr_to_stdout: true]}
    end

    test "invokes gemini CLI correctly" do
      Process.put(:runner_result, {"{\"response\": \"ok\"}", 0})

      params = %{
        agent: :gemini,
        prompt: "hi",
        repo_root: "/tmp",
        runner: FakeRunner
      }

      assert {:ok, %{stdout: "{\"response\": \"ok\"}"}} = RunCliAgent.run(params, %{})

      assert_received {:cmd, "gemini", ["-p", "hi", "--output-format", "json"],
                       [cd: "/tmp", stderr_to_stdout: true]}
    end

    test "invokes codex CLI correctly with temp file" do
      Process.put(:runner_result, {"{\"type\": \"turn.completed\"}", 0})

      params = %{
        agent: :codex,
        prompt: "hi",
        repo_root: "/tmp",
        runner: FakeRunner
      }

      assert {:ok, %{stdout: "{\"type\": \"turn.completed\"}"}} = RunCliAgent.run(params, %{})

      assert_received {:cmd, "codex", ["exec", tmp_path, "--json"],
                       [cd: "/tmp", stderr_to_stdout: true]}

      assert String.contains?(tmp_path, "rt_prompt_")
      # Temp file should be deleted after run
      refute File.exists?(tmp_path)
    end

    test "returns error on non-zero exit code" do
      Process.put(:runner_result, {"error message", 1})

      params = %{
        agent: :claude,
        prompt: "hi",
        repo_root: "/tmp",
        runner: FakeRunner
      }

      assert {:error, {:command_failed, 1, "error message"}} = RunCliAgent.run(params, %{})
    end
  end
end

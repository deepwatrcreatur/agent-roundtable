defmodule Roundtable.Actions.RunCliAgentTest.MockDeepSeekRunner do
  def cmd(cmd, args, _opts) do
    send(self(), {:cmd_called, cmd, args})
    {"Mock DeepSeek harness output\n", 0}
  end
end

defmodule Roundtable.Actions.RunCliAgentTest do
  use ExUnit.Case, async: true

  alias Roundtable.Actions.RunCliAgent
  alias Roundtable.Actions.RunCliAgentTest.MockDeepSeekRunner

  describe "validate_agent/1" do
    test "deepseek fails fast when api key is missing" do
      previous = System.get_env("DEEPSEEK_API_KEY")
      System.delete_env("DEEPSEEK_API_KEY")

      on_exit(fn ->
        if previous do
          System.put_env("DEEPSEEK_API_KEY", previous)
        else
          System.delete_env("DEEPSEEK_API_KEY")
        end
      end)

      assert {:error, {:agent_prereq_missing, :deepseek, :deepseek_api_key_missing}} =
               RunCliAgent.validate_agent(:deepseek)
    end

    test "unsupported agents are rejected explicitly" do
      assert {:error, {:unsupported_agent, :copilot}} =
               RunCliAgent.validate_agent(:copilot)
    end
  end

  describe "validate_agents/1" do
    test "rejects duplicate agents" do
      assert {:error, {:duplicate_agents, [:gemini]}} =
               RunCliAgent.validate_agents([:codex, :gemini, :gemini])
    end

    test "rejects unsupported agents in the roster" do
      assert {:error, {:unsupported_agents, [:copilot]}} =
               RunCliAgent.validate_agents([:codex, :copilot])
    end
  end

  describe "run/2 with harness CLI" do
    test "invokes dsh headless profile when harness is :cli" do
      previous = System.get_env("DEEPSEEK_API_KEY")
      System.put_env("DEEPSEEK_API_KEY", "test-key")

      on_exit(fn ->
        if previous do
          System.put_env("DEEPSEEK_API_KEY", previous)
        else
          System.delete_env("DEEPSEEK_API_KEY")
        end
      end)

      assert {:ok, %{stdout: "Mock DeepSeek harness output\n"}} =
               RunCliAgent.run(
                 %{
                   agent: :deepseek,
                   prompt: "Test prompt",
                   repo_root: System.tmp_dir!(),
                   harness: :cli,
                   cli_path: "dsh",
                   runner: MockDeepSeekRunner
                 },
                 %{}
               )

      assert_receive {:cmd_called, "dsh", ["--profile", "headless", "Test prompt"]}
    end
  end
end

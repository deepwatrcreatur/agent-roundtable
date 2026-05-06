defmodule Roundtable.Actions.RunCliAgentTest do
  use ExUnit.Case, async: true

  alias Roundtable.Actions.RunCliAgent

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
end

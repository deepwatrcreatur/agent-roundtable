defmodule Roundtable.EvalTest do
  use ExUnit.Case, async: true

  alias Roundtable.Eval
  alias Roundtable.TestSupport.FakeRunner

  setup do
    Process.put(:test_pid, self())
    :ok
  end

  describe "run_vaglio/3" do
    test "runs a full round with multiple agents and accumulates metrics" do
      # Mock gemini output
      gemini_json = JSON.encode!(%{
        "response" => "Gemini response",
        "stats" => %{
          "models" => %{
            "gemini-2.0" => %{
              "tokens" => %{"total" => 1000, "input" => 800, "candidates" => 200}
            }
          }
        }
      })

      # Mock claude output
      claude_json = JSON.encode!(%{
        "result" => "Claude synthesis",
        "usage" => %{"input_tokens" => 500, "output_tokens" => 500},
        "total_cost_usd" => 0.05
      })

      results = [
        {gemini_json, 0},
        {claude_json, 0}
      ]

      Process.put(:runner_result, fn ->
        res = Process.get(:test_results, results)
        {head, tail} = {List.first(res), List.delete_at(res, 0)}
        Process.put(:test_results, tail)
        head
      end)
      Process.put(:test_results, results)

      {:ok, run} = Eval.run_vaglio("Test question", "Test context",
        agents: [:gemini, :claude_ic],
        runner: FakeRunner
      )

      assert run.mode == :vaglio
      assert length(run.turns) == 2
      assert run.final_output == "Claude synthesis"

      # Verify metrics
      # Gemini: 1000 tokens. Cost: 800/1000 * 0.0001 + 200/1000 * 0.0003 = 0.00008 + 0.00006 = 0.00014
      # Claude: 1000 tokens. Cost: 0.05 (from JSON)
      assert run.tokens_used == 2000
      assert_in_delta run.cost_usd, 0.05014, 0.000001
    end
  end

  describe "run_single/4" do
    test "runs a single model and captures metrics" do
      claude_json = JSON.encode!(%{
        "result" => "Single response",
        "usage" => %{"input_tokens" => 100, "output_tokens" => 50},
        "total_cost_usd" => 0.001
      })

      Process.put(:runner_result, {claude_json, 0})

      {:ok, run} = Eval.run_single("Test question", "Test context", :naive,
        model: :claude,
        runner: FakeRunner
      )

      assert run.mode == :single_naive
      assert run.model == :claude
      assert run.final_output == "Single response"
      assert run.tokens_used == 150
      assert run.cost_usd == 0.001
    end
  end

  describe "extract_usage/2" do
    # Testing private function via public API (indirectly) or just trusting the logic
    # covered in the tests above.
  end
end

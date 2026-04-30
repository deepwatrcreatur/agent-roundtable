defmodule Roundtable.Eval.MetricsTest do
  use ExUnit.Case, async: true

  alias Roundtable.Eval.{Metrics, Run}

  describe "compute/2" do
    test "populates metrics from judge responses" do
      run = %Run{
        id: "eval-1",
        question: "Should we persist state?",
        brief_context: "brief",
        mode: :single_structured,
        final_output: "Persist state. Add retries.",
        tokens_used: 123,
        cost_usd: 0.42
      }

      invoke = fn prompt ->
        cond do
          prompt =~ "Extract every distinct consideration" ->
            {:ok,
             ~s([{"claim":"Persist state","provenance":"observed"},{"claim":"Add retries","provenance":"inferred"}])}

          prompt =~ "identify any internal contradictions" ->
            {:ok, ~s({"consistent":true,"contradictions":[]})}

          prompt =~ "Count the number of explicit disagreements" ->
            {:ok, ~s({"dissent_count":1,"examples":["retry policy disagreement"]})}
        end
      end

      assert {:ok, computed} = Metrics.compute(run, invoke: invoke)

      assert computed.metrics == %{
               consideration_count: 2,
               unique_considerations: 2,
               self_consistent: true,
               contradiction_count: 0,
               dissent_count: 1,
               diversity_ratio: nil,
               tokens_used: 123,
               cost_usd: 0.42
             }
    end
  end

  describe "compute/2 diversity ratio" do
    test "computes diversity ratio for vaglio runs from per-agent turns" do
      run = %Run{
        id: "eval-v",
        question: "q",
        brief_context: "b",
        mode: :vaglio,
        final_output: "final",
        turns: [
          %{agent: "codex", output: "Persist state in ETS. Add retries for takeover."},
          %{agent: "gemini", output: "Persist state in ETS. Expose metrics in the dashboard."},
          %{agent: "claude_ic", output: "Add retries for takeover. Expose metrics in the dashboard."}
        ]
      }

      invoke = fn prompt ->
        cond do
          prompt =~ "Extract every distinct consideration" ->
            {:ok, ~s([{"claim":"Persist state in ETS","provenance":"observed"}])}

          prompt =~ "identify any internal contradictions" ->
            {:ok, ~s({"consistent":true,"contradictions":[]})}

          prompt =~ "Count the number of explicit disagreements" ->
            {:ok, ~s({"dissent_count":0,"examples":[]})}
        end
      end

      assert {:ok, computed} = Metrics.compute(run, invoke: invoke)
      assert is_float(computed.metrics.diversity_ratio)
      assert computed.metrics.diversity_ratio == 0.5
    end
  end

  describe "compare/1" do
    test "computes consideration and cost ratios against the first baseline" do
      vaglio = %Run{mode: :vaglio, metrics: %{consideration_count: 6, cost_usd: 1.2}}
      single = %Run{mode: :single_structured, metrics: %{consideration_count: 3, cost_usd: 0.4}}

      result = Metrics.compare([vaglio, single])

      assert result[:comparison] == %{consideration_ratio: 2.0, cost_ratio: 3.0}
    end
  end
end

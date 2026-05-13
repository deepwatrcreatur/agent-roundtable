defmodule Roundtable.RobustnessMetricsTest do
  use ExUnit.Case, async: true

  alias Roundtable.RobustnessMetrics

  test "marks multi-round challenged consensus as deep green" do
    questions = %{
      42 => %{
        title: "Q42 — Debate the rollout",
        state: :closed,
        comments: [
          %{
            "body" =>
              "## Codex\n\nThis assumption is weak.\n\n[needs more evidence: rollout data]"
          },
          %{
            "body" =>
              "## Gemini\n\nWe can support it with guardrails.\n\n[satisfied-conditional: after a canary]"
          },
          %{"body" => "## Claude IC\n\nThe revised shape works.\n\n[satisfied]"}
        ]
      }
    }

    decision = """
    # Decisions

    ## Q42 (Round 2, 2026-05-09)

    Consensus reached after 2 round(s).
    """

    assert %{42 => meter} = RobustnessMetrics.compute(questions, decision)
    assert meter.round_count == 2
    assert meter.objection_count == 1
    assert meter.satisfied_count == 2
    assert meter.state == :deep_green
    assert meter.robustness_score > 0.65
  end

  test "marks first-round satisfied closure as pale green" do
    questions = %{
      7 => %{
        title: "Q7 — Straightforward choice",
        state: :closed,
        comments: [
          %{"body" => "## Codex\n\nLooks good.\n\n[satisfied]"},
          %{"body" => "## Gemini\n\nAgree.\n\n[satisfied]"}
        ]
      }
    }

    assert %{7 => meter} = RobustnessMetrics.compute(questions, "")
    assert meter.round_count == 1
    assert meter.state == :pale_green
    assert meter.objection_count == 0
  end

  test "marks no-objection exhaustion as yellow" do
    questions = %{
      11 => %{
        title: "Q11 — Quiet closure",
        state: :closed,
        comments: [
          %{"body" => "## Codex\n\nI have nothing else.\n\n[no objection]"},
          %{"body" => "## Gemini\n\nNo further pushback.\n\n[no objection]"}
        ]
      }
    }

    assert %{11 => meter} = RobustnessMetrics.compute(questions, "")
    assert meter.no_objection_count == 2
    assert meter.state == :yellow
    assert meter.robustness_score < 0.3
  end

  test "estimates active rounds from turn count before a decision exists" do
    questions = %{
      99 => %{
        title: "Q99 — Open question",
        state: :open,
        comments: [
          %{"body" => "## Codex\n\nInitial push.\n\n[needs more evidence: benchmark]"},
          %{
            "body" => "## Gemini\n\nCounterproposal.\n\n[satisfied-conditional: after benchmark]"
          },
          %{"body" => "## Codex\n\nFollow-up.\n\n[satisfied]"},
          %{"body" => "## Gemini\n\nAccepted.\n\n[satisfied]"}
        ]
      }
    }

    assert %{99 => meter} = RobustnessMetrics.compute(questions, "")
    assert meter.round_count == 2
    assert meter.state == :active
  end

  test "sorts low robustness history from weakest closed decisions first" do
    questions = %{
      1 => %{title: "Q1", state: :closed, comments: [%{"body" => "## Codex\n\n[satisfied]"}]},
      2 => %{title: "Q2", state: :closed, comments: [%{"body" => "## Codex\n\n[no objection]"}]},
      3 => %{title: "Q3", state: :open, comments: []}
    }

    meters = RobustnessMetrics.compute(questions, "")

    assert [{2, _q2, weakest}, {1, _q1, _stronger}] =
             RobustnessMetrics.low_robustness_history(questions, meters, 2)

    assert weakest.state == :yellow
  end
end

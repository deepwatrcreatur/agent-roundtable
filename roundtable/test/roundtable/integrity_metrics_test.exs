defmodule Roundtable.IntegrityMetricsTest do
  use ExUnit.Case, async: true

  alias Roundtable.IntegrityMetrics

  test "computes metrics for completed questions from brief, transcript, and decisions" do
    questions = %{
      41 => %{
        title: "Q41 — Should we trust the initial plan?",
        state: :closed,
        comments: [
          %{"body" => "## Codex\n\nThis assumption looks weak.\n\n[needs more evidence: deployment data]"},
          %{"body" => "## Gemini\n\nWe should rename the design around provenance and integrity.\n\n[satisfied]"}
        ]
      }
    }

    brief = """
    # Brief

    ### Q41 — Should we trust the initial plan?

    Assume the original plan is already correct and only needs implementation.
    """

    decision = """
    # Decisions

    ## Q41 (Round 2, 2026-05-09)

    Consensus reached after 2 round(s).

    ### Satisfaction summary

    The council reframed the work around provenance, integrity, and explicit challenge of assumptions.
    """

    assert %{41 => scorecard} = IntegrityMetrics.compute(questions, brief, decision)
    assert scorecard.premise_challenge_rate > 0.0
    assert scorecard.vocabulary_innovation > 0.0
    assert scorecard.divergence_delta > 0.0
    assert scorecard.total_turn_count == 2
    assert scorecard.challenge_turn_count == 1
    assert scorecard.integrity_score > 0.0
  end

  test "ignores open questions and handles empty source text" do
    questions = %{
      1 => %{title: "Q1 — Open question", state: :open, comments: []},
      2 => %{title: "Q2 — Closed question", state: :closed, comments: []}
    }

    assert %{2 => scorecard} = IntegrityMetrics.compute(questions, "", "")
    refute Map.has_key?(IntegrityMetrics.compute(questions, "", ""), 1)
    assert scorecard.integrity_score == 0.0
    assert scorecard.sycophancy_warning
  end

  test "treats challenge language as premise pressure even without explicit marker" do
    questions = %{
      7 => %{
        title: "Q7 — Network defaults",
        state: :closed,
        comments: [
          %{"body" => "## Claude IC\n\nWe should challenge the assumption that the fallback is safe."}
        ]
      }
    }

    assert %{7 => scorecard} =
             IntegrityMetrics.compute(
               questions,
               "### Q7 — Network defaults\n\nUse the current fallback.",
               "## Q7\n\nDecision text."
             )

    assert scorecard.premise_challenge_rate == 1.0
  end
end

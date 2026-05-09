defmodule Roundtable.RedTeamHighlightsTest do
  use ExUnit.Case, async: true

  alias Roundtable.RedTeamHighlights

  test "flags skeptical turns and premise collisions from observed evidence" do
    questions = %{
      43 => %{
        title: "Q43 — Should we trust the initial benchmark?",
        state: :closed,
        comments: [
          %{
            "body" =>
              "## Codex\n\nThe assumption does not hold. [observed: benchmark failed under load]\n\n[needs more evidence: wider sample]"
          },
          %{"body" => "## Gemini\n\nThe revised plan seems acceptable.\n\n[satisfied]"}
        ]
      }
    }

    brief = """
    ### Q43 — Should we trust the initial benchmark?

    The benchmark is stable under load and safe to reuse as-is.
    """

    assert %{43 => view} = RedTeamHighlights.build(questions, brief)
    assert view.hard_truth_count == 1
    assert view.premise_collision_count == 1

    [skeptic_turn] = view.red_team_turns
    assert skeptic_turn.disconfirmation_pass?
    assert skeptic_turn.premise_collision?
    assert skeptic_turn.agent_name == "Codex"
    assert skeptic_turn.observed_evidence == ["benchmark failed under load"]
  end

  test "keeps satisfied turns out of red team highlights" do
    questions = %{
      1 => %{
        title: "Q1 — Happy path",
        state: :closed,
        comments: [
          %{"body" => "## Gemini\n\nLooks good.\n\n[satisfied]"}
        ]
      }
    }

    assert %{1 => view} = RedTeamHighlights.build(questions, "")
    assert view.hard_truth_count == 0
    assert view.red_team_turns == []
  end
end

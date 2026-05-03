defmodule Roundtable.SatisfactionTest do
  use ExUnit.Case, async: true
  alias Roundtable.Satisfaction

  describe "parse/1" do
    test "correctly parses [satisfied]" do
      assert Satisfaction.parse("I agree. [satisfied]") == {:satisfied, nil}
      assert Satisfaction.parse("[SATISFIED] with extra space") == {:satisfied, nil}
    end

    test "correctly parses [satisfied-conditional: ...]" do
      assert Satisfaction.parse("[satisfied-conditional: if we add tests]") == {:satisfied_conditional, "if we add tests"}
      assert Satisfaction.parse("[SATISFIED - CONDITIONAL: fix lint]") == {:satisfied_conditional, "fix lint"}
    end

    test "correctly parses [no objection]" do
      assert Satisfaction.parse("I've said my piece. [no objection]") == {:no_objection, nil}
      assert Satisfaction.parse("[NO OBJECTION]") == {:no_objection, nil}
    end

    test "correctly parses [needs more evidence: ...]" do
      assert Satisfaction.parse("[needs more evidence: missing benchmark]") == {:needs_more_evidence, "missing benchmark"}
      assert Satisfaction.parse("[NEEDS MORE EVIDENCE: security audit]") == {:needs_more_evidence, "security audit"}
    end

    test "returns {:unknown, text} when no marker is found" do
      text = "This is just prose without a marker."
      assert Satisfaction.parse(text) == {:unknown, text}
    end

    test "most conservative marker wins when multiple are present" do
      # needs_more_evidence > satisfied_conditional > no_objection > satisfied
      text = "[satisfied] [needs more evidence: everything]"
      assert Satisfaction.parse(text) == {:needs_more_evidence, "everything"}

      text = "[satisfied] [satisfied-conditional: only if]"
      assert Satisfaction.parse(text) == {:satisfied_conditional, "only if"}

      text = "[satisfied] [no objection]"
      assert Satisfaction.parse(text) == {:no_objection, nil}
    end
  end

  describe "question_state/2" do
    test "returns :all_satisfied when all are satisfied" do
      responses = ["[satisfied]", "[satisfied]"]
      assert Satisfaction.question_state(responses) == :all_satisfied
    end

    test "returns :satisfied_conditional if any are conditional (and none blocking)" do
      responses = ["[satisfied]", "[satisfied-conditional: maybe]"]
      assert Satisfaction.question_state(responses) == :satisfied_conditional

      responses = ["[no objection]", "[satisfied-conditional: maybe]"]
      assert Satisfaction.question_state(responses) == :satisfied_conditional
    end

    test "returns :needs_more_evidence if any agent is blocking" do
      responses = ["[satisfied]", "[needs more evidence: why]"]
      assert Satisfaction.question_state(responses) == :needs_more_evidence

      responses = ["[satisfied-conditional: x]", "[needs more evidence: why]"]
      assert Satisfaction.question_state(responses) == :needs_more_evidence
    end

    test "returns :needs_ic_triage if any agent response is unknown" do
      responses = ["[satisfied]", "prose without marker"]
      assert Satisfaction.question_state(responses) == :needs_ic_triage
    end

    test "returns :max_rounds_reached when passed in opts" do
      assert Satisfaction.question_state([], max_rounds_reached: true) == :max_rounds_reached
    end

    test "returns :needs_more_evidence if only [no objection] responses exist (no positive satisfaction)" do
      responses = ["[no objection]", "[no objection]"]
      assert Satisfaction.question_state(responses) == :needs_more_evidence
    end

    test "returns :all_satisfied if mixed [satisfied] and [no objection]" do
      responses = ["[satisfied]", "[no objection]"]
      assert Satisfaction.question_state(responses) == :all_satisfied
    end
  end

  describe "label_changes/1" do
    test "correctly maps :all_satisfied" do
      assert Satisfaction.label_changes(:all_satisfied) == %{
               add: ["satisfied"],
               remove: ["needs-more-evidence", "satisfied-conditional", "no-objection", "needs-ic-triage"]
             }
    end

    test "correctly maps :satisfied_conditional" do
      assert Satisfaction.label_changes(:satisfied_conditional) == %{
               add: ["satisfied-conditional"],
               remove: ["needs-more-evidence", "no-objection", "needs-ic-triage"]
             }
    end

    test "correctly maps :needs_more_evidence" do
      assert Satisfaction.label_changes(:needs_more_evidence) == %{
               add: ["needs-more-evidence"],
               remove: ["satisfied", "satisfied-conditional", "no-objection", "needs-ic-triage"]
             }
    end

    test "correctly maps :needs_ic_triage" do
      assert Satisfaction.label_changes(:needs_ic_triage) == %{
               add: ["needs-ic-triage"],
               remove: []
             }
    end

    test "correctly maps :max_rounds_reached" do
      assert Satisfaction.label_changes(:max_rounds_reached) == %{
               add: ["needs-human-review"],
               remove: []
             }
    end
  end
end

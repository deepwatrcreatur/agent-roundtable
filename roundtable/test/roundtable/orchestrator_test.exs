defmodule Roundtable.OrchestratorTest do
  use ExUnit.Case, async: true

  alias Roundtable.{Orchestrator, RoundRun}

  # ------------------------------------------------------------------
  # Fixtures
  # ------------------------------------------------------------------

  defp run(attrs \\ []) do
    base = RoundRun.new(1001, [:codex, :gemini, :claude_ic])
    struct!(base, attrs)
  end

  defp issue(extras \\ []) do
    Map.new([{"comments", []}, {"state", "open"}, {"labels", []}] ++ extras)
  end

  defp comment(agent_header, body_suffix) do
    %{"id" => "c#{System.unique_integer()}", "body" => "#{agent_header}\n\n#{body_suffix}"}
  end

  # ------------------------------------------------------------------
  # :awaiting_turns
  # ------------------------------------------------------------------

  describe "step/3 :awaiting_turns" do
    test "emits {:run_agent} for the first pending speaker" do
      r = run()
      {next_run, effects} = Orchestrator.step(r, issue(), [])

      assert next_run.phase == :awaiting_turns
      assert [{:run_agent, :codex, 1001}] = effects
    end

    test "emits next pending speaker when first has already spoken" do
      r = run(completed_speakers: [:codex])
      {_next_run, effects} = Orchestrator.step(r, issue(), [])

      assert [{:run_agent, :gemini, 1001}] = effects
    end

    test "transitions to :triage_missing_markers when all speakers done" do
      r = run(completed_speakers: [:codex, :gemini, :claude_ic], retry_count: 0)
      {next_run, effects} = Orchestrator.step(r, issue(), [])

      assert next_run.phase == :triage_missing_markers
      assert next_run.retry_count == 1
      assert [{:notify, {:round_complete, 1001}}] = effects
    end

    test "transitions to :needs_human_review when all done and max_rounds reached" do
      r = run(completed_speakers: [:codex, :gemini, :claude_ic], retry_count: 3)
      {next_run, effects} = Orchestrator.step(r, issue(), max_rounds: 3)

      assert next_run.phase == :needs_human_review
      assert Enum.any?(effects, &match?({:gh_label, 1001, ["needs-human-review"], []}, &1))
      assert Enum.any?(effects, &match?({:notify, {:question_max_rounds, 1001}}, &1))
    end
  end

  # ------------------------------------------------------------------
  # :triage_missing_markers
  # ------------------------------------------------------------------

  describe "step/3 :triage_missing_markers" do
    test "transitions to :consensus_check when all agents have satisfaction markers" do
      r = run(
        phase: :triage_missing_markers,
        satisfaction_map: %{codex: :satisfied, gemini: :satisfied, claude_ic: :satisfied}
      )

      {next_run, effects} = Orchestrator.step(r, issue(), [])

      assert next_run.phase == :consensus_check
      assert effects == []
    end

    test "emits {:triage_agent} for agents missing markers whose comments exist" do
      codex_comment = comment("## Codex", "I think this is fine.")
      i = issue([{"comments", [codex_comment]}])

      r = run(
        phase: :triage_missing_markers,
        expected_speakers: [:codex, :gemini],
        satisfaction_map: %{gemini: :satisfied}
      )

      {next_run, effects} = Orchestrator.step(r, i, [])

      assert next_run.phase == :triage_missing_markers
      assert [{:triage_agent, :codex, 1001, text}] = effects
      assert String.contains?(text, "## Codex")
    end

    test "transitions to :consensus_check when missing agents have no comments to triage" do
      r = run(
        phase: :triage_missing_markers,
        expected_speakers: [:codex, :gemini],
        satisfaction_map: %{gemini: :satisfied}
      )

      {next_run, effects} = Orchestrator.step(r, issue(), [])

      assert next_run.phase == :consensus_check
      assert effects == []
    end
  end

  # ------------------------------------------------------------------
  # :consensus_check
  # ------------------------------------------------------------------

  describe "step/3 :consensus_check" do
    test "closes when all agents are :satisfied" do
      r = run(
        phase: :consensus_check,
        retry_count: 1,
        satisfaction_map: %{codex: :satisfied, gemini: :satisfied, claude_ic: :satisfied}
      )

      {next_run, effects} = Orchestrator.step(r, issue(), [])

      assert next_run.phase == :closed
      assert Enum.any?(effects, &match?({:gh_close, 1001, _}, &1))
      assert Enum.any?(effects, &match?({:notify, {:question_satisfied, 1001, 1}}, &1))
    end

    test "closes when mixed :satisfied and :satisfied_conditional" do
      r = run(
        phase: :consensus_check,
        retry_count: 2,
        satisfaction_map: %{
          codex: :satisfied,
          gemini: :satisfied_conditional,
          claude_ic: :satisfied
        }
      )

      {next_run, _effects} = Orchestrator.step(r, issue(), [])

      assert next_run.phase == :closed
    end

    test "resets and returns to :awaiting_turns when any agent needs-more-evidence" do
      r = run(
        phase: :consensus_check,
        retry_count: 1,
        completed_speakers: [:codex, :gemini, :claude_ic],
        satisfaction_map: %{
          codex: :satisfied,
          gemini: :needs_more_evidence,
          claude_ic: :satisfied
        }
      )

      {next_run, effects} = Orchestrator.step(r, issue(), max_rounds: 5)

      assert next_run.phase == :awaiting_turns
      assert next_run.completed_speakers == []
      assert next_run.satisfaction_map == %{}
      assert [{:notify, {:round_start, 1001, 2}}] = effects
    end

    test "flags :needs_human_review when max_rounds reached without consensus" do
      r = run(
        phase: :consensus_check,
        retry_count: 5,
        satisfaction_map: %{codex: :needs_more_evidence, gemini: :satisfied}
      )

      {next_run, effects} = Orchestrator.step(r, issue(), max_rounds: 5)

      assert next_run.phase == :needs_human_review
      assert Enum.any?(effects, &match?({:gh_label, 1001, ["needs-human-review"], []}, &1))
    end
  end

  # ------------------------------------------------------------------
  # Terminal phases
  # ------------------------------------------------------------------

  describe "step/3 terminal phases" do
    for phase <- [:closed, :needs_human_review, :needs_human_input] do
      test "#{phase} returns run unchanged with no effects" do
        r = run(phase: unquote(phase))
        {next_run, effects} = Orchestrator.step(r, issue(), [])

        assert next_run.phase == unquote(phase)
        assert effects == []
      end
    end
  end

  # ------------------------------------------------------------------
  # Phase progression — pure step/3 walkthrough, no I/O
  # ------------------------------------------------------------------

  describe "phase progression" do
    test "full satisfied path: awaiting_turns → triage → consensus → closed" do
      r0 = run()

      {r1, [{:run_agent, :codex, 1001}]} = Orchestrator.step(r0, issue(), [])
      r1 = %{r1 | completed_speakers: [:codex], satisfaction_map: %{codex: :satisfied}}

      {r2, [{:run_agent, :gemini, 1001}]} = Orchestrator.step(r1, issue(), [])

      r2 = %{
        r2
        | completed_speakers: [:codex, :gemini],
          satisfaction_map: %{codex: :satisfied, gemini: :satisfied}
      }

      {r3, [{:run_agent, :claude_ic, 1001}]} = Orchestrator.step(r2, issue(), [])

      r3 = %{
        r3
        | completed_speakers: [:codex, :gemini, :claude_ic],
          satisfaction_map: %{codex: :satisfied, gemini: :satisfied, claude_ic: :satisfied}
      }

      # All done → :triage_missing_markers
      {r4, [{:notify, {:round_complete, 1001}}]} = Orchestrator.step(r3, issue(), [])
      assert r4.phase == :triage_missing_markers

      # All markers present → :consensus_check
      {r5, []} = Orchestrator.step(r4, issue(), [])
      assert r5.phase == :consensus_check

      # All satisfied → :closed
      {r6, effects} = Orchestrator.step(r5, issue(), [])
      assert r6.phase == :closed
      assert Enum.any?(effects, &match?({:gh_close, 1001, _}, &1))
    end

    test "disagreement path resets speakers and loops back to :awaiting_turns" do
      r0 = run(
        phase: :consensus_check,
        retry_count: 1,
        completed_speakers: [:codex, :gemini, :claude_ic],
        satisfaction_map: %{codex: :needs_more_evidence, gemini: :satisfied, claude_ic: :satisfied}
      )

      {r1, effects} = Orchestrator.step(r0, issue(), max_rounds: 5)

      assert r1.phase == :awaiting_turns
      assert r1.completed_speakers == []
      assert r1.satisfaction_map == %{}
      assert [{:notify, {:round_start, 1001, 2}}] = effects
    end
  end

  # ------------------------------------------------------------------
  # Compatibility tests kept from original file
  # ------------------------------------------------------------------

  describe "Satisfaction.consensus?/1 edge cases" do
    test "consensus when satisfied label present" do
      assert Roundtable.Satisfaction.consensus?(["satisfied"])
    end

    test "no consensus when needs-more-evidence present" do
      refute Roundtable.Satisfaction.consensus?(["satisfied", "needs-more-evidence"])
    end

    test "no consensus with empty labels" do
      refute Roundtable.Satisfaction.consensus?([])
    end
  end

  describe "run/3" do
    setup do
      brief_path = Path.join(System.tmp_dir!(), "test_brief_#{System.unique_integer()}.md")
      File.write!(brief_path, "# Brief\n\n### Q1 — Test question\n\nDescribe the system.\n")
      on_exit(fn -> File.rm(brief_path) end)
      %{brief_path: brief_path}
    end

    test "returns empty list when questions list is empty", %{brief_path: brief_path} do
      assert [] = Orchestrator.run(brief_path, [], [])
    end
  end
end

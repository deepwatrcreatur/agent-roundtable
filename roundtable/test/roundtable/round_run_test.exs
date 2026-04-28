defmodule Roundtable.RoundRunTest do
  use ExUnit.Case, async: false

  alias Roundtable.RoundRun

  @test_issue 88_001

  setup do
    RoundRun.init()

    on_exit(fn ->
      :ets.delete(:roundtable_round_runs, @test_issue)
      File.rm("/tmp/roundtable_test_state/round_run_#{@test_issue}.json")
    end)

    :ok
  end

  # ------------------------------------------------------------------
  # new/2
  # ------------------------------------------------------------------

  describe "new/2" do
    test "creates struct with correct defaults" do
      run = RoundRun.new(@test_issue, [:codex, :gemini, :claude_ic])

      assert run.issue_number == @test_issue
      assert run.phase == :awaiting_turns
      assert run.expected_speakers == [:codex, :gemini, :claude_ic]
      assert run.completed_speakers == []
      assert run.satisfaction_map == %{}
      assert run.retry_count == 0
      assert %DateTime{} = run.updated_at
    end
  end

  # ------------------------------------------------------------------
  # put_phase/2
  # ------------------------------------------------------------------

  describe "put_phase/2" do
    test "transitions phase" do
      run = RoundRun.new(@test_issue, [:codex])
      updated = RoundRun.put_phase(run, :consensus_check)
      assert updated.phase == :consensus_check
    end

    test "stamps updated_at" do
      run = RoundRun.new(@test_issue, [:codex])
      before_dt = run.updated_at
      # ensure at least 1ms passes
      Process.sleep(2)
      updated = RoundRun.put_phase(run, :triage_missing_markers)
      assert DateTime.compare(updated.updated_at, before_dt) == :gt
    end

    test "all valid phases round-trip" do
      phases = [
        :awaiting_turns,
        :triage_missing_markers,
        :consensus_check,
        :needs_human_input,
        :closed,
        :needs_human_review
      ]

      run = RoundRun.new(@test_issue, [])

      for phase <- phases do
        assert RoundRun.put_phase(run, phase).phase == phase
      end
    end
  end

  # ------------------------------------------------------------------
  # mark_speaker_done/3
  # ------------------------------------------------------------------

  describe "mark_speaker_done/3" do
    test "adds agent to completed_speakers" do
      run = RoundRun.new(@test_issue, [:codex, :gemini])
      run = RoundRun.mark_speaker_done(run, :codex, :satisfied)

      assert :codex in run.completed_speakers
      assert run.satisfaction_map[:codex] == :satisfied
    end

    test "is idempotent for the same agent" do
      run = RoundRun.new(@test_issue, [:codex])
      run = RoundRun.mark_speaker_done(run, :codex, :satisfied)
      run = RoundRun.mark_speaker_done(run, :codex, :satisfied)

      assert length(run.completed_speakers) == 1
    end

    test "nil satisfaction preserves existing entry" do
      run = RoundRun.new(@test_issue, [:codex])
      run = RoundRun.mark_speaker_done(run, :codex, :satisfied)
      run = RoundRun.mark_speaker_done(run, :codex, nil)

      assert run.satisfaction_map[:codex] == :satisfied
    end

    test "records all three satisfaction results" do
      run = RoundRun.new(@test_issue, [:codex, :gemini, :claude_ic])
      run = RoundRun.mark_speaker_done(run, :codex, :satisfied)
      run = RoundRun.mark_speaker_done(run, :gemini, :satisfied_conditional)
      run = RoundRun.mark_speaker_done(run, :claude_ic, :needs_more_evidence)

      assert run.satisfaction_map[:codex] == :satisfied
      assert run.satisfaction_map[:gemini] == :satisfied_conditional
      assert run.satisfaction_map[:claude_ic] == :needs_more_evidence
    end
  end

  # ------------------------------------------------------------------
  # persist/1 and load/1
  # ------------------------------------------------------------------

  describe "persist/1 and load/1" do
    test "ETS round-trip" do
      run = RoundRun.new(@test_issue, [:codex, :gemini])
      assert :ok = RoundRun.persist(run)
      assert {:ok, loaded} = RoundRun.load(@test_issue)

      assert loaded.issue_number == @test_issue
      assert loaded.phase == :awaiting_turns
      assert loaded.expected_speakers == [:codex, :gemini]
    end

    test "JSON round-trip when ETS is cold" do
      run =
        RoundRun.new(@test_issue, [:codex])
        |> RoundRun.put_phase(:consensus_check)
        |> RoundRun.mark_speaker_done(:codex, :satisfied_conditional)

      assert :ok = RoundRun.persist(run)

      # Evict from ETS to force JSON path
      :ets.delete(:roundtable_round_runs, @test_issue)

      assert {:ok, loaded} = RoundRun.load(@test_issue)
      assert loaded.phase == :consensus_check
      assert loaded.expected_speakers == [:codex]
      assert loaded.satisfaction_map[:codex] == :satisfied_conditional
    end

    test "returns not_found for unknown issue" do
      :ets.delete(:roundtable_round_runs, 99_999)
      File.rm("/tmp/roundtable_test_state/round_run_99999.json")

      assert {:error, :not_found} = RoundRun.load(99_999)
    end

    test "JSON file contains human-readable phase string" do
      run = RoundRun.new(@test_issue, [:codex]) |> RoundRun.put_phase(:triage_missing_markers)
      RoundRun.persist(run)

      {:ok, json} = File.read("/tmp/roundtable_test_state/round_run_#{@test_issue}.json")
      assert json =~ "triage_missing_markers"
    end
  end

  # ------------------------------------------------------------------
  # build_from_issue/3 (drives reconcile logic, no Gh mock needed)
  # ------------------------------------------------------------------

  describe "build_from_issue/3" do
    test "extracts completed_speakers from comment headers" do
      issue = %{
        "state" => "open",
        "labels" => [],
        "comments" => [
          %{"id" => "c1", "body" => "## Codex\n\nMy analysis.\n\n[needs more evidence: proof]"},
          %{"id" => "c2", "body" => "## Gemini\n\nAgreed.\n\n[satisfied]"}
        ]
      }

      run = RoundRun.build_from_issue(42, [:codex, :gemini, :claude_ic], issue)

      assert :codex in run.completed_speakers
      assert :gemini in run.completed_speakers
      refute :claude_ic in run.completed_speakers
    end

    test "parses satisfaction markers per speaker" do
      issue = %{
        "state" => "open",
        "labels" => [],
        "comments" => [
          %{"id" => "c1", "body" => "## Codex\n\nText.\n\n[satisfied]"},
          %{"id" => "c2", "body" => "## Gemini\n\nText.\n\n[satisfied-conditional: needs deployment]"},
          %{"id" => "c3", "body" => "## Claude IC\n\nText.\n\n[needs more evidence: repro steps]"}
        ]
      }

      run = RoundRun.build_from_issue(42, [:codex, :gemini, :claude_ic], issue)

      assert run.satisfaction_map[:codex] == :satisfied
      assert run.satisfaction_map[:gemini] == :satisfied_conditional
      assert run.satisfaction_map[:claude_ic] == :needs_more_evidence
    end

    test "infers :closed phase from issue state" do
      issue = %{"state" => "closed", "labels" => [], "comments" => []}
      run = RoundRun.build_from_issue(42, [], issue)
      assert run.phase == :closed
    end

    test "infers :needs_human_review from label" do
      issue = %{
        "state" => "open",
        "labels" => [%{"name" => "needs-human-review"}],
        "comments" => []
      }

      run = RoundRun.build_from_issue(42, [], issue)
      assert run.phase == :needs_human_review
    end

    test "defaults to :awaiting_turns for open issue with no special labels" do
      issue = %{
        "state" => "open",
        "labels" => [%{"name" => "satisfied"}],
        "comments" => []
      }

      run = RoundRun.build_from_issue(42, [], issue)
      assert run.phase == :awaiting_turns
    end

    test "collects comment IDs" do
      issue = %{
        "state" => "open",
        "labels" => [],
        "comments" => [
          %{"id" => "101", "body" => "## Codex\n\nText.\n\n[satisfied]"},
          %{"id" => "102", "body" => "## Gemini\n\nText.\n\n[satisfied]"}
        ]
      }

      run = RoundRun.build_from_issue(42, [], issue)
      assert "101" in run.last_comment_ids
      assert "102" in run.last_comment_ids
    end

    test "ignores non-agent comments" do
      issue = %{
        "state" => "open",
        "labels" => [],
        "comments" => [
          %{"id" => "1", "body" => "Human comment, no header"},
          %{"id" => "2", "body" => "## Codex\n\nText.\n\n[satisfied]"}
        ]
      }

      run = RoundRun.build_from_issue(42, [:codex, :gemini], issue)
      assert run.completed_speakers == [:codex]
    end
  end
end

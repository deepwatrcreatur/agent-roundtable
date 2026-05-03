defmodule Roundtable.RoundRunTest do
  use ExUnit.Case, async: false

  alias Roundtable.RoundRun
  alias Roundtable.TestSupport.FakeRunner

  @test_issue 88_001

  setup do
    RoundRun.init()
    Process.put(:test_pid, self())
    Process.put(:runner_result, {"", 0})

    on_exit(fn ->
      :ets.delete(:roundtable_round_runs, @test_issue)
      File.rm("/tmp/roundtable_test_state/round_run_#{@test_issue}.json")
    end)

    :ok
  end

  # ------------------------------------------------------------------
  # reconcile_from_github/2
  # ------------------------------------------------------------------

  describe "reconcile_from_github/2" do
    test "fetches issue data through Gh.view_issue and rebuilds state" do
      Process.put(
        :runner_result,
        {~s({"state":"OPEN","labels":[{"name":"needs-human-review"}],"comments":[{"id":"c1","body":"## Codex\\n\\nText.\\n\\n[satisfied]"},{"id":"c2","body":"## Gemini\\n\\nText.\\n\\n[needs more evidence: more proof]"}]}),
         0}
      )

      assert {:ok, run} =
               RoundRun.reconcile_from_github(
                 42,
                 %{repo: "owner/repo", runner: FakeRunner, agents: [:codex, :gemini]}
               )

      assert run.issue_number == 42
      assert run.phase == :needs_human_review
      assert run.expected_speakers == [:codex, :gemini]
      assert run.completed_speakers == [:codex, :gemini]
      assert run.satisfaction_map[:codex] == :satisfied
      assert run.satisfaction_map[:gemini] == :needs_more_evidence

      assert_received {:cmd, "gh",
                       [
                         "issue",
                         "view",
                         "42",
                         "-R",
                         "owner/repo",
                         "--comments",
                         "--json",
                         "labels,state,comments"
                       ], [stderr_to_stdout: true]}
    end

    test "passes through gh errors" do
      Process.put(:runner_result, {"bad token", 1})

      assert {:error, {:command_failed, 1, "bad token"}} =
               RoundRun.reconcile_from_github(42, %{runner: FakeRunner})
    end
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
        :coordinator_unavailable,
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
          %{
            "id" => "c2",
            "body" => "## Gemini\n\nText.\n\n[satisfied-conditional: needs deployment]"
          },
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

    test "infers :coordinator_unavailable from label" do
      issue = %{
        "state" => "open",
        "labels" => [%{"name" => "coordinator-unavailable"}],
        "comments" => []
      }

      run = RoundRun.build_from_issue(42, [], issue)
      assert run.phase == :coordinator_unavailable
    end
  end

  # ------------------------------------------------------------------
  # Coordinator lease / failover
  # ------------------------------------------------------------------

  describe "claim_coordinator/3" do
    test "claims when no coordinator is active" do
      run = RoundRun.new(@test_issue, [:codex])
      assert {:ok, claimed} = RoundRun.claim_coordinator(run, :claude_ic, 300)

      assert claimed.coordinator == :claude_ic
      assert %DateTime{} = claimed.coordinator_lease_expires_at
      assert %DateTime{} = claimed.last_progress_at
    end

    test "fails when an active coordinator holds a valid lease" do
      run = RoundRun.new(@test_issue, [:codex])
      {:ok, run} = RoundRun.claim_coordinator(run, :claude_ic, 300)

      assert {:error, :coordinator_active} = RoundRun.claim_coordinator(run, :codex, 300)
    end

    test "succeeds when existing lease has expired" do
      run = RoundRun.new(@test_issue, [:codex])
      past = DateTime.add(DateTime.utc_now(), -10, :second)

      run = %{
        run
        | coordinator: :claude_ic,
          coordinator_lease_expires_at: past
      }

      assert {:ok, claimed} = RoundRun.claim_coordinator(run, :codex, 300)
      assert claimed.coordinator == :codex
    end
  end

  describe "heartbeat/2" do
    test "refreshes lease expiry and last_progress_at" do
      run = RoundRun.new(@test_issue, [:codex])
      {:ok, run} = RoundRun.claim_coordinator(run, :claude_ic, 10)
      old_expires = run.coordinator_lease_expires_at

      Process.sleep(2)
      refreshed = RoundRun.heartbeat(run, 300)

      assert DateTime.compare(refreshed.coordinator_lease_expires_at, old_expires) == :gt
      assert DateTime.compare(refreshed.last_progress_at, run.last_progress_at) == :gt
    end
  end

  describe "coordinator_timed_out?/2" do
    test "returns false when no lease set" do
      run = RoundRun.new(@test_issue, [:codex])
      refute RoundRun.coordinator_timed_out?(run, DateTime.utc_now())
    end

    test "returns false before expiry" do
      run = RoundRun.new(@test_issue, [:codex])
      {:ok, run} = RoundRun.claim_coordinator(run, :claude_ic, 300)

      refute RoundRun.coordinator_timed_out?(run, DateTime.utc_now())
    end

    test "returns true after expiry" do
      run = RoundRun.new(@test_issue, [:codex])
      {:ok, run} = RoundRun.claim_coordinator(run, :claude_ic, 300)
      future = DateTime.add(DateTime.utc_now(), 400, :second)

      assert RoundRun.coordinator_timed_out?(run, future)
    end
  end

  describe "enter_coordinator_unavailable/1" do
    test "suspends current phase and transitions to :coordinator_unavailable" do
      run = RoundRun.new(@test_issue, [:codex]) |> RoundRun.put_phase(:consensus_check)
      {:ok, run} = RoundRun.claim_coordinator(run, :claude_ic, 300)

      unavailable = RoundRun.enter_coordinator_unavailable(run)

      assert unavailable.phase == :coordinator_unavailable
      assert unavailable.suspended_phase == :consensus_check
      assert unavailable.coordinator == nil
      assert unavailable.coordinator_lease_expires_at == nil
    end
  end

  describe "takeover/2" do
    test "resumes suspended phase with new coordinator" do
      run =
        RoundRun.new(@test_issue, [:codex])
        |> RoundRun.put_phase(:consensus_check)
        |> RoundRun.enter_coordinator_unavailable()

      assert {:ok, resumed} = RoundRun.takeover(run, :codex)

      assert resumed.phase == :consensus_check
      assert resumed.coordinator == :codex
      assert resumed.suspended_phase == nil
      assert resumed.takeover_count == 1
    end

    test "increments takeover_count on each takeover" do
      run =
        RoundRun.new(@test_issue, [:codex])
        |> RoundRun.enter_coordinator_unavailable()

      {:ok, run} = RoundRun.takeover(run, :codex)
      run = RoundRun.enter_coordinator_unavailable(run)
      {:ok, run} = RoundRun.takeover(run, :gemini)

      assert run.takeover_count == 2
    end

    test "returns error when no suspended phase" do
      run = RoundRun.new(@test_issue, [:codex])
      assert {:error, :no_suspended_phase} = RoundRun.takeover(run, :codex)
    end
  end

  describe "coordinator fields JSON round-trip" do
    test "coordinator fields survive persist/load cycle" do
      run = RoundRun.new(@test_issue, [:codex, :gemini])
      {:ok, run} = RoundRun.claim_coordinator(run, :claude_ic, 300)
      run = %{run | takeover_count: 1}

      assert :ok = RoundRun.persist(run)
      :ets.delete(:roundtable_round_runs, @test_issue)
      assert {:ok, loaded} = RoundRun.load(@test_issue)

      assert loaded.coordinator == :claude_ic
      assert %DateTime{} = loaded.coordinator_lease_expires_at
      assert %DateTime{} = loaded.last_progress_at
      assert loaded.takeover_count == 1
    end

    test "nil coordinator fields round-trip as nil" do
      run = RoundRun.new(@test_issue, [:codex])
      assert :ok = RoundRun.persist(run)
      :ets.delete(:roundtable_round_runs, @test_issue)
      assert {:ok, loaded} = RoundRun.load(@test_issue)

      assert loaded.coordinator == nil
      assert loaded.coordinator_lease_expires_at == nil
      assert loaded.last_progress_at == nil
      assert loaded.suspended_phase == nil
      assert loaded.takeover_count == 0
    end
  end
end

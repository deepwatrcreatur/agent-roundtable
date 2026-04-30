defmodule Roundtable.TelemetryTest do
  use ExUnit.Case, async: false

  alias Roundtable.Telemetry

  # Capture a single telemetry event into the test process mailbox.
  defp attach(event, ref) do
    handler_id = "test-#{inspect(ref)}-#{Enum.join(event, "-")}"

    :telemetry.attach(
      handler_id,
      event,
      fn _event, measurements, metadata, _config ->
        send(self(), {:telemetry, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
  end

  describe "all_events/0" do
    test "returns 12 event names" do
      assert length(Telemetry.all_events()) == 12
    end

    test "each event name is a list of atoms" do
      for event <- Telemetry.all_events() do
        assert is_list(event)
        assert Enum.all?(event, &is_atom/1)
      end
    end
  end

  describe "issue_poll/2" do
    test "emits [:roundtable, :issue, :poll] with correct metadata" do
      ref = make_ref()
      attach([:roundtable, :issue, :poll], ref)

      Telemetry.issue_poll(42, "owner/repo")

      assert_receive {:telemetry, %{system_time: _}, %{issue_number: 42, gh_repo: "owner/repo"}}
    end

    test "gh_repo may be nil" do
      ref = make_ref()
      attach([:roundtable, :issue, :poll], ref)

      Telemetry.issue_poll(1, nil)

      assert_receive {:telemetry, _, %{issue_number: 1, gh_repo: nil}}
    end
  end

  describe "agent_turn/3" do
    test "emits [:roundtable, :agent, :turn] with agent, issue_number, round" do
      ref = make_ref()
      attach([:roundtable, :agent, :turn], ref)

      Telemetry.agent_turn(:codex, 7, 2)

      assert_receive {:telemetry, _, %{agent: :codex, issue_number: 7, round: 2}}
    end
  end

  describe "gh_comment/3" do
    test "emits [:roundtable, :gh, :comment] with body_bytes" do
      ref = make_ref()
      attach([:roundtable, :gh, :comment], ref)

      Telemetry.gh_comment(10, :gemini, 512)

      assert_receive {:telemetry, _, %{issue_number: 10, agent: :gemini, body_bytes: 512}}
    end
  end

  describe "satisfaction_parse/3" do
    test "emits [:roundtable, :satisfaction, :parse] for marker method" do
      ref = make_ref()
      attach([:roundtable, :satisfaction, :parse], ref)

      Telemetry.satisfaction_parse(:codex, "satisfied", :marker)

      assert_receive {:telemetry, _, %{agent: :codex, result: "satisfied", method: :marker}}
    end

    test "emits for triage method" do
      ref = make_ref()
      attach([:roundtable, :satisfaction, :parse], ref)

      Telemetry.satisfaction_parse(:gemini, "needs-more-evidence", :triage)

      assert_receive {:telemetry, _,
                      %{agent: :gemini, result: "needs-more-evidence", method: :triage}}
    end
  end

  describe "ic_triage/2" do
    test "emits [:roundtable, :ic, :triage] with issue_number and result" do
      ref = make_ref()
      attach([:roundtable, :ic, :triage], ref)

      Telemetry.ic_triage(5, "satisfied-conditional")

      assert_receive {:telemetry, _, %{issue_number: 5, result: "satisfied-conditional"}}
    end
  end

  describe "consensus_check/3" do
    test "emits [:roundtable, :consensus, :check] with labels and result" do
      ref = make_ref()
      attach([:roundtable, :consensus, :check], ref)

      Telemetry.consensus_check(3, ["satisfied", "satisfied-conditional"], true)

      assert_receive {:telemetry, _,
                      %{
                        issue_number: 3,
                        labels: ["satisfied", "satisfied-conditional"],
                        result: true
                      }}
    end
  end

  describe "issue_close/3" do
    test "emits [:roundtable, :issue, :close] with round and reason" do
      ref = make_ref()
      attach([:roundtable, :issue, :close], ref)

      Telemetry.issue_close(8, 3, :consensus)

      assert_receive {:telemetry, _, %{issue_number: 8, round: 3, reason: :consensus}}
    end

    test "max_rounds reason" do
      ref = make_ref()
      attach([:roundtable, :issue, :close], ref)

      Telemetry.issue_close(9, 5, :max_rounds)

      assert_receive {:telemetry, _, %{issue_number: 9, reason: :max_rounds}}
    end
  end

  describe "phase_transition/3" do
    test "emits [:roundtable, :phase, :transition] with from and to phase" do
      ref = make_ref()
      attach([:roundtable, :phase, :transition], ref)

      Telemetry.phase_transition(4, :awaiting_turns, :consensus_check)

      assert_receive {:telemetry, _,
                      %{issue_number: 4, from_phase: :awaiting_turns, to_phase: :consensus_check}}
    end
  end

  describe "RoundRun.put_phase/2 integration" do
    test "put_phase emits phase_transition span" do
      Roundtable.RoundRun.init()
      ref = make_ref()
      attach([:roundtable, :phase, :transition], ref)

      run = Roundtable.RoundRun.new(77_001, [:codex])
      Roundtable.RoundRun.put_phase(run, :triage_missing_markers)

      assert_receive {:telemetry, _,
                      %{
                        issue_number: 77_001,
                        from_phase: :awaiting_turns,
                        to_phase: :triage_missing_markers
                      }}
    end
  end

  describe "coordinator_lease_claim/3" do
    test "emits [:roundtable, :coordinator, :lease, :claim] with coordinator and expires_at" do
      ref = make_ref()
      attach([:roundtable, :coordinator, :lease, :claim], ref)
      expires = DateTime.add(DateTime.utc_now(), 300, :second)

      Telemetry.coordinator_lease_claim(20, :claude_ic, expires)

      assert_receive {:telemetry, _, %{issue_number: 20, coordinator: :claude_ic, expires_at: _}}
    end
  end

  describe "coordinator_heartbeat/2" do
    test "emits [:roundtable, :coordinator, :heartbeat]" do
      ref = make_ref()
      attach([:roundtable, :coordinator, :heartbeat], ref)

      Telemetry.coordinator_heartbeat(21, :claude_ic)

      assert_receive {:telemetry, _, %{issue_number: 21, coordinator: :claude_ic}}
    end
  end

  describe "coordinator_timeout/2" do
    test "emits [:roundtable, :coordinator, :timeout]" do
      ref = make_ref()
      attach([:roundtable, :coordinator, :timeout], ref)

      Telemetry.coordinator_timeout(22, :claude_ic)

      assert_receive {:telemetry, _, %{issue_number: 22, coordinator: :claude_ic}}
    end
  end

  describe "coordinator_takeover/3" do
    test "emits [:roundtable, :coordinator, :takeover] with from and to" do
      ref = make_ref()
      attach([:roundtable, :coordinator, :takeover], ref)

      Telemetry.coordinator_takeover(23, :claude_ic, :codex)

      assert_receive {:telemetry, _,
                      %{issue_number: 23, from_coordinator: :claude_ic, to_coordinator: :codex}}
    end
  end

  describe "attach_logger/0" do
    test "attaches without error and handler receives events" do
      # Detach first in case a prior test left it attached
      :telemetry.detach("roundtable-json-logger")

      assert :ok = Telemetry.attach_logger()

      # Verify it fires — capture stdout to avoid test noise
      import ExUnit.CaptureIO
      output = capture_io(fn -> Telemetry.issue_poll(99, "test/repo") end)

      assert output =~ "roundtable.issue.poll"
      assert output =~ "\"issue_number\":99"

      :telemetry.detach("roundtable-json-logger")
    end

    test "is idempotent when called twice" do
      :telemetry.detach("roundtable-json-logger")

      assert :ok = Telemetry.attach_logger()
      assert :ok = Telemetry.attach_logger()

      :telemetry.detach("roundtable-json-logger")
    end
  end
end

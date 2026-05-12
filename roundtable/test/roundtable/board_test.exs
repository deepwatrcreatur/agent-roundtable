defmodule Roundtable.BoardTest do
  use ExUnit.Case, async: true

  alias Roundtable.Board

  defmodule FakeDolt do
    def query(sql, _opts) do
      send(self(), {:query, sql})

      cond do
        String.contains?(sql, "SELECT id, repo_ref") ->
          {:ok,
           [
             %{
               "id" => "wk-1",
               "repo_ref" => "deepwatrcreatur/agent-roundtable",
               "branch_ref" => "feat/board",
               "source_ref" => "round-70",
               "title" => "Implement board schema",
               "task_type" => "code_change",
               "input_payload" => ~s({"issue":73}),
               "desired_outcome" => ~s({"tests":"green"}),
               "status" => "queued",
               "priority" => "10",
               "assignee_type" => "agent",
               "assignee_ref" => "codex-gpt54",
               "workflow_ref" => "wf-basic",
               "retry_policy" => ~s({"max_attempts":3}),
               "timeout_policy" => ~s({"hard_timeout_s":1800}),
               "hitl_policy" => ~s({"gate":"approve"}),
               "created_at" => "2026-05-12T00:00:00Z",
               "updated_at" => "2026-05-12T00:00:00Z",
               "closed_at" => nil
             }
           ]}

        String.contains?(sql, "SELECT id, work_item_id, attempt_number") ->
          {:ok,
           [
             %{
               "id" => "att-1",
               "work_item_id" => "wk-1",
               "attempt_number" => "1",
               "runtime_id" => "rtk-1",
               "agent_id" => "codex-gpt54",
               "status" => "failed",
               "lease_expires_at" => nil,
               "started_at" => "2026-05-12T00:01:00Z",
               "finished_at" => "2026-05-12T00:02:00Z",
               "exit_class" => "tool_error",
               "summary" => "lint failed",
               "error_excerpt" => "mix format mismatch",
               "artifact_ref" => "artifact://att-1"
             },
             %{
               "id" => "att-2",
               "work_item_id" => "wk-1",
               "attempt_number" => "2",
               "runtime_id" => "rtk-1",
               "agent_id" => "codex-gpt54",
               "status" => "running",
               "lease_expires_at" => "2026-05-12T00:12:00Z",
               "started_at" => "2026-05-12T00:10:00Z",
               "finished_at" => nil,
               "exit_class" => nil,
               "summary" => "re-running tests",
               "error_excerpt" => nil,
               "artifact_ref" => nil
             }
           ]}

        String.contains?(sql, "SELECT id, work_item_id, attempt_id, gate_type") ->
          {:ok,
           [
             %{
               "id" => "gate-1",
               "work_item_id" => "wk-1",
               "attempt_id" => "att-2",
               "gate_type" => "approve",
               "prompt" => "Promote patch?",
               "options_json" => ~s(["approve","reject"]),
               "state" => "open",
               "decision_json" => nil,
               "resolved_by" => nil,
               "created_at" => "2026-05-12T00:15:00Z",
               "resolved_at" => nil
             }
           ]}

        String.contains?(sql, "SELECT runtime_id, host_label, transport") ->
          {:ok,
           [
             %{
               "runtime_id" => "rtk-1",
               "host_label" => "local runner",
               "transport" => "unix_socket",
               "status" => "busy",
               "capabilities_json" => ~s({"profiles":["codex-gpt54"]}),
               "last_seen_at" => "2026-05-12T00:20:00Z",
               "active_attempt_id" => "att-2",
               "metadata_json" => ~s({"host":"strix"})
             }
           ]}

        String.contains?(sql, "SELECT id, attempt_id, work_item_id, event_type") ->
          {:ok,
           [
             %{
               "id" => "evt-1",
               "attempt_id" => "att-2",
               "work_item_id" => "wk-1",
               "event_type" => "progress",
               "summary" => "running tests",
               "metadata_json" => ~s({"phase":"validation"}),
               "created_at" => "2026-05-12T00:11:00Z"
             }
           ]}

        true ->
          {:ok, []}
      end
    end

    def write_files(params, _opts) do
      send(self(), {:commit, params})
      {:ok, %{commit_id: "abc123", branch: "main"}}
    end
  end

  test "schema SQL defines all board tables" do
    sql = Board.schema_sql()

    assert sql =~ "CREATE TABLE IF NOT EXISTS work_items"
    assert sql =~ "CREATE TABLE IF NOT EXISTS work_attempts"
    assert sql =~ "CREATE TABLE IF NOT EXISTS human_gates"
    assert sql =~ "CREATE TABLE IF NOT EXISTS runtime_heartbeats"
    assert sql =~ "CREATE TABLE IF NOT EXISTS work_attempt_events"
  end

  test "create_work_item persists board rows with commit metadata" do
    assert :ok =
             Board.create_work_item(
               "/tmp/repo",
               %{
                 id: "wk-1",
                 repo_ref: "deepwatrcreatur/agent-roundtable",
                 branch_ref: "feat/board",
                 source_ref: "round-70",
                 title: "Implement board schema",
                 task_type: "code_change",
                 input_payload: %{issue: 73},
                 desired_outcome: %{tests: "green"},
                 status: "queued",
                 priority: 10,
                 assignee_type: "agent",
                 assignee_ref: "codex-gpt54",
                 workflow_ref: "wf-basic",
                 retry_policy: %{max_attempts: 3},
                 timeout_policy: %{hard_timeout_s: 1800},
                 hitl_policy: %{gate: "approve"}
               },
               dolt: FakeDolt
             )

    assert_received {:query, schema_sql}
    assert schema_sql =~ "CREATE TABLE IF NOT EXISTS work_items"

    assert_received {:query, insert_sql}
    assert insert_sql =~ "REPLACE INTO work_items"
    assert insert_sql =~ "'wk-1'"
    assert insert_sql =~ "'code_change'"
    assert insert_sql =~ "\"issue\":73"

    assert_received {:commit, commit}
    assert commit.message =~ "create work item wk-1"
    refute commit.sign?
  end

  test "append_attempt and open_human_gate preserve retry lineage and structured gates" do
    assert :ok =
             Board.append_attempt(
               "/tmp/repo",
               %{
                 id: "att-2",
                 work_item_id: "wk-1",
                 attempt_number: 2,
                 runtime_id: "rtk-1",
                 agent_id: "codex-gpt54",
                 status: "running",
                 lease_expires_at: "2026-05-12T00:12:00Z",
                 summary: "re-running tests"
               },
               dolt: FakeDolt
             )

    assert_received {:query, attempt_schema_sql}
    assert attempt_schema_sql =~ "CREATE TABLE IF NOT EXISTS work_attempts"

    assert_received {:query, attempt_sql}
    assert attempt_sql =~ "REPLACE INTO work_attempts"
    assert attempt_sql =~ "'att-2'"
    assert attempt_sql =~ "'wk-1'"
    assert attempt_sql =~ "2"

    assert_received {:commit, attempt_commit}
    assert attempt_commit.message =~ "append attempt att-2"

    assert :ok =
             Board.open_human_gate(
               "/tmp/repo",
               %{
                 id: "gate-1",
                 work_item_id: "wk-1",
                 attempt_id: "att-2",
                 gate_type: "approve",
                 prompt: "Promote patch?",
                 options: ["approve", "reject"]
               },
               dolt: FakeDolt
             )

    assert_received {:query, gate_schema_sql}
    assert gate_schema_sql =~ "CREATE TABLE IF NOT EXISTS human_gates"

    assert_received {:query, gate_sql}
    assert gate_sql =~ "REPLACE INTO human_gates"
    assert gate_sql =~ "'gate-1'"
    assert gate_sql =~ ~s(["approve","reject"])

    assert_received {:commit, gate_commit}
    assert gate_commit.message =~ "open human gate gate-1"
  end

  test "heartbeat_runtime upserts runtime state and decodes board views" do
    assert :ok =
             Board.heartbeat_runtime(
               "/tmp/repo",
               %{
                 runtime_id: "rtk-1",
                 host_label: "local runner",
                 transport: "unix_socket",
                 status: "busy",
                 capabilities: %{profiles: ["codex-gpt54"]},
                 active_attempt_id: "att-2",
                 metadata: %{host: "strix"}
               },
               dolt: FakeDolt
             )

    assert_received {:query, heartbeat_schema_sql}
    assert heartbeat_schema_sql =~ "CREATE TABLE IF NOT EXISTS runtime_heartbeats"

    assert_received {:query, heartbeat_sql}
    assert heartbeat_sql =~ "REPLACE INTO runtime_heartbeats"
    assert heartbeat_sql =~ "'rtk-1'"
    assert heartbeat_sql =~ "'unix_socket'"

    assert {:ok, [item]} = Board.list_work_items("/tmp/repo", dolt: FakeDolt)
    assert item.id == "wk-1"
    assert item.input_payload == %{"issue" => 73}
    assert item.retry_policy == %{"max_attempts" => 3}

    assert {:ok, attempts} = Board.list_attempts("/tmp/repo", "wk-1", dolt: FakeDolt)
    assert Enum.map(attempts, & &1.attempt_number) == [1, 2]

    assert {:ok, [gate]} = Board.list_human_gates("/tmp/repo", "wk-1", dolt: FakeDolt)
    assert gate.options == ["approve", "reject"]

    assert {:ok, [runtime]} = Board.list_runtime_heartbeats("/tmp/repo", dolt: FakeDolt)
    assert runtime.runtime_id == "rtk-1"
    assert runtime.capabilities == %{"profiles" => ["codex-gpt54"]}
  end

  test "gets individual rows and stores append-only attempt events" do
    assert {:ok, item} = Board.get_work_item("/tmp/repo", "wk-1", dolt: FakeDolt)
    assert item.id == "wk-1"
    assert_received {:query, get_item_schema_sql}
    assert get_item_schema_sql =~ "CREATE TABLE IF NOT EXISTS work_items"
    assert_received {:query, get_item_sql}
    assert get_item_sql =~ "FROM work_items"

    assert {:ok, attempt} = Board.get_attempt("/tmp/repo", "att-2", dolt: FakeDolt)
    assert attempt.id == "att-1"
    assert_received {:query, get_attempt_schema_sql}
    assert get_attempt_schema_sql =~ "CREATE TABLE IF NOT EXISTS work_attempts"
    assert_received {:query, get_attempt_sql}
    assert get_attempt_sql =~ "FROM work_attempts"

    assert :ok =
             Board.append_attempt_event(
               "/tmp/repo",
               %{
                 id: "evt-2",
                 attempt_id: "att-2",
                 work_item_id: "wk-1",
                 event_type: "progress",
                 summary: "running tests",
                 metadata: %{phase: "validation"}
               },
               dolt: FakeDolt
             )

    assert_received {:query, schema_sql}
    assert schema_sql =~ "CREATE TABLE IF NOT EXISTS work_attempt_events"

    assert_received {:query, event_sql}

    assert event_sql =~ "REPLACE INTO work_attempt_events" or
             event_sql =~ "SELECT id, attempt_id, work_item_id, event_type"

    if String.contains?(event_sql, "SELECT id, attempt_id, work_item_id, event_type") do
      assert_received {:query, insert_event_sql}
      assert insert_event_sql =~ "REPLACE INTO work_attempt_events"
      assert insert_event_sql =~ "'evt-2'"
      assert insert_event_sql =~ "'progress'"
    else
      assert event_sql =~ "'evt-2'"
      assert event_sql =~ "'progress'"
    end

    assert {:ok, [event]} = Board.list_attempt_events("/tmp/repo", "att-2", dolt: FakeDolt)
    assert event.event_type == "progress"
    assert event.metadata == %{"phase" => "validation"}
  end
end

defmodule Roundtable.BoardKanbanReadModelTest do
  use ExUnit.Case, async: true

  alias Roundtable.BoardKanbanReadModel

  defmodule FakeBoard do
    def list_work_items(_repo_path, _opts) do
      {:ok,
       [
         %{
           id: "wk-queued",
           repo_ref: "deepwatrcreatur/agent-roundtable",
           branch_ref: "feat/queued",
           source_ref: "round-queued",
           title: "Queued work",
           task_type: "code_change",
           input_payload: %{"surface" => "/forgejo-shell"},
           priority: 10,
           status: "queued",
           assignee_ref: "codex-queued",
           desired_outcome: %{"result" => "Queue should stay visible"},
           updated_at: "2026-05-23T00:00:00Z"
         },
         %{
           id: "wk-gated",
           repo_ref: "deepwatrcreatur/agent-roundtable",
           branch_ref: "feat/gated",
           source_ref: "round-gated",
           title: "Needs approval",
           task_type: "deploy",
           input_payload: %{"route" => "/forgejo-shell/reports"},
           priority: 20,
           status: "awaiting_human_input",
           assignee_ref: "codex-review",
           desired_outcome: %{"result" => "Ship after approval"},
           updated_at: "2026-05-23T00:05:00Z"
         },
         %{
           id: "wk-running",
           repo_ref: "deepwatrcreatur/agent-roundtable",
           branch_ref: "feat/running",
           source_ref: "round-running",
           title: "Runtime drift",
           task_type: "benchmark",
           input_payload: %{"surface" => "/board"},
           priority: 30,
           status: "running",
           assignee_ref: "codex-bench",
           desired_outcome: %{"result" => "Benchmarks complete"},
           updated_at: "2026-05-23T00:10:00Z"
         },
         %{
           id: "wk-done",
           repo_ref: "kubernetes/kubernetes",
           branch_ref: "feat/done",
           source_ref: "round-done",
           title: "Completed work",
           task_type: "review",
            priority: 40,
            status: "succeeded",
           assignee_ref: "codex-review",
           desired_outcome: %{"result" => "Validation passes"},
           updated_at: "2026-05-23T00:20:00Z"
         }
       ]}
    end

    def list_attempts(_repo_path, "wk-queued", _opts), do: {:ok, []}

    def list_attempts(_repo_path, "wk-gated", _opts) do
      {:ok,
       [
         %{
           id: "att-2",
           work_item_id: "wk-gated",
           attempt_number: 1,
           runtime_id: "rtk-1",
           status: "running",
           lease_expires_at: "2026-05-23T01:07:00Z",
           summary: "Waiting for approval",
           exit_class: "needs_human_gate",
           started_at: "2026-05-23T00:50:00Z"
         }
       ]}
    end

    def list_attempts(_repo_path, "wk-running", _opts) do
      {:ok,
       [
         %{
           id: "att-3",
           work_item_id: "wk-running",
           attempt_number: 2,
           runtime_id: "rtk-2",
           status: "running",
           lease_expires_at: "2026-05-23T00:59:00Z",
           summary: "Benchmark in progress",
           exit_class: nil,
           started_at: "2026-05-23T00:40:00Z"
         }
       ]}
    end

    def list_attempts(_repo_path, "wk-done", _opts) do
      {:ok,
       [
         %{
           id: "att-4",
           work_item_id: "wk-done",
           attempt_number: 1,
           runtime_id: "rtk-1",
           status: "succeeded",
           lease_expires_at: nil,
           summary: "Validation passed",
           exit_class: "success",
           started_at: "2026-05-23T00:00:00Z",
           finished_at: "2026-05-23T00:15:00Z"
         }
       ]}
    end

    def list_human_gates(_repo_path, "wk-gated", _opts) do
      {:ok,
       [
         %{
           id: "gate-1",
           work_item_id: "wk-gated",
           attempt_id: "att-2",
           gate_type: "approve",
           state: "open",
           prompt: "Ship this?",
           created_at: "2026-05-23T00:55:00Z"
         }
       ]}
    end

    def list_human_gates(_repo_path, _work_item_id, _opts), do: {:ok, []}

    def list_runtime_heartbeats(_repo_path, _opts) do
      {:ok,
       [
         %{runtime_id: "rtk-1", host_label: "runner-1", status: "busy", last_seen_at: "2026-05-23T00:57:00Z"},
         %{runtime_id: "rtk-2", host_label: "runner-2", status: "offline", last_seen_at: "2026-05-23T00:45:00Z"}
       ]}
    end

    def list_attempt_events(_repo_path, "att-2", _opts) do
      {:ok,
       [
         %{id: "evt-1", attempt_id: "att-2", event_type: "needs_human_gate", summary: "Approval required", created_at: "2026-05-23T00:56:00Z"}
       ]}
    end

    def list_attempt_events(_repo_path, "att-3", _opts) do
      {:ok,
       [
         %{id: "evt-2", attempt_id: "att-3", event_type: "progress", summary: "Still running benchmarks", created_at: "2026-05-23T00:58:30Z"}
       ]}
    end

    def list_attempt_events(_repo_path, "att-4", _opts), do: {:ok, []}
  end

  test "derives lanes, badges, and attention alerts from canonical board state" do
    now = ~U[2026-05-23 01:00:00Z]

    assert {:ok, snapshot} =
             BoardKanbanReadModel.snapshot(
               "/tmp/repo",
               board: FakeBoard,
               now: now
             )

    cards = Map.new(snapshot.cards, &{&1.work_item_id, &1})

    assert cards["wk-queued"].lane == "queued"
    assert cards["wk-gated"].lane == "gated"
    assert cards["wk-gated"].gate_type == "approve"
    assert "gate:open" in cards["wk-gated"].badge_refs
    assert cards["wk-gated"].owner_ref == "codex-review"
    assert cards["wk-gated"].next_signal == "Ship this?"
    assert cards["wk-gated"].freshness_state == "fresh"
    assert Enum.any?(cards["wk-gated"].evidence_links, &(&1.href == "/forgejo-shell/reports"))

    assert cards["wk-running"].lane == "attention"
    assert "runtime_offline" in cards["wk-running"].alert_refs
    assert "lease:expired" in cards["wk-running"].badge_refs
    assert cards["wk-running"].next_signal == "Still running benchmarks"
    assert cards["wk-running"].freshness_state == "fresh"
    assert Enum.any?(cards["wk-running"].evidence_links, &(&1.href == "/board"))

    assert cards["wk-done"].lane == "done"
    assert Enum.any?(cards["wk-done"].evidence_links, &(&1.href == "/forgejo-shell?demo=kubernetes"))
    assert snapshot.counts["queued"] == 1
    assert snapshot.counts["gated"] == 1
    assert snapshot.counts["attention"] == 1
    assert snapshot.counts["done"] == 1
  end
end

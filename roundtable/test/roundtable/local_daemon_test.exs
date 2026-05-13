defmodule Roundtable.LocalDaemonTest do
  use ExUnit.Case, async: true

  alias Roundtable.LocalDaemon

  defmodule FakeBoard do
    def ensure_schema(_repo_path, _opts), do: {:ok, :ok}

    def create_work_item(_repo_path, attrs, opts) do
      Agent.update(store(opts), fn state ->
        put_in(state, [:work_items, attrs.id], attrs)
      end)

      :ok
    end

    def get_work_item(_repo_path, id, opts) do
      {:ok, Agent.get(store(opts), &get_in(&1, [:work_items, id]))}
    end

    def list_work_items(_repo_path, opts) do
      {:ok,
       Agent.get(store(opts), fn state ->
         state.work_items
         |> Map.values()
         |> Enum.sort_by(fn item -> item.id end)
       end)}
    end

    def append_attempt(_repo_path, attrs, opts) do
      Agent.update(store(opts), fn state ->
        put_in(state, [:attempts, attrs.id], attrs)
      end)

      :ok
    end

    def get_attempt(_repo_path, id, opts) do
      {:ok, Agent.get(store(opts), &get_in(&1, [:attempts, id]))}
    end

    def list_attempts(_repo_path, work_item_id, opts) do
      attempts =
        Agent.get(store(opts), fn state ->
          state.attempts
          |> Map.values()
          |> Enum.filter(&(&1.work_item_id == work_item_id))
          |> Enum.sort_by(& &1.attempt_number)
        end)

      {:ok, attempts}
    end

    def open_human_gate(_repo_path, attrs, opts) do
      Agent.update(store(opts), fn state ->
        put_in(state, [:gates, attrs.id], attrs)
      end)

      :ok
    end

    def list_human_gates(_repo_path, work_item_id, opts) do
      gates =
        Agent.get(store(opts), fn state ->
          state.gates
          |> Map.values()
          |> Enum.filter(&(&1.work_item_id == work_item_id))
          |> Enum.sort_by(& &1.created_at)
        end)

      {:ok, gates}
    end

    def heartbeat_runtime(_repo_path, attrs, opts) do
      Agent.update(store(opts), fn state ->
        put_in(state, [:runtimes, attrs.runtime_id], attrs)
      end)

      :ok
    end

    def list_runtime_heartbeats(_repo_path, opts) do
      {:ok, Agent.get(store(opts), &Map.values(&1.runtimes))}
    end

    def append_attempt_event(_repo_path, attrs, opts) do
      Agent.update(store(opts), fn state ->
        put_in(state, [:events, attrs.id], attrs)
      end)

      :ok
    end

    def list_attempt_events(_repo_path, attempt_id, opts) do
      events =
        Agent.get(store(opts), fn state ->
          state.events
          |> Map.values()
          |> Enum.filter(&(&1.attempt_id == attempt_id))
          |> Enum.sort_by(& &1.created_at)
        end)

      {:ok, events}
    end

    defp store(opts), do: Keyword.fetch!(opts, :store)
  end

  defmodule FakeWorkflow do
    def resolve_work_item(_repo_path, work_item, _opts) do
      case work_item.workflow_ref do
        "wf-codex" ->
          {:ok,
           work_item
           |> Map.put(:allowed_task_types, ["code_change"])
           |> Map.put(:runtime_requirements, %{
             "profiles" => ["codex-gpt54"],
             "labels" => ["linux"]
           })
           |> Map.put(
             :retry_policy,
             Map.merge(%{"max_attempts" => 4}, work_item.retry_policy || %{})
           )}

        _ ->
          {:ok, Map.put_new(work_item, :runtime_requirements, %{})}
      end
    end

    def runtime_allowed?(work_item, opts) do
      requirements = Map.get(work_item, :runtime_requirements, %{})
      profiles = Keyword.get(opts, :runtime_profile_ids, [])
      labels = Keyword.get(opts, :runtime_labels, [])

      required_profiles = Map.get(requirements, "profiles", [])
      required_labels = Map.get(requirements, "labels", [])

      Enum.any?(required_profiles, &(&1 in profiles)) and
        Enum.all?(required_labels, &(&1 in labels))
    end
  end

  setup do
    {:ok, store} =
      Agent.start_link(fn ->
        %{work_items: %{}, attempts: %{}, gates: %{}, runtimes: %{}, events: %{}}
      end)

    [store: store]
  end

  test "registers runtimes and polls claimable work", %{store: store} do
    assert :ok =
             FakeBoard.create_work_item(
               "/tmp/repo",
               %{
                 id: "wk-1",
                 repo_ref: "deepwatrcreatur/agent-roundtable",
                 branch_ref: "feat/board",
                 source_ref: "round-70",
                 title: "Implement daemon contract",
                 task_type: "code_change",
                 input_payload: %{},
                 desired_outcome: %{},
                 status: "queued",
                 priority: 10,
                 assignee_type: nil,
                 assignee_ref: nil,
                 workflow_ref: nil,
                 retry_policy: %{"max_attempts" => 3},
                 timeout_policy: nil,
                 hitl_policy: nil,
                 created_at: "2026-05-12T09:00:00Z",
                 updated_at: "2026-05-12T09:00:00Z",
                 closed_at: nil
               },
               store: store
             )

    assert :ok =
             LocalDaemon.register_runtime(
               "/tmp/repo",
               %{
                 runtime_id: "rtk-1",
                 host_label: "local runner",
                 transport: "unix_socket",
                 capabilities: %{profiles: ["codex-gpt54"]},
                 metadata: %{host: "strix"}
               },
               board: FakeBoard,
               store: store
             )

    assert {:ok, item} =
             LocalDaemon.poll_work(
               "/tmp/repo",
               board: FakeBoard,
               store: store,
               runtime_id: "rtk-1"
             )

    assert item.id == "wk-1"
  end

  test "workflow definitions gate runtime matching and supply retry defaults", %{store: store} do
    assert :ok =
             FakeBoard.create_work_item(
               "/tmp/repo",
               %{
                 id: "wk-1",
                 repo_ref: "deepwatrcreatur/agent-roundtable",
                 branch_ref: nil,
                 source_ref: nil,
                 title: "Workflow gated task",
                 task_type: "code_change",
                 input_payload: %{},
                 desired_outcome: %{},
                 status: "queued",
                 priority: 10,
                 assignee_type: nil,
                 assignee_ref: nil,
                 workflow_ref: "wf-codex",
                 retry_policy: nil,
                 timeout_policy: nil,
                 hitl_policy: nil,
                 created_at: "2026-05-12T09:00:00Z",
                 updated_at: "2026-05-12T09:00:00Z",
                 closed_at: nil
               },
               store: store
             )

    assert {:ok, nil} =
             LocalDaemon.poll_work(
               "/tmp/repo",
               board: FakeBoard,
               workflow: FakeWorkflow,
               store: store,
               runtime_id: "rtk-1",
               runtime_profile_ids: ["gemini-cli"],
               runtime_labels: ["linux"]
             )

    assert {:ok, item} =
             LocalDaemon.poll_work(
               "/tmp/repo",
               board: FakeBoard,
               workflow: FakeWorkflow,
               store: store,
               runtime_id: "rtk-1",
               runtime_profile_ids: ["codex-gpt54"],
               runtime_labels: ["linux"]
             )

    assert item.workflow_ref == "wf-codex"
    assert item.retry_policy == %{"max_attempts" => 4}
  end

  test "claims work, starts attempt, emits progress, and renews leases", %{store: store} do
    FakeBoard.create_work_item(
      "/tmp/repo",
      %{
        id: "wk-1",
        repo_ref: "deepwatrcreatur/agent-roundtable",
        branch_ref: nil,
        source_ref: nil,
        title: "Claim me",
        task_type: "code_change",
        input_payload: %{},
        desired_outcome: %{},
        status: "queued",
        priority: 10,
        assignee_type: nil,
        assignee_ref: nil,
        workflow_ref: nil,
        retry_policy: %{"max_attempts" => 3},
        timeout_policy: nil,
        hitl_policy: nil,
        created_at: "2026-05-12T09:00:00Z",
        updated_at: "2026-05-12T09:00:00Z",
        closed_at: nil
      },
      store: store
    )

    assert {:ok, claim} =
             LocalDaemon.claim_work(
               "/tmp/repo",
               "rtk-1",
               "wk-1",
               board: FakeBoard,
               store: store,
               agent_id: "codex-gpt54",
               lease_seconds: 120,
               host_label: "local runner",
               transport: "unix_socket"
             )

    assert claim.work_item.status == "claimed"
    assert claim.attempt.status == "claimed"

    assert {:ok, started} =
             LocalDaemon.start_attempt(
               "/tmp/repo",
               claim.attempt.id,
               board: FakeBoard,
               store: store
             )

    assert started.status == "running"

    assert {:ok, event} =
             LocalDaemon.append_attempt_event(
               "/tmp/repo",
               claim.attempt.id,
               %{
                 event_type: "progress",
                 summary: "running tests",
                 metadata: %{phase: "validation"}
               },
               board: FakeBoard,
               store: store
             )

    assert event.event_type == "progress"

    assert {:ok, renewed} =
             LocalDaemon.renew_lease(
               "/tmp/repo",
               claim.attempt.id,
               board: FakeBoard,
               store: store,
               runtime_id: "rtk-1",
               lease_seconds: 240
             )

    assert renewed.lease_expires_at
  end

  test "opens human gates and records machine-usable failures", %{store: store} do
    FakeBoard.create_work_item(
      "/tmp/repo",
      %{
        id: "wk-1",
        repo_ref: "deepwatrcreatur/agent-roundtable",
        branch_ref: nil,
        source_ref: nil,
        title: "Needs human review",
        task_type: "code_change",
        input_payload: %{},
        desired_outcome: %{},
        status: "queued",
        priority: 10,
        assignee_type: nil,
        assignee_ref: nil,
        workflow_ref: nil,
        retry_policy: %{"max_attempts" => 2},
        timeout_policy: nil,
        hitl_policy: nil,
        created_at: "2026-05-12T09:00:00Z",
        updated_at: "2026-05-12T09:00:00Z",
        closed_at: nil
      },
      store: store
    )

    {:ok, claim} =
      LocalDaemon.claim_work(
        "/tmp/repo",
        "rtk-1",
        "wk-1",
        board: FakeBoard,
        store: store,
        agent_id: "codex-gpt54"
      )

    assert {:ok, %{gate: gate, attempt: attempt}} =
             LocalDaemon.request_human_gate(
               "/tmp/repo",
               claim.attempt.id,
               %{
                 gate_type: "clarify",
                 prompt: "Continue on fresh branch?",
                 options: ["yes", "no"]
               },
               board: FakeBoard,
               store: store
             )

    assert gate.gate_type == "clarify"
    assert attempt.status == "awaiting_human_input"

    assert {:ok, failed} =
             LocalDaemon.fail_attempt(
               "/tmp/repo",
               claim.attempt.id,
               board: FakeBoard,
               store: store,
               failure_class: "tool_error",
               summary: "formatter failed"
             )

    assert failed.attempt.exit_class == "tool_error"
    assert failed.work_item.status == "retry_scheduled"
    assert "tool_error" in LocalDaemon.failure_classes()

    assert {:error, {:invalid_failure_class, "bad"}} =
             LocalDaemon.fail_attempt("/tmp/repo", claim.attempt.id,
               board: FakeBoard,
               store: store,
               failure_class: "bad"
             )
  end

  test "expires stale claims into retry scheduling when lease renewal stops", %{store: store} do
    FakeBoard.create_work_item(
      "/tmp/repo",
      %{
        id: "wk-1",
        repo_ref: "deepwatrcreatur/agent-roundtable",
        branch_ref: nil,
        source_ref: nil,
        title: "Stale claim",
        task_type: "code_change",
        input_payload: %{},
        desired_outcome: %{},
        status: "claimed",
        priority: 10,
        assignee_type: "runtime",
        assignee_ref: "rtk-1",
        workflow_ref: nil,
        retry_policy: %{"max_attempts" => 3},
        timeout_policy: nil,
        hitl_policy: nil,
        created_at: "2026-05-12T09:00:00Z",
        updated_at: "2026-05-12T09:00:00Z",
        closed_at: nil
      },
      store: store
    )

    FakeBoard.append_attempt(
      "/tmp/repo",
      %{
        id: "att-1",
        work_item_id: "wk-1",
        attempt_number: 1,
        runtime_id: "rtk-1",
        agent_id: "codex-gpt54",
        status: "claimed",
        lease_expires_at: "2026-05-12T08:00:00Z",
        started_at: "2026-05-12T07:59:00Z"
      },
      store: store
    )

    assert :ok =
             LocalDaemon.expire_stale_claims(
               "/tmp/repo",
               board: FakeBoard,
               store: store,
               now: "2026-05-12T09:00:00Z"
             )

    assert {:ok, work_item} = FakeBoard.get_work_item("/tmp/repo", "wk-1", store: store)
    assert work_item.status == "retry_scheduled"

    assert {:ok, attempt} = FakeBoard.get_attempt("/tmp/repo", "att-1", store: store)
    assert attempt.exit_class == "runtime_disconnect"
  end
end

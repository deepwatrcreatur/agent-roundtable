defmodule Roundtable.BoardDemoSeed do
  @moduledoc """
  Seed a small browseable execution board demo into a local board repo.
  """

  alias Roundtable.Board

  @timestamps %{
    created: "2026-05-23T02:00:00Z",
    queued_updated: "2026-05-23T02:03:00Z",
    running_started: "2026-05-23T02:05:00Z",
    running_updated: "2026-05-23T02:09:00Z",
    gated_started: "2026-05-23T02:01:00Z",
    gated_updated: "2026-05-23T02:11:00Z",
    attention_started: "2026-05-23T01:20:00Z",
    attention_updated: "2026-05-23T02:12:00Z",
    done_started: "2026-05-23T00:45:00Z",
    done_finished: "2026-05-23T01:10:00Z",
    done_updated: "2026-05-23T01:10:00Z",
    failed_started: "2026-05-23T01:40:00Z",
    failed_finished: "2026-05-23T01:58:00Z",
    failed_updated: "2026-05-23T01:58:00Z",
    recent_runtime: "2026-05-23T02:12:30Z",
    stale_runtime: "2026-05-23T01:15:00Z",
    lease_healthy: "2026-05-23T03:45:00Z",
    lease_expired: "2026-05-23T01:50:00Z",
    gate_created: "2026-05-23T02:10:00Z"
  }

  @doc """
  Seed a deterministic demo board into `repo_path`.
  """
  @spec seed(String.t(), keyword()) :: :ok | {:error, term()}
  def seed(repo_path, opts \\ []) when is_binary(repo_path) do
    board = Keyword.get(opts, :board, Board)
    board_opts = Keyword.drop(opts, [:board])

    with :ok <- seed_runtimes(repo_path, board, board_opts),
         :ok <- seed_work_items(repo_path, board, board_opts),
         :ok <- seed_attempts(repo_path, board, board_opts),
         :ok <- seed_gates(repo_path, board, board_opts),
         :ok <- seed_events(repo_path, board, board_opts) do
      :ok
    end
  end

  defp seed_runtimes(repo_path, board, opts) do
    for runtime <- runtimes(), reduce: :ok do
      :ok -> board.heartbeat_runtime(repo_path, runtime, opts)
      error -> error
    end
  end

  defp seed_work_items(repo_path, board, opts) do
    for item <- work_items(), reduce: :ok do
      :ok -> board.create_work_item(repo_path, item, opts)
      error -> error
    end
  end

  defp seed_attempts(repo_path, board, opts) do
    for attempt <- attempts(), reduce: :ok do
      :ok -> board.append_attempt(repo_path, attempt, opts)
      error -> error
    end
  end

  defp seed_gates(repo_path, board, opts) do
    for gate <- human_gates(), reduce: :ok do
      :ok -> board.open_human_gate(repo_path, gate, opts)
      error -> error
    end
  end

  defp seed_events(repo_path, board, opts) do
    for event <- attempt_events(), reduce: :ok do
      :ok -> board.append_attempt_event(repo_path, event, opts)
      error -> error
    end
  end

  defp runtimes do
    [
      %{
        runtime_id: "runtime-vaglio-main",
        host_label: "vaglio main runtime",
        transport: "systemd",
        status: "busy",
        capabilities: %{profiles: ["codex", "review"], resource_scope: "host:vaglio"},
        active_attempt_id: "att-running-1",
        last_seen_at: @timestamps.recent_runtime,
        metadata: %{host: "vaglio", role: "executor"}
      },
      %{
        runtime_id: "runtime-vaglio-review",
        host_label: "vaglio review lane",
        transport: "systemd",
        status: "degraded",
        capabilities: %{profiles: ["review"], resource_scope: "host:vaglio"},
        active_attempt_id: "att-gated-1",
        last_seen_at: @timestamps.recent_runtime,
        metadata: %{host: "vaglio", role: "review"}
      },
      %{
        runtime_id: "runtime-vaglio-ops",
        host_label: "vaglio ops runtime",
        transport: "systemd",
        status: "offline",
        capabilities: %{profiles: ["ops"], resource_scope: "host:vaglio"},
        active_attempt_id: "att-attention-1",
        last_seen_at: @timestamps.stale_runtime,
        metadata: %{host: "vaglio", role: "ops"}
      }
    ]
  end

  defp work_items do
    [
      %{
        id: "wk-gated",
        repo_ref: "deepwatrcreatur/agent-roundtable",
        branch_ref: "fix/board-repo-path",
        source_ref: "round-103",
        title: "Review board repo bootstrap on vaglio",
        task_type: "code_change",
        input_payload: %{
          pr: 103
        },
        surface_route: "/board",
        evidence_links: [
          %{label: "Open board", href: "/board", kind: "surface"}
        ],
        desired_outcome: %{result: "board route stays live after switch"},
        status: "running",
        priority: 10,
        assignee_type: "agent",
        assignee_ref: "codex-gpt54",
        workflow_ref: "wf-review",
        retry_policy: %{max_attempts: 2},
        timeout_policy: %{hard_timeout_s: 1800},
        hitl_policy: %{gate: "approve"},
        created_at: @timestamps.created,
        updated_at: @timestamps.gated_updated
      },
      %{
        id: "wk-attention",
        repo_ref: "deepwatrcreatur/agent-roundtable",
        branch_ref: "main",
        source_ref: "round-88",
        title: "Repair stalled public repo cache warm path",
        task_type: "ops_repair",
        input_payload: %{
          concern: "cache warm"
        },
        surface_route: "/forgejo-shell",
        public_demo_id: "kubernetes",
        desired_outcome: %{result: "all demo caches hot"},
        status: "running",
        priority: 20,
        assignee_type: "agent",
        assignee_ref: "codex-gpt54",
        workflow_ref: "wf-ops",
        retry_policy: %{max_attempts: 3},
        timeout_policy: %{hard_timeout_s: 900},
        hitl_policy: %{gate: "notify"},
        created_at: @timestamps.created,
        updated_at: @timestamps.attention_updated
      },
      %{
        id: "wk-running",
        repo_ref: "deepwatrcreatur/agent-roundtable",
        branch_ref: "main",
        source_ref: "round-102",
        title: "Polish browseable board surface for public demos",
        task_type: "ui_polish",
        input_payload: %{
          audience: "operators"
        },
        surface_route: "/board",
        evidence_links: [
          %{label: "Open reports", href: "/forgejo-shell/reports", kind: "report"}
        ],
        desired_outcome: %{result: "legible live board"},
        status: "running",
        priority: 30,
        assignee_type: "agent",
        assignee_ref: "codex-gpt54",
        workflow_ref: "wf-ui",
        retry_policy: %{max_attempts: 2},
        timeout_policy: %{hard_timeout_s: 1200},
        hitl_policy: %{gate: "none"},
        created_at: @timestamps.created,
        updated_at: @timestamps.running_updated
      },
      %{
        id: "wk-queued",
        repo_ref: "deepwatrcreatur/agent-roundtable",
        branch_ref: "main",
        source_ref: "round-95",
        title: "Thread Sourcegraph evidence into subtree briefs",
        task_type: "analysis",
        input_payload: %{
          adapter: "sourcegraph",
          surface: "subtree_brief"
        },
        evidence_links: [
          %{label: "Open Forgejo shell", href: "/forgejo-shell", kind: "surface"}
        ],
        desired_outcome: %{result: "bounded semantic evidence in brief"},
        status: "queued",
        priority: 40,
        assignee_type: "agent",
        assignee_ref: "codex-gpt54",
        workflow_ref: "wf-analysis",
        retry_policy: %{max_attempts: 2},
        timeout_policy: %{hard_timeout_s: 1800},
        hitl_policy: %{gate: "none"},
        created_at: @timestamps.created,
        updated_at: @timestamps.queued_updated
      },
      %{
        id: "wk-done",
        repo_ref: "deepwatrcreatur/agent-roundtable",
        branch_ref: "main",
        source_ref: "round-89",
        title: "Ship shareable public repo reports page",
        task_type: "deployment",
        input_payload: %{},
        surface_route: "/forgejo-shell/reports",
        public_demo_id: "kubernetes",
        desired_outcome: %{result: "public reports route live"},
        status: "succeeded",
        priority: 50,
        assignee_type: "agent",
        assignee_ref: "codex-gpt54",
        workflow_ref: "wf-deploy",
        retry_policy: %{max_attempts: 1},
        timeout_policy: %{hard_timeout_s: 1200},
        hitl_policy: %{gate: "none"},
        created_at: @timestamps.created,
        updated_at: @timestamps.done_updated,
        closed_at: @timestamps.done_finished
      },
      %{
        id: "wk-closed",
        repo_ref: "deepwatrcreatur/agent-roundtable",
        branch_ref: "docs/vaglio-single-writer-lock",
        source_ref: "round-78",
        title: "Stabilize overlapping host deploy attempts",
        task_type: "ops_policy",
        input_payload: %{
          resource: "host:vaglio"
        },
        evidence_links: [
          %{label: "Open board", href: "/board", kind: "surface"}
        ],
        desired_outcome: %{result: "single-writer deploy policy"},
        status: "failed",
        priority: 60,
        assignee_type: "agent",
        assignee_ref: "codex-gpt54",
        workflow_ref: "wf-policy",
        retry_policy: %{max_attempts: 1},
        timeout_policy: %{hard_timeout_s: 900},
        hitl_policy: %{gate: "operator"},
        created_at: @timestamps.created,
        updated_at: @timestamps.failed_updated,
        closed_at: @timestamps.failed_finished
      }
    ]
  end

  defp attempts do
    [
      %{
        id: "att-gated-1",
        work_item_id: "wk-gated",
        attempt_number: 1,
        runtime_id: "runtime-vaglio-review",
        agent_id: "codex-gpt54",
        status: "running",
        lease_expires_at: @timestamps.lease_healthy,
        started_at: @timestamps.gated_started,
        summary: "Board bootstrap patch is waiting for operator approval"
      },
      %{
        id: "att-attention-1",
        work_item_id: "wk-attention",
        attempt_number: 1,
        runtime_id: "runtime-vaglio-ops",
        agent_id: "codex-gpt54",
        status: "running",
        lease_expires_at: @timestamps.lease_expired,
        started_at: @timestamps.attention_started,
        summary: "Cache warm path lost ownership during deploy churn"
      },
      %{
        id: "att-running-1",
        work_item_id: "wk-running",
        attempt_number: 1,
        runtime_id: "runtime-vaglio-main",
        agent_id: "codex-gpt54",
        status: "running",
        lease_expires_at: @timestamps.lease_healthy,
        started_at: @timestamps.running_started,
        summary: "Rendering the board surface against canonical board state"
      },
      %{
        id: "att-done-1",
        work_item_id: "wk-done",
        attempt_number: 1,
        runtime_id: "runtime-vaglio-main",
        agent_id: "codex-gpt54",
        status: "succeeded",
        lease_expires_at: nil,
        started_at: @timestamps.done_started,
        finished_at: @timestamps.done_finished,
        exit_class: "success",
        summary: "Reports page deployed and verified"
      },
      %{
        id: "att-closed-1",
        work_item_id: "wk-closed",
        attempt_number: 1,
        runtime_id: "runtime-vaglio-ops",
        agent_id: "codex-gpt54",
        status: "failed",
        lease_expires_at: nil,
        started_at: @timestamps.failed_started,
        finished_at: @timestamps.failed_finished,
        exit_class: "tool_error",
        summary: "Concurrent deploy attempts contended on the same mutable host",
        error_excerpt: "runtime wrapper state collided across agents"
      }
    ]
  end

  defp human_gates do
    [
      %{
        id: "gate-gated-1",
        work_item_id: "wk-gated",
        attempt_id: "att-gated-1",
        gate_type: "approve",
        prompt: "Promote the persistent board-repo bootstrap fix to main?",
        options: ["approve", "request changes", "hold"],
        state: "open",
        created_at: @timestamps.gate_created
      }
    ]
  end

  defp attempt_events do
    [
      %{
        id: "evt-gated-1",
        attempt_id: "att-gated-1",
        work_item_id: "wk-gated",
        event_type: "waiting_for_review",
        summary: "Operator review requested before promoting the board bootstrap change",
        metadata: %{surface: "/board", gate: "approve"},
        created_at: @timestamps.gate_created
      },
      %{
        id: "evt-attention-1",
        attempt_id: "att-attention-1",
        work_item_id: "wk-attention",
        event_type: "lease_expired",
        summary: "Public repo cache warm lane needs an operator handoff",
        metadata: %{resource_scope: "cache:public-repo-demo"},
        created_at: @timestamps.attention_updated
      },
      %{
        id: "evt-running-1",
        attempt_id: "att-running-1",
        work_item_id: "wk-running",
        event_type: "progress",
        summary: "Board cards now reflect lane projections over canonical state",
        metadata: %{surface: "/board"},
        created_at: @timestamps.running_updated
      }
    ]
  end
end

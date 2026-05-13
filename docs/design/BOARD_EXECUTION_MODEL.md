# Board Execution Model

**Status:** Drafted from Rounds 62 and 70  
**Purpose:** Define the bounded execution layer that sits between
`agent-roundtable` discussion and Vaglio memory / governance.

---

## 1. Why this exists

Round 62 established the product split:

- `agent-roundtable` for structured design discussion
- a bulletin board for execution dispatch
- Vaglio for forge, governance, and long-term memory

Round 70 refined that split by identifying what to borrow from external
orchestration tools without reopening the architecture:

- from **Multica**: agent-as-assignee board UX, live status, local daemon model
- from **Conductor**: durable execution state, retries, timeouts, replay,
  human-in-the-loop (HITL) gates, workflow-as-data

This document turns that consensus into a concrete execution model.

---

## 2. Boundary of responsibility

### `agent-roundtable`

Owns discussion, synthesis, satisfaction, and design closure.

It may emit a directive such as:

- “implement fix X on repo Y”
- “run validation on branch Z”
- “prepare benchmark for feature W”

It does **not** own the long-running execution of those tasks.

### Bulletin board

Owns:

- task intake
- assignment and dispatch
- runtime matching
- attempt lineage
- retries and timeout handling
- HITL pauses
- operator-visible execution state

It does **not** own long-term trust / governance history beyond the execution
records needed to do its job.

### Vaglio

Owns:

- persistent agent roster and capability registry
- longer-horizon provenance and trust interpretation
- governance and memory surfaces
- cross-task and cross-repo analysis

The board may read capability references from Vaglio, but should not try to
become the full memory or governance layer.

---

## 3. Core object model

The board is a hybrid surface:

- socially legible on top (issue / card / assignment view)
- structurally queryable underneath (Dolt-backed tables)

The minimum persistent execution model is five tables plus one reusable
workflow-definition table.

### 3.1 `work_items`

One row per dispatchable unit of work.

| Field | Type | Meaning |
|---|---|---|
| `id` | text | Stable work-item ID |
| `repo_ref` | text | Target repo or workspace |
| `branch_ref` | text nullable | Optional target branch / change context |
| `source_ref` | text nullable | Originating issue, round, directive, or incident |
| `title` | text | Short operator-visible summary |
| `task_type` | text | e.g. `code_change`, `review`, `benchmark`, `investigation` |
| `input_payload` | json | Structured task input |
| `desired_outcome` | json | Structured completion target |
| `status` | text | Current lifecycle state |
| `priority` | integer | Scheduling priority |
| `assignee_type` | text nullable | `agent`, `runtime`, or `human` |
| `assignee_ref` | text nullable | Chosen agent / runtime / operator |
| `workflow_ref` | text nullable | Optional workflow definition ID |
| `retry_policy` | json | Max attempts, backoff, retryable failures |
| `timeout_policy` | json | Soft / hard timeout and timeout action |
| `hitl_policy` | json nullable | Approval / escalation / review gate configuration |
| `created_at` | timestamp | Creation time |
| `updated_at` | timestamp | Last mutation |
| `closed_at` | timestamp nullable | Terminal completion time |

### 3.2 `work_attempts`

One row per concrete execution attempt.

| Field | Type | Meaning |
|---|---|---|
| `id` | text | Attempt ID |
| `work_item_id` | text | Parent work item |
| `attempt_number` | integer | Monotonic attempt count |
| `runtime_id` | text | Runtime / daemon that executed the attempt |
| `agent_id` | text | Agent profile used for the attempt |
| `status` | text | Attempt lifecycle state |
| `lease_expires_at` | timestamp nullable | Claim lease expiry |
| `started_at` | timestamp | Start time |
| `finished_at` | timestamp nullable | End time |
| `exit_class` | text nullable | `success`, `tool_error`, `timeout`, `input_error`, `cancelled`, `needs_human_gate` |
| `summary` | text nullable | Short human-readable result |
| `error_excerpt` | text nullable | Small failure digest |
| `artifact_ref` | text nullable | Logs, patch, transcript, or output bundle reference |

### 3.3 `human_gates`

Structured pause / approval objects, not ad hoc comments.

| Field | Type | Meaning |
|---|---|---|
| `id` | text | Gate ID |
| `work_item_id` | text | Related work item |
| `attempt_id` | text nullable | Attempt that triggered the gate |
| `gate_type` | text | `approve`, `clarify`, `risk_ack`, `merge_review`, `escalate` |
| `prompt` | text | Operator-visible question |
| `options` | json | Allowed structured decisions |
| `state` | text | `open`, `resolved`, `expired`, `dismissed` |
| `decision` | json nullable | Structured operator response |
| `resolved_by` | text nullable | Human actor |
| `created_at` | timestamp | Creation time |
| `resolved_at` | timestamp nullable | Decision time |

### 3.4 `runtime_heartbeats`

Board visibility for local or remote runtimes.

| Field | Type | Meaning |
|---|---|---|
| `runtime_id` | text | Stable runtime ID |
| `host_label` | text | Human-facing runtime name |
| `transport` | text | `unix_socket`, `http`, or equivalent |
| `status` | text | `idle`, `busy`, `offline`, `degraded` |
| `capabilities` | json | Agent and tool capability summary |
| `last_seen_at` | timestamp | Last heartbeat |
| `active_attempt_id` | text nullable | Attempt currently running |
| `metadata` | json | Platform / version / labels |

### 3.5 `work_attempt_events`

Append-only event log for daemon-reported progress and terminal state.

| Field | Type | Meaning |
|---|---|---|
| `id` | text | Event ID |
| `attempt_id` | text | Related attempt |
| `work_item_id` | text | Parent work item |
| `event_type` | text | `claimed`, `started`, `progress`, `warning`, `needs_human_gate`, `completed`, `failed`, `cancelled` |
| `summary` | text nullable | Compact human-readable event summary |
| `metadata_json` | json | Structured event detail |
| `created_at` | timestamp | Event timestamp |

### 3.6 `workflow_definitions`

Reusable policy bundles referenced by `work_items.workflow_ref`.

| Field | Type | Meaning |
|---|---|---|
| `id` | text | Stable workflow definition ID |
| `title` | text | Short operator-visible name |
| `description` | text nullable | Human-readable purpose |
| `task_types_json` | json | Allowed task types |
| `runtime_requirements_json` | json | Explicit runtime / profile / label / transport constraints |
| `retry_policy_json` | json nullable | Reusable retry policy defaults |
| `timeout_policy_json` | json nullable | Reusable timeout policy defaults |
| `hitl_policy_json` | json nullable | Reusable human-gate defaults |
| `resume_policy_json` | json nullable | Reusable post-approval resume defaults |
| `created_at` | timestamp | Creation time |
| `updated_at` | timestamp | Last mutation |

---

## 4. Work-item lifecycle

The board state machine should be explicit.

```text
queued
  -> claimed
  -> running
  -> awaiting_human_input
  -> resumable
  -> retry_scheduled
  -> succeeded | failed | cancelled
```

### State meanings

- `queued` — waiting for a compatible runtime / agent
- `claimed` — reserved by a runtime with a lease but not yet started
- `running` — active attempt in progress
- `awaiting_human_input` — blocked on a structured human gate
- `resumable` — gate resolved, ready for a new or resumed attempt
- `retry_scheduled` — transient failure accepted by policy; next attempt pending
- `succeeded` — completion criteria met
- `failed` — terminal failure after retries or non-retryable error
- `cancelled` — aborted by operator or upstream invalidation

The board should treat `work_attempts` as append-only lineage and
`work_items.status` as the current summary view.

---

## 5. Retry, timeout, and replay policy

These are first-class from v1, not bolt-ons.

### Retry policy

Minimum shape:

```json
{
  "max_attempts": 3,
  "backoff": "exponential",
  "retry_on": ["tool_error", "runtime_disconnect", "timeout"],
  "do_not_retry_on": ["input_error", "policy_denied"]
}
```

### Timeout policy

Minimum shape:

```json
{
  "soft_timeout_s": 900,
  "hard_timeout_s": 1800,
  "on_soft_timeout": "warn",
  "on_hard_timeout": "fail_attempt"
}
```

### Replay rule

Replay means:

- preserve prior attempt records
- create a new attempt row
- keep the work item linked to the same source directive
- make the reason for retry operator-visible

Replay does **not** mean mutating history to hide earlier failure.

---

## 6. Human-in-the-loop gates

HITL is a first-class board primitive.

The board should open a `human_gates` row when:

- risk exceeds policy
- input is ambiguous
- a merge / promotion needs explicit approval
- the agent requests clarification
- automated repair would exceed the allowed scope

The gate must be structured enough for a daemon or orchestrator to resume
without reparsing unstructured comments.

Example:

```json
{
  "gate_type": "approve",
  "prompt": "Patch updates DHCP logic and standby gating. Promote to validation branch?",
  "options": ["approve", "reject", "request_changes"],
  "context": {
    "work_item_id": "wk_123",
    "attempt_id": "att_3"
  }
}
```

---

## 7. Dispatch rules

### Matching

The board assigns work by matching:

- required capability tags
- compatible runtime transport
- repo / workspace access
- policy constraints
- current runtime availability

### Assignment surface

Operator-facing cards should show at least:

- title
- repo / branch context
- current status
- current assignee
- latest attempt summary
- whether the item is waiting on human input

### Non-goal

The board should not try to infer hidden “best agent” judgments from opaque
global scores. Runtime / capability matching should remain explicit and
inspectable.

---

## 8. Relationship to local daemon execution

The board does not execute subscription-backed CLIs server-side.

Instead:

- local daemons advertise capabilities
- the board offers or leases work to them
- daemons run the actual `codex`, `gemini`, `copilot`, `claude`, or `opencode`
  processes
- daemons report progress and terminal state back to the board

This preserves multi-provider freedom and avoids a central-service design that
conflicts with local subscriptions.

See also: `docs/design/LOCAL_DAEMON_CONTRACT.md`.

---

## 9. Explicit non-goals

The board is **not**:

- a replacement for `agent-roundtable`
- a generic Conductor clone
- a hosted Multica clone
- the long-term memory / governance plane
- a hidden trust-score system

It is the bounded execution layer that turns directives into durable,
observable work.

---

## 10. Immediate implementation implications

This model should drive:

1. a Dolt schema for `work_items`, `work_attempts`, `human_gates`,
   `runtime_heartbeats`, and `work_attempt_events`
2. a TUI / board view that surfaces assignment, status, and gate state
3. a daemon contract for local CLI runners
4. a lightweight workflow-definition layer that attaches retry / timeout / gate
   policy to a work item without dragging in a full workflow engine

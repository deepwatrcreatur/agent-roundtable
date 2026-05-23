# Board Kanban Read Model

**Status:** Drafted from Round 121  
**Purpose:** Define the derived read/query layer that turns canonical board
execution state into stable kanban lanes, machine-readable badges, and compact
card summaries for a browse-first operator surface.

---

## 1. Boundary

The kanban board is a read model, not a source of truth.

Canonical execution truth remains in:

- `work_items`
- `work_attempts`
- `work_attempt_events`
- `human_gates`
- `runtime_heartbeats`

The board read model should:

- derive current lane placement
- summarize operator-relevant state
- expose machine-readable badges and stuck conditions
- preserve historical lineage rather than collapsing it away

---

## 2. Why a read model is necessary

Raw execution tables are structurally correct but not operator-friendly.

Operators need to answer quickly:

- what is running now
- what is blocked on a human
- what looks stale
- which runtime owns the current attempt
- which attempt superseded another
- what just finished and whether it is safe to ignore or needs attention

Those answers should not require hand-reading attempt event logs or composing
joins in UI templates.

---

## 3. Design principle

Lane placement and card badges should be derived by explicit rules, not
implicitly encoded inside a LiveView or ad hoc SQL snippets.

That means the board should expose:

- a deterministic lane assignment
- a deterministic card summary projection
- explicit alert/stuck reasons
- explicit badge generation rules

The UI then renders the read model rather than inventing state.

---

## 4. Read-model outputs

The minimum read model should produce two outputs.

### 4.1 Lane index

A grouped view of work items by current kanban lane.

### 4.2 Card projection

A compact per-work-item summary containing the fields operators need at a
glance.

---

## 5. Recommended kanban lanes

The lane model should remain small and operator-legible.

### 5.1 `queued`

Work ready for claim or waiting on runtime matching.

Includes:

- `work_items.status = queued`
- `retry_scheduled` items whose backoff has matured and can re-enter dispatch

### 5.2 `running`

Work with an active current attempt and live ownership.

Includes:

- `claimed`
- `running`

when the current attempt has not gone stale or been superseded.

### 5.3 `gated`

Work blocked on explicit human or policy input.

Includes:

- `awaiting_human_input`
- open `human_gates`
- attempts whose latest meaningful event is `needs_human_gate`

### 5.4 `attention`

Work not terminal, but requiring operator review because it appears unhealthy.

Includes conditions such as:

- stale lease
- missing runtime heartbeat
- runtime degraded/offline while owning an active attempt
- repeated warnings without terminal resolution
- unresolved conflict between item status and attempt state

### 5.5 `done`

Terminal work that completed successfully or was cancelled benignly.

Includes:

- `succeeded`
- terminal `cancelled` where no human follow-up is required

### 5.6 `closed_with_issue`

Terminal work that should remain visible for operator follow-up.

Includes:

- `failed`
- terminal cancelled work needing review
- superseded work where the supersession itself is the important current fact

The exact lane names may change in UI copy, but the semantic distinctions
should remain stable.

---

## 6. Lane derivation rules

Lane placement should be computed in priority order so one item lands in one
current lane.

Recommended priority:

1. `gated`
2. `attention`
3. `running`
4. `queued`
5. `closed_with_issue`
6. `done`

This priority keeps “needs a human now” above “still technically running.”

### 6.1 Example derivation logic

Given a work item and its current attempt/gate/runtime context:

- if an open gate exists, place in `gated`
- else if stale or contradictory state exists, place in `attention`
- else if current item/attempt state is active, place in `running`
- else if dispatchable, place in `queued`
- else if terminal and unhealthy, place in `closed_with_issue`
- else if terminal and healthy, place in `done`

---

## 7. Current attempt selection

The read model must define one current attempt per work item for summary
purposes without destroying lineage.

Recommended rule:

- choose the highest `attempt_number`
- if multiple rows compete, prefer the most recently started non-superseded
  attempt
- if the latest attempt is explicitly superseded, retain it in lineage but mark
  the replacing attempt as current

This rule should be encoded centrally so the UI does not guess.

---

## 8. Card projection shape

Each work item should project to a single compact card shape.

Minimum fields:

| Field | Meaning |
|---|---|
| `work_item_id` | Stable card/work item ID |
| `lane` | Derived current lane |
| `title` | Operator-facing summary |
| `repo_ref` | Repo or workspace anchor |
| `branch_ref` | Optional branch/change context |
| `task_type` | Task category |
| `priority` | Scheduling priority |
| `status` | Canonical current item status |
| `current_attempt_ref` | Current attempt ID if any |
| `attempt_number` | Current attempt ordinal |
| `attempt_status` | Current attempt status |
| `runtime_ref` | Owning runtime if any |
| `runtime_status` | `idle`, `busy`, `offline`, `degraded`, or `unknown` |
| `open_gate_ref` | Current gate if any |
| `gate_type` | Type of gate if present |
| `lease_state` | `healthy`, `stale`, `expired`, `missing`, or `not_required` |
| `superseded_by_attempt_ref` | Replacement attempt if current one was superseded |
| `summary` | Compact human-readable state summary |
| `badge_refs` | Structured badge list |
| `alert_refs` | Structured alerts/stuck reasons |
| `updated_at` | Most relevant freshness timestamp |

---

## 9. Badge model

Badges should be machine-readable first and human-rendered second.

Recommended badge classes:

- `priority:high`
- `task:code_change`
- `runtime:offline`
- `gate:approve`
- `lease:stale`
- `attempt:superseded`
- `retry:scheduled`
- `result:failed`
- `result:succeeded`

Badges should be additive and not replace lane assignment.

---

## 10. Alert / stuck-reason model

The read model should explicitly surface why something deserves attention.

Recommended alert codes:

- `stale_lease`
- `runtime_offline`
- `runtime_degraded`
- `open_human_gate`
- `awaiting_review`
- `attempt_superseded`
- `retry_backoff_active`
- `status_conflict`
- `missing_heartbeat`
- `terminal_failure`

Each alert should carry:

- a stable code
- compact summary text
- severity
- timestamp or freshness reference

This keeps the UI from turning operational reasoning into prose-only guesswork.

---

## 11. Derived health rules

The board should derive several health fields rather than forcing every caller
to recompute them.

### 11.1 Lease health

Possible values:

- `healthy`
- `stale`
- `expired`
- `missing`
- `not_required`

### 11.2 Runtime health

Possible values:

- `online`
- `busy`
- `degraded`
- `offline`
- `unknown`

### 11.3 Item freshness

Should derive from the newest relevant event among:

- work item update
- current attempt event
- gate state change
- runtime heartbeat

---

## 12. Historical lineage visibility

The read model should summarize the current state without discarding history.

Each card should expose compact lineage hints such as:

- current attempt number
- prior attempt count
- superseded-by relationship
- most recent terminal outcome

Detailed history may live behind drill-down, but the summary should make it
obvious that the board is backed by lineage rather than in-place mutation.

---

## 13. Recommended materialization strategy

The first implementation can be a deterministic query/projection layer rather
than a fully separate stored table.

Recommended phases:

### Phase 1

- derive lanes/cards directly from canonical tables
- publish a stable schema for the projection

### Phase 2

- optionally materialize cached read rows for performance
- keep them explicitly rebuildable from canonical state

This preserves correctness while avoiding premature duplication of truth.

---

## 14. Relationship to adjacent contracts

This read model depends on:

- `BOARD_EXECUTION_MODEL.md`
- `LOCAL_DAEMON_CONTRACT.md`
- `CONTROLLED_EXECUTOR_CONTRACT.md`

Those documents define the authoritative execution semantics.
This document defines how to browse them safely and consistently.

---

## 15. Non-goals

This read model does not attempt to:

- replace canonical execution tables
- define the full browse UI
- hide all history behind a single status string
- become an analytics warehouse

Its job is narrower:

- give the board a stable kanban projection
- expose operator-relevant state without raw table spelunking
- keep lane placement, badges, and alerts machine-readable

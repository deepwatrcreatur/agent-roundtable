# 96 — Board Kanban Read Model

**Status:** `ready`
**Tag:** `[structural]`

## Goal

Define and implement the read/query layer that turns board execution state into
a stable kanban-style operator surface, so the board can become the primary
human-facing control-plane view rather than a thin debug wrapper around raw
tables.

## Scope

- Define the derived board views needed for human browsing, including:
  - queued work
  - running work
  - blocked or gated work
  - completed / failed / superseded work
- Specify the card summary fields that should be visible without drilling into
  raw attempt logs.
- Derive current board state from canonical tables such as:
  - `work_items`
  - `work_attempts`
  - `work_attempt_events`
  - `human_gates`
  - `runtime_heartbeats`
- Make current lane placement and badge state machine-readable rather than
  encoded only in LiveView templates.
- Include the operator questions that matter immediately:
  - what is running
  - what is stuck
  - what needs human approval
  - which runtime owns the work
  - which attempt superseded another

## Acceptance Criteria

- A concrete board read model exists for kanban lanes and card summaries.
- Current board state can be produced without mutating away historical lineage.
- Human gates, stale leases, runtime liveness, and superseded attempts appear as
  first-class board state rather than buried detail.
- The result is directly usable by a browse-first UI and does not require a
  human to read raw database rows.

## Notes

- Primary design sources:
  - `docs/design/BOARD_EXECUTION_MODEL.md`
  - `docs/design/LOCAL_DAEMON_CONTRACT.md`
  - `docs/design/rounds/round-121-control-plane-orchestration-vs-execution-providers.md`
- Closely related work:
  - `73-board-work-item-schema.md`
  - `74-local-daemon-lease-contract.md`
  - `75-lightweight-workflow-definitions.md`
  - `79-derived-round-index-and-resource-claims.md`
  - `91-maintainer-activity-and-promotion-surface.md`

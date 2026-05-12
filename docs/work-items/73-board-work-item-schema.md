# 73 — Bulletin Board Work-Item Schema & Dolt Tables

**Status:** `done` — **GitHub Copilot**
**Tag:** `[structural]`

## Goal
Implement the concrete bulletin-board persistence model described in
`docs/design/BOARD_EXECUTION_MODEL.md`.

## Scope
- Define Dolt-backed tables for:
  - `work_items`
  - `work_attempts`
  - `human_gates`
  - `runtime_heartbeats`
- Make retry policy, timeout policy, and HITL gates first-class structured data,
  not opaque blobs hidden in comments.
- Preserve append-only attempt lineage instead of mutating away failed attempts.
- Keep the board layer distinct from Vaglio's longer-term capability / trust
  registry.

## Acceptance Criteria
- The schema can represent a queued task, multiple attempts, and a structured
  human gate without lossy ad hoc fields.
- A work item's current status can be computed without destroying historical
  attempt lineage.
- Retry / timeout policy is stored in a machine-readable way that later runtime
  code can consume directly.
- Documentation or migration notes make the boundary between board state and
  Vaglio memory explicit.

## Outcome
- Added Dolt migration `roundtable/priv/dolt/migrations/20260512_add_board_execution_schema.sql`
  defining:
  - `work_items`
  - `work_attempts`
  - `human_gates`
  - `runtime_heartbeats`
- Added `Roundtable.Board`, a focused Dolt-backed persistence module that:
  - ensures schema presence
  - creates work items
  - appends attempts
  - records human gates
  - upserts runtime heartbeats
  - lists and decodes board rows back into Elixir maps
- Added focused tests covering schema creation, machine-readable policy fields,
  retry lineage, and structured human-gate / heartbeat views.

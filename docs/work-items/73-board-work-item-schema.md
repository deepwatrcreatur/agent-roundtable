# 73 — Bulletin Board Work-Item Schema & Dolt Tables

**Status:** `ready`
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

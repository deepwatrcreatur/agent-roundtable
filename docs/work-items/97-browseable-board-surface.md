# 97 — Browseable Board Surface

**Status:** `done` — **Codex**
**Tag:** `[product]`

## Goal

Ship the first browseable board surface so an operator can open Vaglio/board and
see useful kanban state soon, even before the full control-plane product is
complete.

## Scope

- Build a read-first UI for the board that shows:
  - kanban columns / lanes
  - work-item cards
  - current assignee/runtime
  - attempt status
  - human-gate state
  - recent event / heartbeat summary
- Prefer browseability and legibility first:
  - clear board overview
  - card detail drill-down
  - filters for repo, status, runtime, and gate state
- Reuse the existing Phoenix/Web surface where possible instead of creating an
  unrelated second dashboard.
- Keep mutation narrow for the first slice:
  - claim/dispatch visibility first
  - gate acknowledgement or operator notes only if already supported by the
    underlying model
- Make it obvious which state is authoritative board state versus derived
  convenience presentation.

## Acceptance Criteria

- A human can browse current board state without inspecting raw Dolt tables or
  logs directly.
- The UI clearly exposes running, queued, blocked, and human-gated work.
- An operator can open a work item and understand its latest attempt, runtime,
  and recent execution history.
- The implementation reuses existing dashboard infrastructure where practical
  and aligns with the board read model instead of inventing ad hoc UI state.

## Notes

- Primary design sources:
  - `docs/design/BOARD_EXECUTION_MODEL.md`
  - `docs/design/rounds/round-121-control-plane-orchestration-vs-execution-providers.md`
- Closely related work:
  - `10-web-dashboard.md`
  - `57-agent-task-queue.md`
  - `73-board-work-item-schema.md`
  - `96-board-kanban-read-model.md`

## Outcome

- Added a real browse-first `/board` LiveView using the existing Phoenix web
  surface instead of creating a separate dashboard.
- Implemented
  [Roundtable.BoardKanbanReadModel](../../roundtable/lib/roundtable/board_kanban_read_model.ex)
  to derive current lanes, card summaries, alerts, and detail state from
  canonical board tables.
- Added card drill-down, read-only filters, runtime/gate visibility, and recent
  attempt-event summaries so operators can browse board state without reading
  raw rows or logs.
- Linked the landing page to the new board surface and added focused tests for
  both the read model and the LiveView.

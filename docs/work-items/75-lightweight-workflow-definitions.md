# 75 — Lightweight Workflow Definitions for Board Tasks

**Status:** `ready`
**Tag:** `[structural]`

## Goal
Add a minimal workflow-as-data layer for board execution without turning the
project into a generic Conductor clone.

## Scope
- Define a small declarative format for work-item policy:
  - retry policy
  - timeout policy
  - optional human-review gates
  - resumable transitions after approval / clarification
- Keep the definition small enough to live comfortably in the Elixir / Dolt
  stack and avoid a heavyweight external engine.
- Support both direct board-created tasks and directives emitted from
  `agent-roundtable`.
- Ensure workflow definitions reference runtimes / capabilities explicitly,
  without hidden agent scoring.

## Acceptance Criteria
- A single work item can reference a reusable workflow definition or inline
  policy block.
- Human-review gates and retry / timeout behavior are expressible as data.
- The workflow format is narrow enough to explain in one implementation doc and
  does not require adopting an external workflow runtime.
- The result clearly complements items 57, 73, and 74 instead of duplicating
  them.

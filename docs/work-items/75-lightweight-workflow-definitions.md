# 75 — Lightweight Workflow Definitions for Board Tasks

**Status:** `done`
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

## Outcome
- Added Dolt migration `20260512_add_workflow_definitions.sql` for reusable
  workflow policy bundles.
- Added `Roundtable.WorkflowDefinitions` with schema setup, CRUD-style
  persistence, work-item policy resolution, and runtime requirement checks.
- Integrated workflow resolution into `Roundtable.LocalDaemon` polling and
  failure handling so runtime/profile matching and retry defaults can come from
  `workflow_ref`.
- Added focused tests for workflow-definition persistence, overlay behavior, and
  daemon workflow gating.

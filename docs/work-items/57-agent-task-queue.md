# 57 — Autonomous Agent Task Delegation System

**Status:** `done` — **Owner:** `Codex`
**Tag:** `[structural]`

## Goal

Implement a structured task queue that can be driven by the TUI and OpenCode server without human-in-the-loop turn-taking.

## Scope

- Define the `Task` schema (ID, Repo, Branch, Agent, Status, ErrorLog).
- Implement a `Dolt` table or a `jj`-managed `TASKS.md` for the queue.
- Build the "Task Watcher" logic for the TUI: automatically assign idle local agents to the next task.
- Implement the "Rewind" protocol: failed tasks (e.g. merge conflicts) automatically undo `jj` operations and report to the TUI.
- Refine implementation against the concrete specs in:
  - `docs/design/BOARD_EXECUTION_MODEL.md`
  - `docs/design/LOCAL_DAEMON_CONTRACT.md`
- Treat this item as the umbrella for the more specific follow-on items 73–75.

## Acceptance Criteria

- Tasks can be added to the queue via the TUI.
- Agents work on tasks autonomously until completion or explicit failure.
- No more "Stuck in Bash" failures due to interactive editors.

## Notes

- Primary design sources:
  - `docs/design/BOARD_EXECUTION_MODEL.md`
  - `docs/design/LOCAL_DAEMON_CONTRACT.md`
  - `docs/design/CONTROLLED_EXECUTOR_CONTRACT.md`
- Closely related work:
  - `73-board-work-item-schema.md`
  - `74-local-daemon-lease-contract.md`
  - `75-lightweight-workflow-definitions.md`
  - `95-buildkite-compatible-controlled-executor.md`
  - `96-board-kanban-read-model.md`
  - `97-browseable-board-surface.md`

## Outcome

- Added
  [docs/design/AUTONOMOUS_AGENT_TASK_QUEUE.md](../design/AUTONOMOUS_AGENT_TASK_QUEUE.md)
  as the umbrella synthesis note for the autonomous queue model.
- Bound the original item’s broad "task watcher" concept to the now-landed
  concrete slices:
  - board work-item schema
  - local daemon lease/event contract
  - workflow-as-data policy
  - controlled executor/provider boundary
  - browseable board surface
- Reframed "rewind" as append-only attempt lineage plus structured failure and
  requeue policy, rather than destructive undo.
- Clarified that the remaining future work is refinement of runtime matching and
  operator flows, not invention of the queue model from scratch.

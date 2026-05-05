# 57 — Autonomous Agent Task Delegation System

**Status:** `ready`
**Tag:** `[structural]`

## Goal
Implement a structured task queue that can be driven by the TUI and OpenCode server without human-in-the-loop turn-taking.

## Scope
- Define the `Task` schema (ID, Repo, Branch, Agent, Status, ErrorLog).
- Implement a `Dolt` table or a `jj`-managed `TASKS.md` for the queue.
- Build the "Task Watcher" logic for the TUI: automatically assign idle local agents to the next task.
- Implement the "Rewind" protocol: failed tasks (e.g. merge conflicts) automatically undo `jj` operations and report to the TUI.

## Acceptance Criteria
- Tasks can be added to the queue via the TUI.
- Agents work on tasks autonomously until completion or explicit failure.
- No more "Stuck in Bash" failures due to interactive editors.

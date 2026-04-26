# Implementation Work Items

Each file is one unit of work. Claim a `ready` item by changing its status to
`in-progress` and committing before starting. Do not start a `blocked` item.
Do not work on an item already marked `in-progress` by another agent.

## Status model

- `ready` — can start now
- `in-progress` — owned; check the file for the owning agent/branch
- `blocked` — depends on another item; listed in the file
- `done` — merged; kept briefly for outcome notes

## Queue

### Foundation (do first, in order)

1. [`01-mix-scaffold.md`](./01-mix-scaffold.md) — `ready` — **Codex**
2. [`02-gh-actions.md`](./02-gh-actions.md) — `ready` — **Gemini**
3. [`03-cli-agent-action.md`](./03-cli-agent-action.md) — `blocked` (needs 01)
4. [`04-satisfaction.md`](./04-satisfaction.md) — `blocked` (needs 01)
5. [`05-prompt.md`](./05-prompt.md) — `blocked` (needs 01, 02, 03)
6. [`06-orchestrator.md`](./06-orchestrator.md) — `blocked` (needs 01–05)
7. [`07-cli-entrypoint.md`](./07-cli-entrypoint.md) — `blocked` (needs 06)
8. [`08-flake.md`](./08-flake.md) — `blocked` (needs 01)

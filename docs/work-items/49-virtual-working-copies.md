# 49 — Virtual Working Copies (jj)

**Status:** `ready`
**Tag:** `[structural]`

## Goal
Implement a system for managing concurrent agent edits without file locks or heavy worktrees.

## Scope
- Leverage `jj` named working copies for each active agent.
- Implement a "Conflict Collector" that ingest `jj` conflict states into the Vaglio Sieve.
- Automate the resolution of "Silent Conflicts" (where code builds but invariants fail) via the Vouch-Protocol.

## Acceptance Criteria
- Agents can work in parallel on the same subtree without stalling.
- Conflicts are visible in the Vaglio WebUI as "Structural Stress" points.

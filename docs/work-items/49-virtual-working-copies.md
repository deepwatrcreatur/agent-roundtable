# 49 — Virtual Working Copies (jj)

**Status:** `done` — **Owner:** `Codex`
**Tag:** `[structural]`

## Goal

Implement a system for managing concurrent agent edits without file locks or
heavy worktrees.

## Scope

- Leverage `jj` named working copies for each active agent.
- Implement a "Conflict Collector" that ingests `jj` conflict states into the Vaglio Sieve.
- Automate the resolution of "Silent Conflicts" (where code builds but invariants fail) via the Vouch-Protocol.

## Acceptance Criteria

- Agents can work in parallel on the same subtree without stalling.
- Conflicts are visible in the Vaglio WebUI as "Structural Stress" points.

## Notes

- Primary design sources:
  - `docs/design/rounds/historical-synthesis.md`
  - `docs/design/rounds/round-134-vfs-virtual-working-copies-vs-dmux-wrapper.md`
- Closely related work:
  - `74-local-daemon-lease-contract.md`
  - `89-forge-claim-and-lease-protocol.md`
  - `96-board-kanban-read-model.md`
  - `97-browseable-board-surface.md`

## Outcome

- Added
  [docs/design/JJ_VIRTUAL_WORKING_COPIES.md](../design/JJ_VIRTUAL_WORKING_COPIES.md)
  as the isolated-mutation workspace contract note.
- Defined `VirtualWorkingCopy` as a first-class execution object attached to
  claim/attempt lineage rather than an implementation detail hidden inside the
  runtime.
- Specified a conflict collector with explicit conflict classes including
  `silent_invariant` and `rebase_overlap`.
- Clarified that reservations remain advisory scheduling hints, while private
  mutation namespaces are the actual correctness boundary.
- Kept the local implementation path compatible with today’s wrapper-first
  isolated workspaces while preserving a future mapping to mature `jj` named
  working copies.

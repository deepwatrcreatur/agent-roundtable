# 99 — Btrfs Workspace Backend and `dmux` Wiring

**Status:** `blocked`
**Blocked on:** `98-workspace-backend-capability-contract.md`
**Tag:** `[tools]`

## Goal

Implement the first real workspace backend on Linux using Btrfs subvolumes and
wire it into the `dmux`-wrapper path as the strongest local backend.

## Scope

- Implement a Btrfs backend that satisfies the workspace-backend contract.
- Support:
  - workspace create
  - path resolution
  - snapshot
  - writable clone
  - destroy / cleanup
  - usage and quota inspection where available
- Define how the wrapper probes for Btrfs support and degrades cleanly when it
  is unavailable.
- Keep higher-order claim / lease policy above the backend implementation.
- Add operator-facing diagnostics so it is obvious which backend was selected and
  which capabilities are active.

## Acceptance Criteria

- A Linux host with Btrfs can create isolated mutable workspaces through the
  wrapper using the new backend.
- Snapshot, clone, and cleanup operations are available through the contract.
- Backend selection is visible to the operator instead of silently hidden.
- When Btrfs is unavailable, the wrapper falls back cleanly instead of failing
  with backend-specific assumptions.

## Notes

- Primary design sources:
  - `docs/design/rounds/round-131-dmux-btrfs-subvolumes-vs-wrapper.md`
  - `docs/design/rounds/round-136-cross-platform-workspace-backends-beyond-btrfs.md`
- Closely related work:
  - `54-dmux-vaglio-tui.md`
  - `74-local-daemon-lease-contract.md`

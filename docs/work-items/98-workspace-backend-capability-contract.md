# 98 — Workspace Backend Capability Contract

**Status:** `ready`
**Tag:** `[structural]`

## Goal

Define the narrow backend contract that lets the `dmux`-adjacent local workspace
tooling use Btrfs, APFS, ZFS, or simpler fallbacks without hard-coding Btrfs as
the abstraction.

## Scope

- Define the canonical workspace-backend object model:
  - workspace handle
  - backend kind
  - capability advertisement
  - usage / quota metadata
- Define the minimum required operations:
  - `probe`
  - `create`
  - `destroy`
  - `path`
  - `stat`
- Define the optional capability-gated operations:
  - `snapshot`
  - `restore`
  - `clone`
  - `setQuota`
  - `setReserve`
  - `list`
  - `gc`
- Distinguish:
  - baseline portable contract
  - optional acceleration / convenience features
  - backend-specific details that must not leak into the scheduler contract
- Keep claim / lease / orchestration policy out of the backend layer.

## Acceptance Criteria

- A concrete design note exists for the workspace-backend contract and capability
  model.
- The design explicitly supports:
  - Btrfs-backed Linux workspaces
  - APFS-backed macOS workspaces
  - ZFS-backed workspaces where available
  - plain-copy / reflink-style fallback modes
- The contract clearly separates required operations from optional capabilities.
- The design shows how the `dmux` wrapper can select or probe a backend without
  embedding backend-specific policy into higher layers.

## Notes

- Primary design sources:
  - `docs/design/rounds/round-131-dmux-btrfs-subvolumes-vs-wrapper.md`
  - `docs/design/rounds/round-135-greenfield-worktree-btrfs-vs-dmux-efficient-frontier.md`
  - `docs/design/rounds/round-136-cross-platform-workspace-backends-beyond-btrfs.md`
- Closely related work:
  - `74-local-daemon-lease-contract.md`
  - `89-forge-claim-and-lease-protocol.md`
  - `93-backend-adapter-and-performance-tier-contract.md`

# 101 — ZFS Workspace Backend and Capability-Parity Check

**Status:** `blocked`
**Blocked on:** `98-workspace-backend-capability-contract.md`
**Tag:** `[hosting]`

## Goal

Use ZFS as the serious second backend that proves the workspace abstraction is
about lifecycle capabilities rather than Btrfs-only naming or implementation
details.

## Scope

- Implement or spike a ZFS backend using datasets, snapshots, clones, and
  quotas.
- Validate that the common contract maps cleanly to ZFS semantics without
  backend leakage into higher layers.
- Compare the capability surface and operator ergonomics against:
  - Btrfs backend
  - APFS backend
  - fallback copy / reflink modes
- Document which capabilities are truly portable and which remain backend-local
  optimizations.

## Acceptance Criteria

- A concrete ZFS backend or implementation-backed spike exists.
- The project has a clear parity matrix for Btrfs, ZFS, APFS, and fallback
  modes.
- The comparison identifies any contract changes needed to support ZFS cleanly
  without regressing the Btrfs or APFS designs.
- The result strengthens the backend abstraction rather than turning ZFS-specific
  behavior into canonical policy.

## Notes

- Primary design sources:
  - `docs/design/rounds/round-136-cross-platform-workspace-backends-beyond-btrfs.md`
- Closely related work:
  - `93-backend-adapter-and-performance-tier-contract.md`
  - `98-workspace-backend-capability-contract.md`

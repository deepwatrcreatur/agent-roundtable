# 100 — APFS Workspace Backend and macOS Degraded Modes

**Status:** `done` — **Owner:** `Codex`
**Tag:** `[tools]`

## Goal

Implement the real macOS path for isolated mutable workspaces using APFS as a
first serious backend, while making degraded clone/copy modes explicit rather
than hand-waving them as equivalent.

## Scope

- Implement an APFS workspace backend that satisfies the common contract.
- Prefer a stronger mode based on APFS volume-backed workspaces.
- Define and implement a lighter degraded mode using APFS clonefile / tree-clone
  behavior when full volume-backed lifecycle control is too heavy or
  unavailable.
- Record capability differences honestly:
  - snapshot support
  - quota / reserve support
  - fast clone support
  - cleanup / destroy semantics
- Include operator-visible backend and capability reporting.

## Acceptance Criteria

- A macOS host on APFS can create isolated workspaces through the same backend
  contract used on Linux.
- The implementation explicitly distinguishes strong APFS volume-backed mode from
  lighter clone/copy mode.
- The wrapper does not pretend APFS is a subvolume system, but still exposes a
  real usable backend.
- The selected mode and available capabilities are visible in diagnostics and
  tests.

## Notes

- Primary design sources:
  - `docs/design/rounds/round-136-cross-platform-workspace-backends-beyond-btrfs.md`
- Closely related work:
  - `98-workspace-backend-capability-contract.md`
  - `99-btrfs-workspace-backend-and-dmux-wiring.md`

## Outcome

- Added
  [docs/design/APFS_BACKEND_AND_MACOS_DEGRADED_MODES.md](../design/APFS_BACKEND_AND_MACOS_DEGRADED_MODES.md)
  as the maintained macOS backend note.
- Defined:
  - strong `apfs_volume` mode
  - degraded `apfs_clone` mode
  - explicit capability and diagnostic differences between them
- Kept APFS as a real first serious macOS backend while avoiding false claims of
  parity with Btrfs subvolume semantics.

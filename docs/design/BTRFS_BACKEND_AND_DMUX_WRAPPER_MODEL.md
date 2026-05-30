# Btrfs Backend and `dmux` Wrapper Model

**Status:** Maintained

## Purpose

Define the first serious Linux workspace backend implementation model beneath the
`dmux` wrapper path using Btrfs subvolumes.

This note turns the earlier "should we fork `dmux` for Btrfs?" debate into the
current maintained line:

- keep the wrapper path primary
- use Btrfs as the strongest first Linux backend
- add only the narrowest lifecycle helpers needed around upstream `dmux`

## Maintained line

The first real backend should be:

- Btrfs-backed on Linux where available
- selected through the workspace-backend capability contract
- surfaced through a wrapper around upstream `dmux`
- explicitly degradable to weaker backends when Btrfs is unavailable

The project should not treat Btrfs as the abstraction itself, but it should
treat Btrfs as the strongest first Linux implementation of that abstraction.

## Why Btrfs first

Btrfs is the best current Linux fit because it can provide:

- isolated mutable roots via subvolumes
- cheap snapshots
- writable clones through snapshot/subvolume lifecycle
- cleaner destroy and cleanup semantics
- quota support where qgroups are available

This gives the wrapper real rollback and cleanup leverage instead of only
disposable directory copies.

## Boundary

### What the Btrfs backend owns

- subvolume-backed workspace creation
- path and subvolume-handle resolution
- snapshot and writable clone operations
- destroy / cleanup semantics
- quota-aware usage reporting when available

### What remains above it

- shared-checkout read-mostly policy
- preflight guardrails
- claim and lease semantics
- board or daemon orchestration authority
- pane/session UI behavior

The backend strengthens isolation and lifecycle. It does not replace the higher
coordination layers.

## Wrapper-first integration

The project should stay wrapper-first on upstream `dmux`.

That means the wrapper is responsible for:

1. probing backend capabilities
2. selecting `btrfs` when available
3. creating the workspace through the backend
4. launching or attaching the `dmux` session against that path
5. exposing operator-visible cleanup and rollback commands

The wrapper may later gain a tiny sidecar for lease/lifecycle state if the
`dmux` seam proves too weak, but that is an escalation path, not the first
move.

## Expected Btrfs-backed operations

The Btrfs backend should satisfy the common contract with this stronger mapping:

| Contract op | Btrfs mapping |
|---|---|
| `probe()` | detect Btrfs mount, required tools, qgroup support |
| `create()` | create new workspace subvolume |
| `destroy()` | delete workspace subvolume and managed snapshots |
| `path()` | resolve mounted workspace path |
| `stat()` | report usage, creation time, quota metadata when available |
| `snapshot()` | create named Btrfs snapshot |
| `clone()` | create writable workspace from snapshot or seed |
| `set_quota()` | configure qgroup quota when available |

## Seed and clone model

The practical workspace shape should be:

- shared checkout remains read-mostly or sync-only
- wrapper materializes isolated mutable workspace by default
- Btrfs backend may optionally maintain a shared read-only seed for faster
  writable clone creation

This preserves the important policy line from the earlier rounds:

- the shared checkout should not be the default mutation surface

## Fallback behavior

When Btrfs is unavailable, the wrapper should degrade cleanly rather than fail
or silently assume the same semantics exist.

Expected fallback order on Linux:

1. `btrfs`
2. `zfs` if that is the actual host substrate
3. `reflink`
4. `copy`

The wrapper should always report which backend was chosen and why a stronger one
was not used.

## Operator-visible diagnostics

The operator should be able to inspect:

- selected backend
- active capability set
- workspace root path
- whether snapshots and writable clones are available
- whether quota support is active
- cleanup / destroy status

This should be visible through wrapper commands rather than hidden in shell
debugging.

## Cleanup and rollback model

Btrfs is especially valuable here because it enables:

- snapshot-on-create or snapshot-before-risky-step
- faster rollback after a bad local mutation
- cleaner destroy of abandoned workspaces
- lower cleanup debt than unmanaged directory trees

But these should still be explicit wrapper actions, not silent magic.

## Non-goals

This model does **not** imply:

- a `dmux` fork is required now
- Btrfs-only naming should leak into higher contracts
- leases or live-host mutation locks should move into filesystem code
- other backends are second-class forever

It is the first concrete Linux implementation path, not the only future path.

## Relationship to nearby work

This note depends on:

- `docs/design/WORKSPACE_BACKEND_CAPABILITY_CONTRACT.md`

It directly unblocks:

- `100-apfs-workspace-backend-and-macos-degraded-modes.md`
- `101-zfs-workspace-backend-and-capability-parity-check.md`

It also composes with:

- `docs/design/DMUX_VAGLIO_TUI_CONTRACT.md`
- `docs/design/JJ_VIRTUAL_WORKING_COPIES.md`
- `docs/design/FORGE_CLAIM_LEASE_PROTOCOL.md`

## Practical verdict

The maintained deliverable is a wrapper-first Btrfs implementation model for
Linux:

- use Btrfs as the strongest first backend
- keep upstream `dmux` in place
- add explicit probe, diagnostics, cleanup, and rollback behavior around it
- and only escalate to a sidecar or fork if real usage shows the wrapper seam is
  too weak

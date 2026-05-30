# APFS Backend and macOS Degraded Modes

**Status:** Maintained

## Purpose

Define the real macOS workspace-backend path using APFS without pretending APFS
is identical to Btrfs or ZFS.

This note makes two implementation modes explicit:

- a stronger `apfs_volume` mode
- a lighter degraded `apfs_clone` mode

The goal is honest portability, not symmetry theater.

## Maintained line

APFS should be treated as a real first serious macOS backend, not as an
afterthought or a permanent apology mode.

But the contract must remain capability-based because APFS does not present the
same lifecycle primitive shape as Btrfs subvolumes or ZFS datasets.

So the maintained line is:

- prefer APFS volume-backed workspaces where that lifecycle is acceptable
- expose clone-backed degraded mode explicitly when volume-backed control is too
  heavy or unavailable
- keep backend selection and capability reporting visible to the operator

## Boundary

### What the APFS backend owns

- workspace creation and destroy on APFS-backed hosts
- path resolution
- mode selection between strong and degraded APFS paths
- snapshot/quota/reserve reporting where actually supported
- operator-visible capability and mode diagnostics

### What remains above it

- claim and lease authority
- `dmux` session policy
- harness routing
- promotion or deploy authority

This is still a backend/lifecycle layer, not a coordination layer.

## Strong mode: `apfs_volume`

The strong macOS path is volume-per-workspace inside an APFS container.

### Why this is the strong mode

It can provide the closest stock-macOS match to the workspace contract:

- isolated mutable root
- managed mount target
- APFS snapshot support
- reserve/quota semantics
- clearer destroy lifecycle than plain directory trees

### Expected capabilities

- `isolated_root`
- `snapshot`
- `quota`
- `reserve`
- `mount_managed`
- likely `fast_destroy` relative to plain copy-backed trees

### Operational cautions

This mode is stronger, but it is not free:

- volume lifecycle overhead is real
- mount/admin semantics are more explicit than simple directory trees
- the wrapper must surface mode and capability choices instead of hiding them

## Degraded mode: `apfs_clone`

The degraded path uses APFS clonefile/tree-clone behavior when the stronger
volume-backed lifecycle is too heavy or not acceptable.

### Why it exists

It still gives the project a better macOS answer than plain copy-only fallback:

- cheap copy-on-write style tree creation when available
- lower setup overhead than volume-per-workspace
- useful local mutability with less administrative friction

### What it lacks relative to strong mode

The wrapper must not pretend this mode is equivalent to `apfs_volume`.

Likely missing or weaker areas:

- no equally explicit managed mount lifecycle
- weaker or absent snapshot semantics at the workspace-object level
- weaker reserve/quota behavior
- less structural cleanup semantics than a volume-backed path

## Selection rules

On APFS-backed macOS hosts, the wrapper should:

1. probe whether `apfs_volume` is allowed and practical
2. prefer `apfs_volume` when the host policy allows it
3. fall back to `apfs_clone` when strong mode is too heavy or unavailable
4. fall back further only if APFS-native paths are not usable

The operator should always be able to see which mode was selected.

## Capability transparency

The backend should explicitly report:

- selected backend kind
- whether the workspace is `apfs_volume` or `apfs_clone`
- snapshot availability
- quota/reserve availability
- whether cleanup is strong or degraded

This is the key rule for macOS portability: degrade honestly instead of
pretending different mechanisms are semantically identical.

## Relationship to other backends

### Relative to Btrfs

- Btrfs remains the stronger first Linux backend
- APFS should not imitate Btrfs vocabulary unnecessarily
- APFS should still satisfy the same high-level contract where possible

### Relative to ZFS

- ZFS remains the main parity cross-check backend
- APFS proves the contract can handle a native macOS path without collapsing to
  copy-only assumptions

## Wrapper behavior

The `dmux`-adjacent wrapper should:

- probe the backend
- pick the strongest usable APFS mode
- create the workspace through that mode
- expose diagnostics and cleanup commands
- avoid embedding APFS-specific policy into higher orchestration layers

This keeps the macOS path aligned with the same wrapper-first architecture used
for Linux.

## Non-goals

This note does **not** claim:

- APFS is identical to Btrfs
- the degraded clone mode is equivalent to volume-backed lifecycle control
- macOS should own the canonical backend semantics for the whole project
- claims/leases belong in filesystem code

## Relationship to nearby work

This note depends on:

- `docs/design/WORKSPACE_BACKEND_CAPABILITY_CONTRACT.md`

It complements:

- `docs/design/BTRFS_BACKEND_AND_DMUX_WRAPPER_MODEL.md`

It remains a peer input to:

- `101-zfs-workspace-backend-and-capability-parity-check.md`

## Practical verdict

The maintained macOS answer is:

- use `apfs_volume` as the strong path
- use `apfs_clone` as the explicit degraded path
- expose the difference clearly
- and keep APFS as a real backend under the common workspace contract rather
  than treating macOS as a second-class fallback-only platform

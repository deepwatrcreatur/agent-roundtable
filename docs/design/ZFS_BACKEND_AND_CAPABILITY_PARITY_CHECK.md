# ZFS Backend and Capability Parity Check

**Status:** Maintained

## Purpose

Use ZFS as the parity-check backend that proves the workspace abstraction is
about lifecycle capabilities rather than Btrfs-only naming.

This note does not make ZFS the canonical backend. It uses ZFS as the strongest
cross-check that the contract survives a different underlying primitive set
without leaking filesystem-specific policy upward.

## Maintained line

ZFS should be treated as:

- a serious second Linux backend
- a parity and regression check for the common workspace contract
- a useful host-specific backend where datasets/snapshots/clones are already
  operationally present

It should not be treated as:

- the only alternative to Btrfs
- a reason to rename higher contracts around ZFS terms
- a hidden place to move claim or lease authority

## Why ZFS matters

ZFS is the clearest proof that the abstraction is really about managed workspace
lifecycle semantics.

It offers:

- dataset-backed workspace identity
- snapshots
- writable clones
- quota and reserve-like controls
- clear destroy lifecycle

If the contract maps cleanly to ZFS, then the abstraction is doing its job.

## Boundary

### What the ZFS backend owns

- dataset-backed workspace create/destroy
- snapshot and clone operations
- path and dataset-handle resolution
- quota and usage reporting where available
- operator-visible capability reporting

### What remains above it

- wrapper policy
- claims and leases
- board/executor orchestration
- provider or harness routing
- promotion and deploy authority

This remains a backend/lifecycle layer only.

## Expected ZFS mapping

The common contract should map to ZFS approximately like this:

| Contract op | ZFS mapping |
|---|---|
| `probe()` | detect usable dataset namespace, tools, and permissions |
| `create()` | create workspace dataset |
| `destroy()` | destroy workspace dataset and managed snapshots/clones |
| `path()` | resolve mounted dataset path |
| `stat()` | return usage/quota/create metadata |
| `snapshot()` | create named ZFS snapshot |
| `clone()` | create writable clone from snapshot |
| `set_quota()` | set dataset quota |
| `set_reserve()` | set dataset reservation |

This is why ZFS is such a useful parity backend: it hits most of the stronger
capability surface while still being structurally distinct from Btrfs.

## Capability comparison matrix

### Strong capability view

| Backend | Isolated root | Snapshot | Writable clone | Quota | Reserve | Managed mount | Notes |
|---|---|---|---|---|---|---|---|
| `btrfs` | yes | yes | yes | yes | limited/host-specific | implicit-ish | strongest current Linux default |
| `zfs` | yes | yes | yes | yes | yes | yes | strongest parity cross-check |
| `apfs_volume` | yes | yes | weaker than dataset/subvolume clone model | yes | yes | yes | strongest stock macOS path |
| `apfs_clone` | partial | weaker | yes | weak/none | weak/none | no | degraded macOS mode |
| `reflink` | partial | no | yes | no | no | no | useful degraded Linux mode |
| `copy` | partial | no | no | no | no | no | universal fallback only |

### What this matrix proves

- the common contract is rich enough to express ZFS honestly
- APFS and degraded modes can remain first-class without pretending full parity
- fallbacks can be admitted without being mislabeled as strong managed backends

## Parity findings

### What appears truly portable

These concepts survive all serious backends:

- isolated mutable root
- stable workspace handle
- create / destroy lifecycle
- path resolution
- basic usage/stat reporting

### What is capability-gated rather than universal

- snapshots
- writable clones with strong lifecycle semantics
- quotas
- reserves
- managed mount semantics

This is exactly why the contract had to be capability-based instead of
filesystem-branded.

### What should remain backend-local

- backend-specific identifiers
- admin commands
- exact snapshot/clone implementation details
- host-specific performance and cleanup quirks

Those should not leak into the scheduler or board model.

## Relationship to Btrfs and APFS

### Relative to Btrfs

- Btrfs remains the strongest first Linux implementation path
- ZFS does not replace that priority
- ZFS mainly proves that the contract is not Btrfs-named by accident

### Relative to APFS

- APFS proves the contract can support a native macOS path
- ZFS proves the contract stays coherent across a second strong Linux/Unix-like
  dataset model
- together they show that the abstraction is broader than one filesystem family

## Wrapper implications

The `dmux`-adjacent wrapper should:

- treat `zfs` as a normal backend candidate
- rank it below `btrfs` only when host policy prefers Btrfs on Linux
- expose its stronger capabilities clearly when selected
- avoid hard-coding Btrfs assumptions into clone/snapshot/cleanup UX

This is the practical effect of the parity check: the wrapper should speak in
contract terms, not Btrfs nouns.

## Contract-change check

Current verdict: the existing workspace-backend contract is sufficient.

The parity pass does **not** require:

- renaming operations into ZFS vocabulary
- moving lease semantics into the backend
- weakening the contract down to copy-only portability

The only maintained requirement is to keep capability reporting explicit so the
wrapper can distinguish `btrfs`, `zfs`, `apfs_volume`, `apfs_clone`, and
fallbacks honestly.

## Non-goals

This note does **not** claim:

- ZFS should be the default everywhere
- OpenZFS on macOS should be the normal path for most users
- parity means identical performance or operator ergonomics
- backend-specific lifecycle becomes governance truth

## Relationship to nearby work

This note depends on:

- `docs/design/WORKSPACE_BACKEND_CAPABILITY_CONTRACT.md`

It cross-checks:

- `docs/design/BTRFS_BACKEND_AND_DMUX_WRAPPER_MODEL.md`
- `docs/design/APFS_BACKEND_AND_MACOS_DEGRADED_MODES.md`

## Practical verdict

The maintained conclusion is:

- ZFS cleanly fits the common workspace contract
- that fit confirms the abstraction is lifecycle- and capability-based rather
  than Btrfs-branded
- Btrfs remains the primary Linux path
- APFS remains the primary stock macOS path
- and the wrapper should continue to choose among them through explicit
  capability probing instead of backend-specific assumptions

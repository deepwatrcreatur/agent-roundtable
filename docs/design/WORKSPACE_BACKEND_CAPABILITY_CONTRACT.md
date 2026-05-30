# Workspace Backend Capability Contract

**Status:** Maintained

## Purpose

Define the narrow backend contract for isolated mutable workspaces used by the
local `dmux`-adjacent workflow and future workspace-aware operator tooling.

This contract keeps:

- filesystem and backend mechanics below the wrapper layer
- claim and lease policy above the backend layer
- backend capability differences explicit rather than hidden behind false
  semantic parity

## Maintained line

The abstraction is a **managed isolated workspace lifecycle**, not a specific
filesystem brand such as Btrfs.

The project should therefore:

- define a capability-based backend contract
- implement real backends for Btrfs, APFS, and ZFS where useful
- allow honest degraded modes such as reflink or copy-backed workspaces
- keep claims, leases, and orchestration policy outside the backend layer

## Boundary

### What the backend layer owns

- creation and destruction of isolated mutable workspace roots
- backend-specific path and handle resolution
- snapshot, clone, quota, and reserve operations where supported
- usage, capability, and lifecycle metadata

### What the backend layer does not own

- claim issuance
- lease renewal or revocation
- scheduler policy
- provider or harness routing
- promotion or publish authority

Backends provide isolation and lifecycle primitives. They do not become the
coordination plane.

## Core object model

### `WorkspaceHandle`

Opaque identity for one managed mutable workspace.

Minimum fields:

| Field | Meaning |
|---|---|
| `workspace_id` | Stable backend-level handle |
| `backend_kind` | `btrfs`, `zfs`, `apfs_volume`, `apfs_clone`, `reflink`, `copy`, etc. |
| `root_path` | Absolute usable path |
| `created_at` | Creation timestamp |
| `labels` | Optional operator or wrapper labels |

### `BackendProbe`

Result of probing one backend implementation on one host.

Minimum fields:

| Field | Meaning |
|---|---|
| `backend_kind` | Candidate backend |
| `available` | Whether the backend can be used now |
| `capabilities` | Supported capability set |
| `reason_codes` | Why the backend is degraded or unavailable |
| `host_notes` | Optional operator-facing notes |

### `WorkspaceStat`

Minimum shape:

| Field | Meaning |
|---|---|
| `workspace_id` | Parent workspace |
| `backend_kind` | Backend in use |
| `bytes_used` | Current usage when measurable |
| `quota_bytes` | Current quota if supported |
| `reserve_bytes` | Current reserve if supported |
| `created_at` | Creation timestamp |
| `snapshot_count` | Snapshot count when supported |

## Required operations

Every backend must support these operations.

| Operation | Purpose |
|---|---|
| `probe()` | Return availability and capability set |
| `create(name, opts)` | Create isolated mutable workspace |
| `destroy(workspace, opts)` | Remove workspace and its managed state |
| `path(workspace)` | Return absolute usable path |
| `stat(workspace)` | Return usage and lifecycle metadata |

These are the portability baseline.

## Optional capability-gated operations

Backends may additionally support:

| Operation | Capability gate |
|---|---|
| `snapshot(workspace, label)` | `snapshot` |
| `restore(workspace, snapshot_ref)` | `restore` |
| `clone(source, new_name, opts)` | `cow_clone` or equivalent |
| `set_quota(workspace, bytes)` | `quota` |
| `set_reserve(workspace, bytes)` | `reserve` |
| `list(opts)` | `enumerable` |
| `gc(policy)` | `gc` |

The wrapper must check capabilities instead of assuming these always exist.

## Standard capability names

The following capability names are worth standardizing:

- `isolated_root`
- `cow_clone`
- `snapshot`
- `restore`
- `quota`
- `reserve`
- `fast_destroy`
- `shared_readonly_seed`
- `mount_managed`
- `enumerable`
- `gc`

Backends may expose additional backend-local diagnostics, but higher layers
should anchor on the standard capability vocabulary first.

## Selection and probing model

The `dmux` wrapper or future workspace launcher should:

1. probe available backends on the host
2. rank them by policy and host fit
3. choose the strongest backend satisfying required capabilities
4. report the selected backend and active capabilities to the operator

The wrapper should not silently pretend a degraded backend is equivalent to a
stronger one.

### Example selection ladder

- Linux on Btrfs:
  - prefer `btrfs`
  - then `zfs` if that is the actual local substrate
  - then reflink/copy fallbacks
- macOS on APFS:
  - prefer `apfs_volume` when allowed
  - then `apfs_clone`
  - then copy fallback

## Backend shortlist

### Linux

#### `btrfs`

- strongest first Linux candidate
- natural fit for subvolume-backed workspace lifecycle
- expected to support:
  - `isolated_root`
  - `snapshot`
  - `cow_clone`
  - `quota`
  - `fast_destroy`

#### `zfs`

- serious second Linux candidate
- proves the abstraction is lifecycle-based rather than Btrfs-named
- expected to support:
  - `isolated_root`
  - `snapshot`
  - `cow_clone`
  - `quota`
  - `reserve`
  - `fast_destroy`

#### `reflink`

- degraded but useful Linux fallback on suitable filesystems
- may support cheap clone without real managed snapshots or quotas

#### `copy`

- universal fallback only
- never the preferred serious mode

### macOS

#### `apfs_volume`

- primary serious macOS backend
- strongest native managed-workspace path on stock macOS
- expected to support:
  - `isolated_root`
  - `snapshot`
  - `quota`
  - `reserve`
  - `mount_managed`

#### `apfs_clone`

- lighter degraded APFS mode
- may support cheap cloning without the stronger lifecycle semantics of a
  managed volume-per-workspace path

#### `zfs`

- niche but real where operators already run OpenZFS on macOS
- not the default expectation for ordinary macOS hosts

#### `copy`

- universal fallback only

## Operator visibility

The wrapper should expose enough diagnostics for an operator to answer:

- which backend was selected
- which capabilities are active
- which stronger backend was unavailable and why
- whether the workspace is on a strong or degraded mode

This avoids silent backend drift and makes degraded macOS or fallback modes
explicit.

## Relationship to leases and coordination

The contract deliberately stops short of lease semantics.

Leases, claims, and mutation authority remain above this layer because:

- two workspaces can be technically isolated while still targeting the same live
  resource
- backend isolation does not decide publish or deploy authority
- lifecycle capabilities are not the same thing as orchestration permission

So the backend contract should compose with, not replace:

- `docs/design/LOCAL_DAEMON_CONTRACT.md`
- `docs/design/FORGE_CLAIM_LEASE_PROTOCOL.md`
- `docs/design/JJ_VIRTUAL_WORKING_COPIES.md`

## Non-goals

This contract does **not** promise:

- generic filesystem virtualization
- container-grade process isolation
- distributed replication
- perfect semantic equivalence across filesystems
- that backend-specific admin commands become scheduler-level concepts

## Practical verdict

The maintained deliverable is a capability-based workspace lifecycle contract.

That means:

- Btrfs should not be the abstraction
- APFS should not be treated as an afterthought
- ZFS should act as the parity cross-check backend
- and the `dmux` wrapper should select among backends through explicit probing
  rather than hard-coded filesystem assumptions

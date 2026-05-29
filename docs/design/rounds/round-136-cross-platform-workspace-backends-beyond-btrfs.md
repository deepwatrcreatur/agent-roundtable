## Round 136 — Cross-Platform Workspace Backends Beyond Btrfs

**Tags:** tooling, worktrees, dmux, btrfs, zfs, apfs, macos, filesystems, isolation  
**Status:** Closed  
**Voices used:** GPT-5.3-Codex, GPT-5.4 mini, Claude Sonnet 4.6, Copilot synthesis  
**Additional note:** Fresh grounding for this round included Btrfs subvolume docs, OpenZFS dataset/snapshot/clone docs, Apple APFS volume docs, and the macOS `clonefile(2)` man page.

### Round question

The maintainer wanted a follow-up on the recent Btrfs-backed workspace direction,
but with a sharper portability question:

- if Btrfs subvolumes are a meaningful adjunct to the `dmux` wrapper path on Linux
- what should the project do on macOS hosts where Btrfs is usually not available
- whether the right answer is an abstract backend interface rather than a
  Btrfs-specific tool shape
- what the interface should actually look like
- and which filesystems deserve to be first-class candidates on Linux and macOS

The real decision was **not** "is APFS identical to Btrfs?"

It was:

- what abstraction preserves the important safety and cleanup benefits
- without pretending every platform has the same filesystem primitive
- and without collapsing the whole design into lowest-common-denominator
  directory copies

### Grounding used in this round

Relevant prior local context carried in:

- **Round 116** — the main recurring bug is bad writable defaults; isolated
  mutation matters more than more reminders
- **Round 129** — the core local failure mode is agent collision in mutable
  workspaces, not frontend/harness aesthetics
- **Round 131** — Btrfs subvolumes are a meaningful secondary upgrade, but the
  primary fix is still isolated mutation by default behind the `dmux` wrapper
- **Round 134** — VFS / virtual working copies mostly address materialization
  and monorepo I/O, not the ownership/collision problem
- **Round 135** — under current means, wrapper-first remains the efficient
  frontier; only a narrow lifecycle/lease helper is a plausible escalation

Fresh external grounding carried in:

- **Btrfs**
  - subvolumes are independent file/directory hierarchies
  - snapshots are also subvolumes with copy-on-write sharing
  - qgroups provide quota support
- **ZFS**
  - datasets are first-class filesystems in a pool namespace
  - snapshots are read-only point-in-time copies
  - clones create writable datasets from snapshots
  - quotas and mountpoint properties are native features
- **APFS**
  - volumes live inside a shared container with space sharing
  - per-volume reserve and quota sizes are available
  - snapshots exist
  - APFS is not a direct per-directory subvolume model
- **macOS clone support**
  - `clonefile(2)` provides copy-on-write cloning support on capable volumes
  - directory-tree cloning is available through the Apple copy APIs, but this is
    lighter-weight and less structurally explicit than a native subvolume/dataset
    unit

Important scope boundary carried into the round:

- the project is still solving **agent-safe mutable workspaces**
- not building a generic filesystem virtualization layer
- and not treating the filesystem backend as the place to solve leases,
  claims, or higher-order orchestration policy

### Participation record

What actually happened in this run:

- **GPT-5.3-Codex seat:** substantive
- **GPT-5.4 mini seat:** substantive
- **Claude Sonnet 4.6 seat:** substantive
- **Copilot:** substantive

This round therefore had a **four-seat substantive roster**.

### Voice summaries

#### GPT-5.3-Codex

- Strongest on drawing the abstraction boundary around a **workspace instance
  lifecycle**, not around filesystem nouns like subvolume or dataset.
- Argued the API should expose intent:
  isolated mutable root, snapshot, fork, quota, destroy.
- Ranked **Btrfs first** and **ZFS second** on Linux.
- Ranked **APFS volume-per-workspace first** on macOS, with clonefile-backed tree
  cloning as a weaker mode and directory copy only as a last resort.
- Treated APFS as good enough to support seriously, but with clear capability
  distinctions and no pretense of perfect semantic parity.

#### GPT-5.4 mini

- Strongest on the phrase that the abstraction should be about **workspace
  isolation**, not filesystem identity.
- Pushed a capability-advertising backend interface:
  snapshot, rollback, quota, reserve, fast create/destroy, shared read-only
  base, and path mountability.
- Saw **APFS as first-class on macOS**, precisely because the project needs a
  native path there rather than a permanent apology/fallback mode.
- Most relaxed about accepting different underlying mechanisms so long as the
  behavior the agents care about remains stable.

#### Claude Sonnet 4.6

- Strongest on placing the abstraction as a **named workspace scope** below the
  `dmux` wrapper and above raw filesystem primitives.
- Most explicit that the interface should advertise runtime capabilities rather
  than assume all backends can snapshot, clone, and quota equally.
- Ranked **Btrfs** and **ZFS** as the serious Linux backends.
- Ranked **APFS volume-per-workspace** as the best stock-macOS backend, while
  warning that volume lifecycle overhead and operational friction make it a bit
  less comfortable than Btrfs/ZFS.
- Was the only voice to argue that APFS should be treated as **second-class but
  fully supported** rather than fully first-class, mainly because its semantics
  and ergonomics are somewhat less direct.

#### Copilot

- I agreed with the prior rounds that the abstraction should not hard-code
  Btrfs.
- My strongest synthesis point was that the project should define a
  **workspace-backend contract** with required and optional capabilities, then
  let Btrfs, ZFS, and APFS map into it honestly.
- I also agreed that APFS deserves to be on the shortlist:
  not because it is identical to Btrfs, but because it is the obvious native
  macOS substrate for managed workspaces.
- I pushed the line that claims/leases remain above this layer:
  filesystem backends help with isolation, rollback, quotas, and cleanup, but
  they do not by themselves settle ownership policy.

### First-pass convergence

The substantive voices converged on the following points.

1. **Do not make Btrfs itself the abstraction.**
   The right boundary is a managed isolated workspace, not a specific filesystem
   primitive.

2. **The backend interface should be capability-based.**
   Different backends can honestly expose:
   - isolated mutable root
   - cheap writable clone
   - snapshots
   - rollback/restore
   - quotas/reserves
   - fast destroy
   without the scheduler or wrapper pretending every backend has identical
   semantics.

3. **Btrfs and ZFS are the main Linux candidates.**
   Btrfs is the cleanest fit for the already-discussed subvolume-backed path.
   ZFS is the strongest serious alternative with dataset/clone semantics close to
   the desired lifecycle model.

4. **APFS absolutely belongs on the macOS shortlist.**
   The panel did not treat APFS as an irrelevant or fake candidate.
   The real question was how to use it honestly:
   typically volume-per-workspace for the strong mode, with clonefile/copy-based
   tree materialization as a lighter degraded mode.

5. **Claims, leases, and orchestration policy should stay above the filesystem
   backend layer.**
   The backend can enforce separation and improve cleanup/rollback, but it should
   not be overloaded into becoming the whole coordination system.

### Real disagreements that remained

There was one real disagreement:

- **GPT-5.4 mini** and **Copilot** were comfortable calling APFS
  **first-class on macOS**
- **Claude** wanted APFS treated as **fully supported but second-class**
  because the volume model is less direct and a bit more operationally awkward
- **Codex** sat between those poles:
  supportive of APFS as the best macOS answer, but insistent on capability
  transparency rather than symmetry theater

This was a disagreement about **status language**, not about whether APFS should
be implemented.

No voice argued that macOS should simply be abandoned to plain directory copies
if serious local agent work is expected there.

### Concrete interface shape

The strongest maintained interface shape from this round is:

#### Required core object

- **Workspace handle**
  - opaque backend-specific identity
  - stable mounted/usable path for one agent workspace
  - metadata sufficient for cleanup and inspection

#### Required core operations

- `probe() -> capabilities`
- `create(name, opts) -> workspace`
- `destroy(workspace, force?)`
- `path(workspace) -> absolute-path`
- `stat(workspace) -> usage/limits/created-at/backend-kind`

These define the minimum viable portable contract.

#### Optional capability-gated operations

- `snapshot(workspace, label) -> snapshot-ref`
- `restore(workspace, snapshot-ref)`
- `clone(source, new-name, opts) -> workspace`
- `setQuota(workspace, bytes)`
- `setReserve(workspace, bytes)`
- `list() -> workspaces`
- `gc(policy)`

#### Capability names worth standardizing

- `isolated_root`
- `cow_clone`
- `snapshot`
- `restore`
- `quota`
- `reserve`
- `fast_destroy`
- `shared_readonly_seed`
- `mount_managed`

#### Non-goals

The interface should **not** promise:

- generic filesystem virtualization
- container/security isolation
- distributed replication
- perfect semantic equivalence across filesystems
- that backend-specific IDs or admin commands are part of the scheduler contract

### Candidate backend shortlist

#### Linux

1. **Btrfs subvolume backend**
   - primary Linux candidate
   - best fit for the already-maintained direction

2. **ZFS dataset backend**
   - serious second Linux candidate
   - strongest alternative when ZFS is already present

3. **Reflink/copy backend on XFS or ext4-like filesystems**
   - fallback only
   - useful when copy-on-write tree cloning exists but snapshots/quotas do not

4. **Plain directory-copy backend**
   - universal fallback
   - not a preferred serious mode

#### macOS

1. **APFS volume backend**
   - primary macOS candidate
   - the closest stock-macOS match to the managed-workspace contract

2. **APFS clonefile/tree-clone backend**
   - lighter degraded mode on APFS
   - useful when volume-per-workspace is too heavy or unavailable

3. **OpenZFS-on-macOS dataset backend**
   - niche but real candidate where already installed
   - not the default expectation for ordinary macOS hosts

4. **Plain directory-copy backend**
   - universal fallback only

### Final synthesis

The strongest maintained answer from this round is:

- keep the main architecture from the recent `dmux` / Btrfs rounds
- but stop talking as if Btrfs itself is the only serious backend
- define a narrow **workspace-backend interface**
  whose job is:
  - isolated mutable roots
  - cheap creation/cloning where possible
  - snapshots/rollback where possible
  - quotas/reserves where possible
  - explicit cleanup
- then implement real backends for:
  - **Btrfs** on Linux
  - **APFS** on macOS
  - and likely **ZFS** where available

The panel rejected two bad extremes:

- **bad extreme A:** "Btrfs subvolumes are the abstraction, so macOS is just a bad
  unsupported case"
- **bad extreme B:** "every platform must look identical, so reduce the interface
  to plain directory copies"

The maintained line is:

- abstract the **workspace lifecycle**, not the filesystem brand
- let backend capabilities differ honestly
- and keep higher-order ownership/lease policy above this layer

### Recommended next-month sequence

1. **Define the workspace-backend contract now.**
   Keep it narrow, capability-based, and explicitly below the `dmux` wrapper /
   scheduler layer.

2. **Implement the Btrfs backend first.**
   That remains the strongest Linux path and preserves continuity with Round 131
   and Round 135.

3. **Implement APFS as the first serious macOS backend.**
   Prefer volume-per-workspace as the strong mode, with clonefile/tree-clone mode
   as an explicit degraded profile rather than pretending they are identical.

4. **Add ZFS as the next cross-check backend.**
   ZFS is the clearest proof that the abstraction is about lifecycle semantics,
   not about Btrfs-only naming.

5. **Keep leases/claims separate.**
   If a narrow lifecycle/lease sidecar is later needed, it should sit above this
   backend layer rather than being baked into backend-specific filesystem code.

### Verdict

Do not hard-code Btrfs as the workspace abstraction: define a capability-based workspace-backend interface, keep Btrfs and ZFS as the main Linux candidates, make APFS a real macOS backend rather than an afterthought, and preserve claims/lease policy as a higher layer above the filesystem-specific isolation primitive.

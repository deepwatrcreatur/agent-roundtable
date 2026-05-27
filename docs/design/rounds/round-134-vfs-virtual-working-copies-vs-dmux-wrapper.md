## Round 134 — VFS / Virtual Working Copies vs the `dmux` Wrapper Path

**Tags:** tooling, worktrees, vfs, jj, scalar, dmux, btrfs  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis

### Round question

The maintainer wanted to know whether the current local direction after Round 131
should be reconsidered in light of VFS-style workspace virtualization.

This was not a generic “is VFS interesting?” round.
The actual decision problem was:

- whether VFS-style workspace virtualization is a better answer than the current
  `dmux`-wrapper direction for preventing agent interference
- whether public `jj` work on virtual working copies means the project should
  pivot now
- whether existing Microsoft VFS / Scalar history changes the local conclusion
- and whether the project should replace, defer, or reaffirm the current plan of
  read-mostly shared checkout plus isolated mutation workspaces

### Grounding used in this round

Relevant prior local context carried in:

- **Round 112** — `jj` is a meaningful local mutation substrate improvement, but
  the differentiated product opportunity remains above the VCS layer.
- **Round 116** — the root local bug is bad writable defaults; shared checkout
  should become read-mostly / sync-only and preflight guardrails matter more than
  more reminders.
- **Round 129** — shared-checkout collisions are fundamentally a
  workspace-isolation problem, not a local harness/frontend problem.
- **Round 131** — Btrfs subvolumes are a secondary upgrade; the primary fix is
  default isolated mutation workspaces, starting with a Nix-packaged wrapper
  around upstream `dmux` rather than an immediate fork.

Fresh external grounding carried in:

- **`microsoft/VFSForGit`**
  - states that VFS for Git is in maintenance mode
  - recommends `Scalar` for new deployments
  - describes a path forward centered more on core Git primitives than on a
    permanent heavy virtualization layer
- **`microsoft/scalar`**
  - says it moved into `microsoft/git`
  - describes itself as a thin shell around core Git scaling features such as
    partial clone, sparse checkout, filesystem monitor, and maintenance
- **public `jj` issue search**
  - shows active/open discussion around virtual working copy / virtual filesystem
    ideas
  - but the fetched evidence here did not establish a clearly mature, shipped,
    general-purpose feature
  - and one visible item explicitly referenced an MVP with caching not yet
    implemented

Important scope boundary carried into the round:

- the question was **not** whether VFS is useful for giant monorepos
- it was whether VFS should replace or supersede the current local answer to
  multi-agent workspace interference

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** substantive
- **DeepSeek API:** substantive via direct HTTP API and local decrypted key
- **Copilot:** substantive

This round therefore had a **full five-seat substantive roster**.

### Voice summaries

#### Codex CLI

- Strongest on the distinction between **checkout materialization** and
  **workspace ownership**.
- Treated VFS as mostly orthogonal to the current failure mode.
- Read the Microsoft VFS -> Scalar evolution as evidence that even for monorepo
  scaling, heavy virtualization tends to collapse back toward thinner wrappers on
  core Git features.
- Recommended continuing the current `dmux` wrapper path and keeping VFS / `jj`
  virtual working copies only as background context unless real measurements make
  checkout/materialization the dominant bottleneck.

#### Gemini CLI

- Most willing to preserve a **background research track** for VFS, but not to
  pivot toward it now.
- Strongest on the immediate next move being a **claim/lease-aware preflight
  guard** in the `dmux` wrapper.
- Treated VFS as a possible future optimization for checkout scaling, not as the
  main answer to interference.
- Kept the local recommendation centered on explicit worktree isolation plus
  Btrfs-backed rollback as an optional enhancement.

#### Claude CLI

- Strongest on the claim that VFS solves **materialization scaling**, not
  **multi-agent write isolation**.
- Read the investigation as effectively complete rather than something that still
  deserves much implementation attention.
- Most skeptical of allocating any real VFS follow-up work at all.
- Recommended simply continuing the Round 131 sequence unchanged:
  preflight guard, wrapper, real-session evidence, and no VFS prototype.

#### DeepSeek API

- Strongest on the explicit comparison between:
  - VFS for file materialization
  - worktree isolation for ownership
  - claims/leases for coordination
  - and Btrfs snapshots for recovery
- Treated the Microsoft history as a warning against building a large bespoke
  VFS layer.
- Saw `jj` virtual working copies as interesting but clearly too exploratory to
  replace the wrapper-first path now.
- Recommended the same practical next move as Round 131:
  make isolated mutation the default and keep VFS only as a secondary research
  topic if checkout scaling later becomes the real bottleneck.

#### Copilot

- I agreed with the strong convergence that the local problem is still
  **ownership / coordination over mutable workspaces**, not primarily checkout
  size or file materialization.
- My strongest synthesis point was that VFS can optimize a shared view, but it
  does not answer:
  who owns the write surface, who may promote, and how stale-success promotion is
  prevented.
- I also agreed that Microsoft’s VFS -> Scalar arc and the public `jj` maturity
  signal both point toward the same maintained line:
  continue with thin wrapper-first isolation rather than a new VFS bet.

### First-pass convergence

The substantive voices converged on the following points.

1. **VFS is not the primary abstraction for the current failure mode.**
   The current pain is multi-agent mutation collision, not giant-monorepo
   materialization.

2. **Microsoft’s VFS -> Scalar history reinforces the local wrapper-first line.**
   Even in the domain VFS was built for, the practical path moved toward thinner
   wrappers around native Git features rather than a permanently separate
   virtualization stack.

3. **Public `jj` virtual-working-copy work is interesting but not mature enough to
   drive a pivot now.**
   The fetched evidence looked active and exploratory rather than ready to become
   the next-month implementation plan.

4. **The real control points remain explicit isolation and coordination.**
   The roster kept returning to:
   - isolated worktrees for separate writable namespaces
   - claims/leases/preflight for coordination
   - and Btrfs snapshots/rollback as a secondary operational upgrade

5. **The current Round 131 direction still stands.**
   No substantive voice argued that the project should replace the `dmux` wrapper
   path with a VFS implementation project.

### Real disagreements that remained

There was one narrower disagreement about how much attention VFS still deserves:

- **Claude** treated the answer as effectively settled and argued against spending
  further time on VFS or `jj` VFS tracking.
- **Codex**, **Gemini**, **DeepSeek**, and **Copilot** were comfortable keeping VFS
  as a **background research/watch item**, but not as an active implementation
  stream.

There was also a softer emphasis difference:

- **Gemini** put the strongest weight on immediately making the wrapper’s
  claim/lease guard load-bearing
- while **Codex** and **DeepSeek** spent more energy on the conceptual mismatch
  between materialization and ownership

These were differences of emphasis, not of direction.

### Final synthesis

The strongest maintained answer from this round is:

- VFS-style workspace virtualization is mostly a solution to checkout size,
  materialization, and I/O concerns
- the current local bug is agent interference in mutable workspaces
- so VFS is at best adjacent, not primary
- Microsoft’s own VFS history points away from a large dedicated VFS investment
- and current public `jj` virtual-working-copy work does not look mature enough to
  replace the already-established wrapper-first direction

The panel rejected two bad extremes:

- **bad extreme A:** “VFS is the future, so replace the current plan with a new
  virtualization project”
- **bad extreme B:** “filesystem/materialization questions never matter at all”

The maintained line is:

- keep the current `dmux` wrapper path
- make isolated mutation and preflight discipline actually load-bearing
- use optional Btrfs-backed worktrees where they improve rollback and cleanup
- and only revisit VFS if later measurement shows checkout/materialization costs
  becoming the real bottleneck

### Recommended next-month sequence

1. **Ship the preflight guard as a real default.**
   Shared-checkout writes should become visibly abnormal.

2. **Prototype the Nix-packaged wrapper around upstream `dmux`.**
   It should create disposable isolated worktrees by default and expose optional
   Btrfs-backed creation where supported.

3. **Run real local sessions through that path and measure the actual pain.**
   Watch collision incidents, cleanup debt, rollback use, workspace-creation time,
   and disk amplification.

4. **Do not pivot to a VFS implementation effort now.**
   Keep VFS / `jj` virtual-working-copy developments as background context only
   unless measurements later show that materialization cost, not ownership, has
   become the practical bottleneck.

### Verdict

Continue with the `dmux` wrapper path; VFS-style workspace virtualization is orthogonal to the current agent-interference problem and should remain, at most, a background research/watch item rather than the primary implementation path.

## Round 140 — `rift` as a Workspace-Manager Reference vs the `dmux` Wrapper Path

**Tags:** tooling, dmux, rift, workspaces, git, copy-on-write, orchestration  
**Status:** Closed  
**Voices used:** GPT-5.2-Codex, Claude Haiku 4.5, GPT-5.4 mini, Copilot synthesis

### Round question

The maintainer asked for a fresh round of discussion on the new
`anomalyco/rift` repository and, specifically, whether it changes what this
project should do around the current `dmux` wrapper direction.

This was not a generic question about whether `rift` is clever.
The actual decision problem was:

- whether `rift` is a better basis than the current wrapper-first `dmux` path
- whether `rift` should be treated as a substitute, a complement, or mostly an
  orthogonal reference
- what concrete ideas should be borrowed now, if any
- and whether any newly appearing adjacent projects change the frontier enough
  to justify a direction change

### Grounding used in this round

Relevant prior local context carried in:

- **Round 131** — treat Btrfs/subvolume ideas as secondary; the first move is a
  wrapper around upstream `dmux`
- **Round 134** — virtual-working-copy / VFS work is mostly orthogonal to the
  current collision bug; keep the `dmux` wrapper path
- **Round 135** — under current means, the efficient frontier is wrapper-first
  on `dmux`, with only a narrow sidecar or backend layer if evidence later
  proves it necessary
- **Round 139** — `ntm` is a meaningful watch item because it bundles much of a
  likely future coordination layer, but it still does not displace the current
  wrapper-first `dmux` direction

Fresh local implementation state carried in:

- a first-slice launcher guard is now implemented locally in a clean
  `nix-dmux` worktree
- the packaged entrypoint now installs upstream as `dmux-upstream` and wraps it
  as `dmux`
- the wrapper:
  - classifies Git roots as **primary checkout** vs **linked worktree**
  - adds `dmux preflight`
  - blocks normal launches from the primary checkout by default
  - allows an explicit one-shot override via
    `DMUX_ALLOW_SHARED_CHECKOUT=1 dmux --allow-shared-checkout`
- the package build succeeded and smoke tests confirmed:
  - primary-checkout preflight blocks
  - linked-worktree preflight allows
  - override preflight allows
- this slice is intentionally a launcher-level guard, not a full lease system,
  workspace backend, or daemon

Fresh external evidence carried in about `rift`:

- `rift` is a brand-new Rust repository created on `2026-05-31`
- its `specs.md` defines a managed workspace-copy model with:
  - `create`
  - `remove`
  - `link`
  - `children`
  - `ancestors`
- default storage is a sibling `.rifts/<workspace-name>/` directory rather than
  linked Git worktrees beneath the original checkout
- metadata is stored in central SQLite with rooted parent/child ancestry and a
  `.rift` identity marker inside each managed workspace
- `remove` deletes a whole managed subtree
- `link` can reconcile moved workspaces and optionally reparent them
- Git integration is intentionally conservative:
  - copy dirty, staged, untracked, ignored, and cached state intact
  - detach `HEAD` in the destination if a commit exists
  - add `/.rift` to `.git/info/exclude`
  - refuse creation from linked Git worktrees
  - refuse unsafe Git states such as merge/rebase/cherry-pick/revert/bisect or
    lock-file ambiguity
- `copy.rs` exposes a copy-on-write backend boundary:
  - Linux reflink
  - macOS `clonefile`
  - no Windows implementation yet
  - no full byte-copy fallback

Fresh ecosystem scan also carried into the round:

- **`tr00x/Manta`** (created `2026-05-29`) is the freshest nearby project with a
  directly relevant posture: transcript inheritance, isolated Git worktrees,
  contracts, locks, claims, heartbeats, a coordination bus, and review/merge
  flows
- **`J1amo/agent-worktree-orchestrator`** (created `2026-05-25`) is a smaller,
  conservative scaffold built around worktrees, audit artifacts, risk routing,
  and human approval rather than a broad new substrate
- **`openwong2kim/wmux`** is a more mature Windows-centric terminal/browser UX
  surface with daemon persistence and automation, but it is much more about
  operator experience than about workspace-isolation policy or mutation safety

Important scope boundary carried into the round:

- the question was **not** whether `rift` is a well-designed little system on
  its own terms
- it was whether `rift` changes what should happen **next** in this project,
  given the already-implemented `dmux` launch guard and the prior wrapper-first
  conclusion history

### Participation record

What actually happened in this run:

- **GPT-5.2-Codex:** substantive
- **Claude Haiku 4.5:** substantive
- **GPT-5.4 mini:** substantive
- **Copilot:** substantive synthesis

This round therefore had a **four-seat substantive roster**.

### Voice summaries

#### GPT-5.2-Codex

- Most disciplined about keeping the comparison anchored to the current local
  `dmux` wrapper path rather than drifting into admiration for a new backend.
- Treated `rift` as a useful reference for Git-safety rules but too heavy as a
  change of basis.
- Strongest on the point that the managed-workspace tree, central SQLite store,
  and `.rift` identity model are exactly the class of backend architecture that
  prior rounds explicitly deferred until stronger evidence exists.
- Recommended borrowing policy ideas only:
  linked-worktree refusal, unsafe-state detection, detached destinations if
  copies ever matter, and Git-status hiding for management markers.

#### Claude Haiku 4.5

- Strongest on the separation between **workspace shape** and **task dispatch**.
- Framed `rift` as a managed COW workspace-copy system rather than an execution
  orchestrator, and therefore not a substitute for `dmux`.
- Most explicit that integrating it now would create a parallel abstraction with
  incomplete platform coverage.
- Recommended citing its Git-safety posture while continuing to build the local
  wrapper around upstream `dmux`.

#### GPT-5.4 mini

- Most sympathetic to `rift` as a coherent workspace-lifecycle model.
- Strongest on the appeal of explicit rooted ancestry, marker identity, and the
  possibility of later moved-workspace recovery via `link`.
- But still concluded that this is a step toward a centralized workspace manager
  and not the next move for a launcher-level guard project.
- Recommended borrowing only the preflight and refusal semantics for now, while
  deferring the registry/tree model and copy-on-write backend machinery.

#### Copilot

- I agreed with the overall convergence that `rift` is a **managed workspace
  backend reference**, not a replacement for the current `dmux` wrapper path.
- My strongest synthesis point was that `rift` is most valuable where it is most
  conservative:
  its Git safety rules are sharp, explicit, and directly reusable.
- But the rest of its model pushes toward a heavier workspace-management plane:
  central registry, rooted copy trees, move reconciliation, subtree deletion,
  and platform-specific copy machinery.
- I therefore treated `rift` as a good source of narrow policy borrowing and a
  watch item for future backend work, but not as a justified basis change now.

### First-pass convergence

The substantive voices converged on the following points.

1. **`rift` is best understood as a managed workspace-copy backend.**
   It is not mainly a terminal multiplexer, not mainly a launcher wrapper, and
   not mainly a coordination control plane.
   Its center of gravity is managed workspace creation, identity, ancestry,
   linking, and removal.

2. **`rift` is not a substitute for `dmux`.**
   The current local `dmux` path is about launch discipline, operator flow,
   worktree-based mutation isolation, and eventually narrow coordination.
   `rift` does not replace that.
   At best it could become a complement beneath some later backend layer.

3. **The strongest part of `rift` for present purposes is its Git-safety policy.**
   In particular:
   - refusing linked-worktree sources in the contexts where exact copy semantics
     matter
   - refusing ambiguous/in-progress Git states
   - hiding management markers from routine Git status
   - making detached destinations explicit instead of smuggling branch semantics
     into a workspace-copy tool

4. **The heaviest part of `rift` is exactly the part we should not adopt yet.**
   The rooted SQLite registry, `.rift` identity plane, `.rifts` storage layout,
   subtree lifecycle APIs, and COW backend abstraction all point toward a larger
   workspace manager.
   That may become reasonable later, but it is beyond the boundary of the first
   safety slice already underway.

5. **`rift` does not overturn the wrapper-first line established by earlier
   rounds.**
   The local situation has now moved even further toward implementation reality:
   the first `dmux` safety guard is already built and smoke-tested.
   This makes a basis switch even less justified than it would have been before.

### Fresh ecosystem read

The surrounding ecosystem scan mattered here because the maintainer asked not
just about `rift`, but whether new similar projects are appearing that deserve
copying.

The practical read was:

- **`Manta` is the freshest high-signal watch item.**
  It is much closer to the predicted future gap than `rift` is:
  transcript inheritance, task contracts, locks, claims, heartbeats, review, and
  coordination over real isolated worktrees.
  If a future round is needed on what a lightweight coordination sidecar should
  look like, `Manta` is currently the most interesting new comparator.
- **`agent-worktree-orchestrator` is philosophically close to the current line.**
  It reinforces conservative execution boundaries, audit artifacts, and human
  approval over ambitious substrate replacement.
  It mostly validates the current posture rather than changing it.
- **`wmux` is interesting, but for a different layer.**
  Its strongest ideas are in operator UX, Windows PTY persistence, and browser
  integration, not in the mutation-isolation and workspace-governance boundary
  currently under discussion.

So the ecosystem scan did produce something actionable, but it was not
"switch to `rift`." It was closer to:

- keep `rift` as a safety/backend reference
- keep `Manta` on the shortlist for future coordination-layer discussion
- keep treating worktree-first, conservative scaffolds as validation of the
  current narrow implementation path

### Main disagreements or emphasis differences

There was no real disagreement on the ultimate direction.
The differences were about emphasis.

- **GPT-5.2-Codex** emphasized discipline: borrow only guardrails.
- **Claude Haiku 4.5** emphasized abstraction boundaries: `rift` solves a
  different layer.
- **GPT-5.4 mini** was the most open to later borrowing from the identity and
  recovery model if workspace movement/reconciliation becomes real.
- **Copilot** emphasized that the strongest external novelty from the wider scan
  was actually `Manta`, not `rift`.

These were differences in weight, not direction.

### Decision

The maintained conclusion of this round is:

- **do not switch away from the `dmux` wrapper path because of `rift`**
- **treat `rift` as a complement/reference for future backend work, not as a
  near-term substitute**
- **borrow only narrow safety ideas now**

Concretely, the strongest borrowable ideas are:

1. add more explicit Git unsafe-state checks to `dmux preflight`
2. keep the current sharp distinction between shared checkout and isolated
   mutation workspace
3. if managed workspaces or copied workspaces ever become real later, make their
   identity and cleanup explicit rather than informal
4. document platform/backend limits honestly rather than pretending a broader
   substrate exists before it does

And the strongest non-borrow conclusion is:

- do **not** adopt a central registry / rooted workspace tree / `.rifts`
  storage plane / subtree lifecycle manager at this stage

### What to do next

The most practical follow-up sequence after this round is:

1. **Finish and publish the current `nix-dmux` guard slice.**
   The right response to `rift` is not more substrate shopping.
   It is to finish the wrapper work already underway.

2. **Strengthen `dmux preflight` with a small second pass of Git-state checks.**
   `rift` provides a good reference list for which unsafe in-progress states are
   worth blocking explicitly.

3. **Keep `Manta` on the watchlist for a future coordination-layer round.**
   If the next real problem turns out to be claims, heartbeats, contracts, or
   review orchestration rather than launch safety, `Manta` is the more relevant
   new comparator.

4. **Do not adopt a workspace-manager architecture until there is measured need.**
   If future evidence shows that linked worktrees are insufficient and managed
   copies are truly required, then `rift` becomes a stronger backend reference.
   But that should be a later, explicit escalation, not an opportunistic pivot.

### Bottom line

`rift` is a serious little workspace-manager design, and its Git-safety posture
is genuinely worth copying.

But it does **not** change the current strategic answer.
The present frontier is still:

- make the `dmux` wrapper load-bearing
- harden preflight and isolation rules
- and only escalate into a richer backend or coordination plane if real use
  proves the current seam too weak

So the correct posture is:
**borrow some rules, keep watching, but stay on the wrapper-first `dmux` path.**

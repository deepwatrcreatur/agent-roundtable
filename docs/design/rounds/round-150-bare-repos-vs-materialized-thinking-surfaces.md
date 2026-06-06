## Round 150 — Bare Repos vs. Materialized Thinking Surfaces

**Tags:** tooling, git, bare-repos, worktrees, cognition, workspace-layers, dmux, herdr  
**Status:** Closed  
**Voices used:** GPT-4.1, GPT-5.4 mini, Claude Sonnet 4.6, Copilot synthesis

### Round question

The maintainer asked for a roundtable discussion because a new operational pain
has appeared after the local move toward bare repositories:

- the repositories are now safer and cleaner as backing stores
- but agents are having more trouble **thinking about the repositories** because
  they are bare

So the real question was not merely whether bare repos are good or bad.
It was:

**Should the project explicitly separate canonical bare storage from a
materialized agent cognition surface, and if so what should the operating model
be?**

### Grounding used in this round

Relevant prior local context carried in:

- **Round 140** — `rift` is useful as a workspace-manager reference, but the
  current implementation frontier remains wrapper-first on `dmux`
- **Round 141** — `herdr` is a stronger long-term terminal-native control-plane
  candidate, but not a reason to abandon the current path now
- **Round 145** — bare-root plus per-agent worktrees is a real improvement in
  **repo-root policy**, but not a replacement for coordination, mutation
  isolation, or task selection
- **Round 146** — the five-layer model should be kept sharp:
  - repo-root policy
  - mutation boundary
  - coordination layer
  - task-selection layer
  - workspace backend

Fresh local problem statement carried in:

- after converting repos to bare backing stores, the user observed that agents
  are now having trouble browsing and reasoning about repositories
- this is not a hypothetical design preference; it is an observed cognition and
  tool-usage regression
- the split between bare backing stores and materialized worktrees already exists
  across the local workspace in practice, but it has not been made explicit
  enough as a harness contract

### Participation record

What actually happened in this run:

- **GPT-4.1:** substantive
- **GPT-5.4 mini:** substantive
- **Claude Sonnet 4.6:** substantive
- **Copilot:** substantive synthesis

This round therefore closes with a **three-seat substantive roster** plus Copilot
synthesis and prior local grounding.

### Voice summary

#### GPT-4.1

- Strongest on the direct claim that bare repos are excellent as canonical
  backing stores but insufficient as the primary cognition surface.
- Most direct that agents and humans need a **materialized, browsable workspace**
  for navigation, diffs, and incremental reasoning.
- Recommended the split:
  - bare repo as canonical backing store
  - read-only browse checkout for cognition
  - ephemeral writable worktrees for actions

#### GPT-5.4 mini

- Strongest on the framing:
  **bare storage as ledger, materialized surface as projection/cache**.
- Most explicit that the danger is letting the projection become a second source
  of truth.
- Strongest on the rule that agents may reason from the projection but must
  promote through canonical Git/worktree paths rather than mutating the
  projection as if it were authoritative.

#### Claude Sonnet 4.6

- Strongest on the claim that this is not a speculative future split; it is
  already much of the real workspace architecture and simply needs to be made
  explicit as policy.
- Most direct that handing a bare path to an agent is a **harness
  misconfiguration**, not an agent failure.
- Strongest on the operational answer:
  - canonical bare root
  - persistent read-mostly `main` worktree as default cognition surface
  - ephemeral writable worktree per attempt for mutation
- Most explicit that the harness, not the agent, should own surface selection.

#### Copilot

- I agreed with the outside convergence and with the earlier local rounds:
  the problem is not that bare repos were a mistake, but that **repo-root policy
  was allowed to masquerade as a full cognition model**.
- My strongest synthesis point is that the project needs a sharper
  **ledger / projection / mutation** split:
  - bare repo = ledger
  - materialized browse surface = projection
  - isolated writable worktree = mutation space
- This keeps the safety advantages of bare roots while restoring the actual
  surface agents use to read, search, and think.

### What the earlier rounds already established

This round does not overturn the recent workspace-layer history.
It mainly sharpens it.

#### 1. Bare-root was already judged as a repo-root policy improvement

Rounds 145 and 146 already converged that bare-root or blocked-root discipline
mainly solves one layer:

- **the shared root should not be the normal writable mutation surface**

That is real and useful.
It reduces root-checkout asymmetry and makes multi-agent editing defaults
cleaner.

But those same rounds also already said that bare-root does **not** by itself
provide:

- workspace allocation
- lifecycle management
- coordination
- task selection
- stale-success arbitration

This round adds one more missing piece:

- **bare-root also does not provide a good cognition surface**

#### 2. Worktrees solve mutation isolation more than they solve thought ergonomics

The earlier rounds were right to defend isolated writable namespaces.

But a linked worktree exists to provide:

- isolated edits
- isolated branch state
- safer promotion

It is not automatically the same thing as:

- a persistent browse cache
- an always-there read surface
- a stable cognition target for many agents and tools

In practice, agents often expect:

- files to exist at predictable paths
- `rg`, `glob`, editors, and LSP-like tooling to work against a materialized
  directory
- incremental cross-file reading without first provisioning a new editable
  workspace

That is what has now become operationally visible.

#### 3. The split already exists in practice and should be canonized

The late Sonnet seat sharpened an important point:

- this project has not discovered a brand-new architecture
- it has already implemented much of it

What is missing is not the existence of worktrees.
It is the explicit contract that says:

- bare roots are backing stores
- stable materialized worktrees are cognition surfaces
- ephemeral isolated worktrees are mutation surfaces
- agents should never be pointed at bare roots for normal reasoning

### First-pass convergence

The substantive voices converged on the following points.

1. **Bare repos are good as canonical backing stores.**
   They are strong for:
   - object storage
   - ref history
   - branch and promotion truth
   - removing the casual writable-root habit

2. **Bare repos are bad as the primary thinking surface.**
   They make repository state less directly explorable for agents and tools that
   reason through files, search, and local path traversal.

3. **The right answer is a layered split, not a reversion.**
   The project should not conclude:
   “bare repos were a mistake.”
   It should conclude:
   “bare repos belong at the storage layer, not at the cognition layer.”

4. **A materialized thinking surface should be treated as a projection, not a new
   authority.**
   This was the strongest mini-seat contribution.
   The browse surface must be:
   - rebuildable
   - disposable
   - refreshable
   - subordinate to canonical Git history

5. **Writable worktrees should remain distinct from read-optimized cognition
   surfaces.**
   The project should not blur:
   - “a place to read and think”
   with
   - “a place to mutate tracked state”

6. **Wrappers/control-plane policy still matters.**
   Once there are multiple surfaces, something still has to define:
   - where agents launch
   - when a writable worktree is created
   - what counts as browse-only vs mutation-capable
   - how promotions flow back to canon

7. **The absence of explicit surface-selection policy is the current bug.**
   The practical problem is not that the backing-store model is wrong.
   It is that agents are still sometimes being handed bare paths as if those were
   normal browse surfaces.

### Strongest case for a materialized thinking surface

The strongest pro case is straightforward:

**Agents reason through files, not through Git object databases.**

That means a useful thinking surface should provide:

- normal filesystem paths
- stable directory traversal
- easy search
- compatibility with code-reading tools
- compatibility with editor/LSP-style cognition aids
- low-friction “open file A, then B, then C” workflows

This is not merely a convenience.
It is part of the cognitive substrate that many agent/tool chains actually use.

If the canonical repo is bare, and nothing materialized exists by default, the
system has made the safe ledger available but made the actual thought surface
scarce.

That is a bad trade if it pushes agents toward awkward ad hoc checkouts or
weaker repository understanding.

### Strongest case against a persistent materialized layer

The strongest anti case is not that browse surfaces are pointless.
It is:

**a persistent projection can become stale, drift-prone, or misleading if it is
allowed to masquerade as the source of truth.**

That creates familiar failure modes:

- stale reads
- hidden divergence
- accidental writes in the wrong place
- local conclusions drawn from an out-of-date tree
- reintroduction of “looks current enough” errors

So the materialized thinking surface is only good if the project keeps the
boundary explicit:

- it is a **projection**
- not the ledger
- not the promotion authority
- not the mutation truth

### Recommended architecture

The strongest answer from this round is:

#### 1. Canonical storage: bare repo

The bare repository should remain the authoritative home of:

- Git objects
- refs
- branch tips
- promotion history
- the stable canonical repository identity

This is the ledger.

#### 2. Cognition surface: materialized read-optimized checkout

The project should maintain a materialized surface specifically for:

- search
- browsing
- cross-file reading
- indexing
- summaries / metadata projections
- agent understanding

This surface should be:

- refreshable from canon
- disposable
- preferably read-only by default or treated as non-authoritative
- cheap to recreate

Its job is to make the repo thinkable, not authoritative.

#### 3. Mutation surface: isolated writable worktrees

When an agent needs to change tracked state, it should move into:

- a dedicated linked worktree
- or another explicit isolated writable namespace

This surface is where:

- edits happen
- tests run against the attempted change
- commits or promotion artifacts are prepared

It should remain distinct from the cognition surface.

#### 4. Wrapper/control-plane policy above all three

Something like `dmux` now, and perhaps a richer layer later, should own:

- launch defaults
- browse vs edit mode distinction
- worktree creation policy
- cleanup
- status exposure
- promotion path back into canonical history

The earlier rounds were already correct that structure alone is not enough.
Policy still has to turn that structure into safe defaults.

One extra rule sharpened by the late Sonnet seat:

- **the harness should hand agents worktree paths, not bare-root paths**

That means surface selection belongs to the wrapper/control plane rather than to
ad hoc agent behavior.

### Operational model this suggests

The project should explicitly move toward:

1. **bare repo as backing store**
2. **one maintained materialized browse checkout per repo or per active branch**
3. **ephemeral writable worktrees per agent/task when mutation is required**

In other words:

- **thinking** happens against a materialized projection
- **changing** happens in isolated writable workspaces
- **truth** lives in the bare backing store and the promoted refs

This is a cleaner articulation of what earlier rounds were already reaching for.

### Durable conclusions this project should preserve

1. **Bare repos belong at the storage layer, not as the sole cognition layer.**

2. **A materialized browse/thinking surface is not a retreat from bare repos; it
   is the correct companion layer.**

3. **That thinking surface must remain subordinate, refreshable, and
   non-authoritative.**
   Treat it as a cache/projection, not as a second source of truth.

4. **Writable mutation should still happen only in isolated workspaces.**
   Do not collapse browse and mutation back into one casually writable root.

5. **Wrapper/control-plane policy remains necessary even with bare repos.**
   Bare structure improves repo-root policy; it does not eliminate the need for
   launch, lifecycle, and promotion discipline.

6. **Handing a bare repo path to an agent for normal repo reasoning is a harness
   misconfiguration.**
   Agents should receive a materialized path by default.

7. **The right architectural split is ledger / projection / mutation, not “bare
   vs worktree” as a false binary.**

### Recommendation now

The maintained recommendation is:

**Keep bare repos as canonical backing stores, but stop treating them as the
main surface agents are supposed to think against.**

Restore or create a materialized read-optimized browse surface for each active
repo, and keep writable linked worktrees as the explicit mutation path.

That preserves the safety and cleanliness benefits of bare roots while fixing
the now-observed cognition regression.

**One-sentence verdict for the round:** Bare repositories are the right
authoritative ledger for multi-agent repo storage, but they are the wrong
primary cognition surface, so the project should explicitly split canonical bare
storage from a refreshable materialized thinking surface and from isolated
writable worktrees used only for tracked mutation.

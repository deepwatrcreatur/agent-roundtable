## Round 142 — The Context Graph Model Above `jj`, Dolt, and Btrfs

**Tags:** structural, jj, dolt, btrfs, context-graph, governance, hosting  
**Status:** Closed  
**Voices used:** GPT-5.4, Claude Sonnet 4.6, GPT-4.1, GPT-5.4 mini, Copilot synthesis

### Round question

The maintainer asked for a roundtable on the proper model for the **context
graph** the project is trying to develop.

The question was not merely whether `jj`, Dolt, or Btrfs are each good tools in
isolation.

The sharper questions were:

- where this model fits in the historical evolution from:
  - Subversion-style reservations
  - Git distributed version control
  - and `jj` weakening branch centrality
- where the project should go next conceptually
- how to navigate currently available systems of developer tooling and code
  storage
- what the main remaining frictions are in the current combination of:
  - `jj` for code
  - Dolt for narrative / board-like records
  - Btrfs subvolumes for workspace boundaries
- and whether a switch to Neo4j or a more graph-database-centric approach would
  actually improve matters or mostly sacrifice ecosystem compatibility

### Grounding used in this round

Relevant prior local context carried in:

- **Round 48** — file reservations are still useful, but mainly as intent /
  scheduling metadata rather than as the core correctness boundary
- **Round 58** — strong Git compatibility remains a trust floor and market-entry
  requirement even if the host becomes more `jj`-native internally
- **Round 63** — embedded design memory should be hybrid:
  round archives for deliberation, `jj` metadata for local pointers, sidecars
  for bounded subtree summaries, and a Dolt-backed index for query / lifecycle
- **Round 65** — `jj` has a real but narrow present advantage, especially around
  rewrite-heavy local mutation, alternatives, and bounded local retrieval
- **Round 73** — the graph should be a **derived index / query layer**, not the
  canonical memory substrate
- **Round 112** — `jj` helps as a local mutation substrate, but the product
  opportunity remains above the VCS layer in governance, deliberation, memory,
  and execution discipline
- **Round 117** — the narrow host-native control plane should own:
  claims, leases, attempts, promotion gates, and review checkpoints
- **Rounds 134–141** — isolated mutation spaces matter more than ideology about
  one workspace substrate; backend abstraction matters; wrapper-first and
  claims/leasing should come before treating Btrfs as architecture

Relevant design notes carried in:

- `FORGE_CLAIM_LEASE_PROTOCOL.md`
- `JJ_VIRTUAL_WORKING_COPIES.md`
- `BOARD_EXECUTION_MODEL.md`
- `JJ_GUIDE.md`

Important local scope boundary carried into the round:

- the project still wants Git compatibility at the edge
- file reservations matter again, but mainly as intent metadata
- isolated mutation namespaces remain the real correctness boundary
- the practical direction is still wrapper-first isolation and backend
  abstraction, not a declaration that Btrfs itself is the model

### Participation record

What actually happened in this run:

- **GPT-5.4:** substantive
- **Claude Sonnet 4.6:** substantive
- **GPT-4.1:** substantive
- **GPT-5.4 mini:** substantive
- **Copilot:** substantive synthesis

This round therefore has a **four-seat substantive roster** plus Copilot
synthesis.

### Voice summaries

#### GPT-5.4

- Strongest on the line that the context graph should be a **derived governance
  graph**, not the canonical store.
- Treated the correct canonical split as:
  - `jj` for code lineage and local mutation history
  - markdown for deliberative legitimacy and archival prose
  - Dolt for structured board / governance / claim / lease / attempt state
  - workspace backends for isolation
- Most explicit that the hardest remaining frictions are the seams:
  - `jj` change IDs versus Dolt records
  - split conflict handling across code, relational state, and structural
    conflicts
  - identity fragmentation across change IDs, claims, attempts, leases, and
    workspaces
  - stale-success promotion after apparently clean local progress
- Most detailed on why Neo4j is the wrong center of gravity:
  it would add operational drag and query elegance without actually solving the
  core authority / promotion / coordination problem.

#### GPT-4.1

- Strongest on the line that the history from Subversion to Git to `jj` is
  really about shifting where correctness and coordination live.
- Framed:
  - Subversion reservations as explicit coordination
  - Git as decentralized mutation with weaker coordination semantics
  - `jj` as further decoupling work from branch-centered workflow assumptions
- Treated the next step as making the **context graph** a first-class layer above
  the VCS that unifies:
  - code state
  - narrative / deliberation state
  - workspace state
  - claim / lease state
- Most direct that the hardest frictions in the current stack are:
  - fragmented coordination
  - Dolt / `jj` split-brain risk
  - portability risk if Btrfs becomes more than a backend

#### Claude Sonnet 4.6

- Strongest on splitting the model into three planes:
  - **live coordination state** such as claims, leases, attempts, and virtual
    working copies
  - **durable governance memory** such as review state, supersession,
    deliberative archive, and conflict records
  - **derived views** such as board surfaces, dashboards, and graph/index
    products
- Most explicit that the context graph is needed because `jj` improves local
  mutation but does not itself create a coordination plane.
- Sharpened the `jj` ↔ Dolt seam as a lifecycle/transaction problem:
  code mutation state and governance/board state can diverge unless the system
  explicitly defines how attempt closure, workspace cleanup, supersession, and
  promotion transitions couple across those stores.
- Most willing to consider a lower-friction local write path, such as
  SQLite-first locally with Dolt promotion/export later, if Dolt local runtime
  overhead proves heavier than the current slice needs.

#### GPT-5.4 mini

- Strongest on the phrase **multi-authority context graph** rather than “graph
  database.”
- Argued that the real problem is not missing graph storage, but missing
  first-class **cross-authority joins** across:
  - code revision and local intent
  - workspace and mutable authority
  - lease and current mutation rights
  - decision records and the code regions or change lineages they govern
- Treated `jj + Dolt + Btrfs` as directionally correct but friction-heavy because:
  - `jj` is strong at local change evolution, but weak on shared coordination
  - Dolt is strong at queryable structured state, but not naturally fused to code
    mutation flows
  - Btrfs is operationally powerful, but dangerously tempting to overfit into the
    conceptual center of the system
- Most explicit that resisting Neo4j is strategically right if the reason is to
  preserve:
  - developer-tooling continuity
  - code-hosting compatibility
  - and a protocol-first architecture rather than a database-centered one

#### Copilot

- I agreed with the strongest convergence from both seats:
  the context graph should not be “the one magical graph that stores
  everything.”
- My strongest synthesis point was that the project is really trying to recover
  two things that earlier systems each handled partially:
  - from Subversion: explicit coordination / reservation signals
  - from Git: distributed, inspectable, forkable code history
  - from `jj`: a better local mutation model where branch identity is no longer
    the main unit of work
- But none of those alone solve the present multi-agent problem on one machine.
  The missing layer is a **control-plane graph** above them:
  claims, leases, attempts, promotion state, local design-memory pointers, and
  path-/change-scoped invariants.
- I also agreed with earlier local rounds that the graph should remain a
  query/index and protocol layer over canonical records rather than becoming the
  sole canonical authority.

### First-pass convergence

The substantive voices converged on the following points.

1. **The context graph belongs above the VCS layer, not as a replacement for it.**
   The project is not mainly trying to invent a new way to store blobs and trees.
   It is trying to make coordination, rationale, and authority visible and
   enforceable for multi-agent work.

2. **Subversion, Git, and `jj` each preserve something worth keeping.**
   - Subversion preserved explicit coordination signals
   - Git preserved distributed history and ecosystem compatibility
   - `jj` improves local mutation semantics by weakening branch-centrality and
     making rewrite-heavy work more natural

3. **Reservations should return, but in a demoted role.**
   The maintained line still holds:
   reservations are useful as intent / scheduling / early-routing metadata, not
   as the main correctness boundary.

4. **The real correctness boundary is isolated mutation space.**
   Private working copies, worktrees, subvolumes, sandboxes, or equivalent
   per-attempt mutation namespaces are the safety primitive that stops direct
   collisions.

5. **The real missing primitive is a cross-authority join model.**
   The current stack has multiple truths with different lifecycles:
   - code truth
   - narrative / board truth
   - workspace truth
   - mutable-authority truth
   The main design challenge is not how to put them all into one engine, but how
   to join them coherently.

6. **Neo4j is not the answer to the main pain.**
   A graph database may make some queries elegant, but it does not solve:
   - developer workflow continuity
   - Git/JJ hosting compatibility
   - local mutation ergonomics
   - or the distinction between canonical records and derived graph edges

7. **The graph should be a derived governance graph over explicit canonical
   records.**
   That means:
   - `jj` remains canonical for code lineage
   - markdown remains canonical for deliberative legitimacy
   - Dolt remains canonical for structured operational / governance state
   - the graph is the typed join and retrieval surface above them

8. **The model has distinct live, durable, and derived planes.**
   The round sharpened that not all context-graph state has the same temporal
   character:
   - live coordination authority is mutable and enforced
   - governance memory is durable and append-oriented
   - read models and graph views are reconstructable projections

### Historical interpretation

The round converged on the following historical reading.

#### 1. What Subversion got right

Subversion was weak on distributed autonomy, but it preserved something that the
project now wants back:

- explicit awareness that another actor is already working in a mutable region
- centralized truth about current edit intent
- a coordination model that existed before merge-time pain

That does not mean SVN-style locking should return as the default correctness
mechanism.
It means the **intent-signaling layer** that Git discarded needs a modern
replacement.

#### 2. What Git got right

Git is still the strongest mainstream answer for:

- distributed replication
- ubiquitous developer tooling
- hosting and CI integration
- forkability and transport continuity

The round did not support giving those advantages up.
Git compatibility remains a trust floor even if richer internal semantics exist.

#### 3. What `jj` improves

`jj` is meaningfully better than ordinary Git for:

- rewrite-heavy local mutation
- undo / operation-log recovery
- conflict-as-state rather than immediate fatal blockage
- change evolution without branch identity carrying so much conceptual weight

But `jj` still does **not** solve:

- task ownership
- shared-resource mutation authority
- promotion sequencing
- or design-memory / narrative joins by itself

So the right historical reading is:

- Subversion solved too much through centralized coordination
- Git solved too much through decentralized history
- `jj` improves local evolution semantics
- the next layer must restore coordination and memory **above** the VCS, not by
  replacing the VCS with a giant graph store

### The proper conceptual model

The strongest converged model is:

- **code graph** for source evolution and local change lineage
- **narrative graph** for reasoning, design memory, objections, outcomes, and
  board state
- **workspace / mutation graph** for private mutable namespaces
- **authority graph** for claims, leases, attempts, and promotion rights

The context graph is the **join layer** across those graphs.

Claude sharpened this further into three operational planes:

- **live coordination state**
- **durable governance memory**
- **derived read/query views**

That split fits the repo's earlier line that the graph should be a lens and
control surface over canonical records, not a monolithic single store.

Its job is to answer questions like:

- which active invariants apply to the path this agent is editing?
- what change or work item superseded the prior rationale here?
- which workspace is tied to this attempt?
- who currently holds the lease for the mutable scope this action would touch?
- what narrative record authorized or constrained this code mutation?

That means the context graph should be treated as:

- protocol surface
- query/index surface
- integration surface

and **not** as:

- one canonical graph database that swallows all other stores
- a replacement for Git/JJ transport and hosting
- a justification to make filesystem semantics the product boundary

### Main remaining frictions in `jj + Dolt + Btrfs`

The round repeatedly converged on the following frictions.

#### 1. Cross-authority joins are still awkward

The hardest present problem is that:

- `jj` tracks change evolution
- Dolt tracks structured state and queryable records
- Btrfs tracks isolated mutable namespaces

but the system still lacks one clean way to express:

- which change maps to which design-memory record
- which workspace belongs to which attempt lineage
- which lease protects which mutable scope
- which board state is active for the code being touched

This is the biggest current friction.

#### 2. Dual-history coordination remains awkward

The system still has to reconcile at least two durable histories:

- code evolution in `jj`
- structured operational/governance state in Dolt

That creates practical seam problems such as:

- linking `jj` change IDs to board / claim / attempt records
- deciding what “atomic enough” means across code and governance updates
- handling rewrite / undo / supersession on the code side without silently
  invalidating narrative or board state

The round sharpened that the issue is not that one of these tools should win.
It is that the join model is still too implicit.
Claude made this even sharper: the seam is fundamentally a missing
**lifecycle-coupling protocol** between code state and governance state.

#### 3. Lifecycle mismatch across the three layers

The three substrates have very different lifecycles:

- code history should replicate and remain durable
- narrative/task state may be updated, superseded, or narrowed often
- workspaces and leases are ephemeral, host-local, and expiring

The stack will keep feeling clumsy until those lifecycle differences are made
explicit in the model rather than hidden behind ad hoc joins.

#### 4. Conflict handling is still split

The current shape still has multiple kinds of conflict:

- `jj` textual / rebase conflict
- Dolt / relational conflict
- structural or policy conflict above both
- stale-success conflict where something stayed locally valid but became wrong
  after refresh on newer accepted history

The round converged that this is exactly where the context graph matters:
not as storage theater, but as a way to route and classify conflicts before
promotion.

#### 5. Developer UX is split across three mental models

Today the operator/developer has to think in:

- `jj` / Git terms for code
- SQL/Dolt terms for board and narrative state
- filesystem/backend terms for workspace isolation

The issue is not that these tools are individually bad.
The issue is that the composition is still too visible.
The project needs a thinner operator-facing protocol surface above them.

#### 6. Identity fragmentation is still too high

The same real-world object can still accumulate too many identifiers:

- `jj` change ID
- branch / bookmark / ref surface
- claim ID
- lease ID
- attempt ID
- workspace ID
- Dolt row / board object ID

That is tolerable only if the join model is explicit and tool-supported.
Otherwise the graph becomes another place where fragmentation is described rather
than reduced.

#### 7. Btrfs is powerful, but too tempting as architecture

Btrfs subvolumes are extremely useful for Linux-hosted isolation.
But the round agreed that overfitting to them creates several risks:

- portability loss
- design distortion toward one backend’s primitives
- confusion between “best current Linux implementation” and “the model”

The right line remains:
**Btrfs is a serious backend, not the architecture.**

#### 8. Dolt is valuable, but can become a second authority unless bounded

The round did not reject Dolt.
It treated Dolt as one of the strongest current candidates for:

- structured narrative records
- board/work-item state
- queryable lifecycle metadata

But it also sharpened a risk:
if Dolt starts to feel like an equal second canonical truth about code rather
than the canonical structured record layer for narrative / control-plane state,
the system becomes split-brained.

The most stable line from this round is:

- `jj` owns code lineage
- markdown owns deliberative legitimacy
- Dolt owns structured operational / governance state
- the context graph joins them

The fix is not “remove Dolt.”
It is to define more clearly:

- what Dolt canonically owns
- what `jj` canonically owns
- what is ephemeral backend/workspace state
- and what the join keys are between them

#### 9. The current stack still under-represents mutable authority

The project already knows this from claims/leases work:

- code versioning does not equal mutation authority
- workspace existence does not equal lease ownership
- narrative agreement does not equal promotion permission

This means the next friction-reducing move is not a different graph database.
It is making **authority objects** first-class:

- claims
- leases
- attempts
- review states
- promotion gates

### What to keep

The round converged clearly on keeping:

- **Git compatibility at the edge**
- **`jj` as a strong local mutation substrate**
- **Dolt or Dolt-like relational/queryable structured state for governance,
  board, and lifecycle records**
- **markdown as the canonical deliberative archive**
- **isolated mutable namespaces by default**
- **backend abstraction for Btrfs/APFS/ZFS/directory fallbacks**

### What to change

The strongest change recommendations were:

1. **Stop treating the stack question as mainly a storage-engine question.**
   The main need is protocol and join clarity, not a shinier canonical database.

2. **Define the context graph explicitly as a multi-authority join model.**
   The model should declare:
   - canonical authorities
   - join keys
   - lifecycle classes
   - projection surfaces

3. **Treat the graph as a derived governance graph, not the canonical store.**
   This keeps:
   - query power
   - conflict routing
   - promotion reasoning
   while avoiding graph-database-first architecture drift

4. **Make claims/leases/attempts first-class everywhere they matter.**
   The project has already conceptually arrived here.
   It should make these objects part of the standard control-plane vocabulary.

5. **Treat Btrfs as an optimization / backend, not as a semantic requirement.**
   The architecture should survive APFS, ZFS, and simpler fallbacks.

6. **Give operators a thinner integrated surface.**
   The stack should feel less like:
   - “open `jj`, then SQL, then inspect subvolumes”
   and more like:
   - “claim this work, get isolated mutation space, see applicable rationale,
     mutate, refresh, and promote”

7. **Stay open to a lighter local governance-store write path if needed.**
   The round still favors Dolt for structured governance state overall, but it
   also surfaced a legitimate question:
   if a SQLite-first local write path dramatically lowers current friction
   without sacrificing later Dolt export/promotion, that may be the more
   practical first slice.

### What not to chase

The round rejected or warned against:

- making the graph itself canonical
- adopting Neo4j as the center of gravity
- pretending `jj` alone solves multi-agent coordination
- treating Btrfs-specific primitives as product identity
- reopening the VCS war when the real gap is governance / coordination / memory

### Final synthesis

The strongest answer from this round is:

- the project is not mainly building a better database for code
- and it is not mainly building a prettier graph over documents
- it is building a **derived governance / context graph** that reconnects things the
  last generations of tooling split apart:
  - intent
  - mutation rights
  - workspace boundaries
  - code evolution
  - narrative memory
  - promotion legitimacy

In historical terms:

- Subversion preserved explicit coordination, but made the system too centralized
- Git preserved distributed history, but externalized too much coordination
- `jj` improves local mutation semantics, but still does not supply shared
  authority or narrative joins

So the next conceptual move is:

- keep Git-compatible code transport
- keep `jj`-friendly local mutation
- keep a structured record substrate such as Dolt for narrative/control-plane
  state
- keep isolated mutation namespaces
- and add a **first-class join / control-plane model** above them

That is the proper role of the context graph.

### Recommendation

Treat the context graph as a **portable protocol for joins across code,
narrative, workspace, and authority state**.

Do not turn it into:

- a filesystem-specific architecture
- a VCS replacement thesis
- or a graph-database ideology project

The right near-term direction is to make the current stack more explicit and less
accidental, not to discard it for a more fashionable substrate.

### Practical next moves

1. **Define the canonical authorities and join keys**
   - what `jj` owns
   - what Dolt owns
   - what the workspace backend owns
   - what claims/leases/attempts own
   - how those objects reference one another

2. **Define lifecycle classes explicitly**
   - durable replicated code state
   - supersedable narrative/control-plane state
   - ephemeral workspace / lease state

3. **Prototype one end-to-end “claimed workspace” flow**
   - claim work
   - allocate isolated mutation space
   - surface bounded local rationale
   - mutate
   - refresh on accepted head
   - promote or arbitrate

4. **Keep backend abstraction honest**
   - validate the model against Btrfs, APFS, ZFS, and a plain directory fallback
   - confirm that Btrfs-specific power is optimization, not ontology

5. **Delay Neo4j unless a specific irreplaceable query need appears**
   - and even then, treat it as an optional derived index or read model, not the
     primary source of truth

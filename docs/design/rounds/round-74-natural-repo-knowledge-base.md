## Round 74 — The Natural Repo-Native Knowledge Base

**Tags:** structural, tooling, epistemic-integrity
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, `opencode/big-pickle`, `opencode/nemotron-3-super-free`, Copilot synthesis  
**Additional note:** `opencode/minimax-m2.5-free` did not return a usable bounded answer for this round and was excluded from synthesis  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wanted one more closely related round after the graph-index
discussion.

This round asked a slightly different question:

- is there a **natural knowledge base** that grows out of the repo's explicit
  embedded deliberation, work lineage, incident/fix memory, and `jj` revision
  history
- if so, what exactly is canonical versus derived
- what should graph/view/query tools do to make that knowledge base legible
  without turning it back into hidden or inferred state
- how should tools like Graphify relate to that knowledge base

### Relevant prior context

This round built directly on:

- **Round 61** — validated repairs need durable fix/incident/discovery records
- **Round 62** — preserve the split between discussion, board, and
  long-horizon memory/governance
- **Round 63** — embedded memory should be hybrid and supersession-aware
- **Round 65** — `jj`-native revision-aware rationale is a real, if still
  narrow, design advantage
- **Round 70** — borrow from external tools selectively without collapsing the
  architecture

### Current hypothesis examined in this round

The round took seriously the idea that a `jj`-native host with embedded
deliberation may already imply a repo-native knowledge base made of:

- round archives
- structured decision / incident / fix records
- board work-item lineage
- links to actual repository changes and supersession
- durable retrieval surfaces for humans and agents

The question was whether that is a real knowledge base or just an appealing
metaphor.

### Participation record

What actually happened:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Big Pickle:** substantive
- **Nemotron 3 Super free:** substantive
- **MiniMax M2.5 free:** not used in the final synthesis

### Voice summaries

#### Codex

- Strongest on the hard distinction between:
  - canonical durable records
  - derived navigation/query layers
- Treated the knowledge base as the explicit, versioned, supersession-aware
  record set in the repo, not "the graph."
- Treated Graphify-like tools as viewers / study aids over that record set.

#### Gemini

- Strongest on the "knowledge base as workflow exhaust" idea.
- Argued that the repo becomes a real knowledge base only if the durable record
  layer is a natural byproduct of work rather than a secondary curation chore.
- Treated `jj` supersession as the backbone for invalidating outdated knowledge.
- Recommended standardizing the record-linking schema before building viewers.

#### Big Pickle

- Strongest on the minimalist skepticism:
  a real knowledge base exists, but it may be much simpler than ambitious
  knowledge-infrastructure rhetoric suggests.
- Reduced the natural model to:
  - Artifacts
  - Decisions
  - Links
- Claimed the highest-value first tool is a link linter and a `jj` supersession
  query, not graph visualization.

#### Nemotron 3 Super free

- Strongest on the straightforward affirmative framing:
  the repo already contains durable knowledge artifacts and should expose them
  through a strictly derived, read-only graph/query service.
- Warned against derived surfaces becoming hidden authority.

#### Copilot

- Agreed that the "natural knowledge base" idea is real **if and only if**
  canonical records remain explicit and derived layers never outrank them.
- Treated the key opportunity as making project knowledge legible rather than
  recoverable only through tacit maintainer memory or giant agent context
  windows.

### First-pass convergence

All substantive voices converged on the following points.

1. **There is a real repo-native knowledge base here.**
   The round did not treat this as empty metaphor. The project's own artifact
   shape already points toward a real structured memory system.

2. **The knowledge base is not the graph.**
   The graph is a viewing / query / study surface over explicit canonical
   records.

3. **`jj`-native supersession materially strengthens the knowledge model.**
   Compared with ordinary git-hosting, `jj` makes "what replaced what, and why"
   more explicit and navigable, which matters directly for durable memory.

4. **The natural canonical units are fairly clear.**
   The most repeated units were:
   - rounds
   - decisions
   - invariants
   - incidents
   - fix records
   - work items
   - concrete `jj` changes

5. **The biggest danger is hidden derived authority.**
   If inferred clusters, similarity edges, or visualization artifacts become
   more trusted than the underlying explicit records, the project has merely
   hidden the knowledge again in a new layer.

### What the round treated as canonical

The strongest converged canonical layer was:

- immutable round archives
- decision records
- invariant records
- work-item lineage
- incident / fix records
- explicit supersession / traceability links
- links from those records to concrete `jj` changes

The round repeatedly rejected:

- making graph topology canonical
- making embeddings or clustering canonical
- making agent-generated summaries canonical

### What the round treated as derived

Derived layers considered legitimate:

- topic or subsystem discovery indexes
- relationship views and lineage chains
- search surfaces and retrieval bundles
- graph visualizations
- query/export services over the explicit record set

The round's common rule was:

derived layers are acceptable when they remain read-only, regenerable, and
visibly subordinate to the canonical record layer.

### What `jj` changes

The strongest repeated `jj`-specific point was:

ordinary git-hosted memory often loses or weakens supersession, alternatives,
and non-landed rationale by scattering it across rebases, squashes, issue
threads, or tacit human knowledge.

A `jj`-native design can instead make:

- revision lineage
- replacement chains
- rejected alternatives
- explicit supersession

first-class navigable relations inside the repo's durable artifact set.

### What role Graphify-like tools should play

The round converged on a restrained role:

- **viewer**
- **study aid**
- **query surface**
- **bootstrapper only with caution**

It rejected treating Graphify-like tooling as:

- the canonical memory model
- a writable database
- a hidden inference engine that outranks explicit records

Big Pickle in particular pushed the hardest minimal form:

- a link linter
- a checked-in adjacency list
- one compelling `jj` supersession query

before any broader graph infrastructure.

### What to build first

The strongest combined first steps were:

1. Standardize minimal schemas for:
   - decision
   - invariant
   - incident
   - fix
   - work item linkage
2. Add explicit supersession / traceability fields.
3. Build a durable "what is current vs superseded" index.
4. Build one or two high-value queries:
   - what is the current decision on X
   - what superseded this guidance
   - what incidents/fixes exist for this failure mode
5. Only after that, add richer graph visualization or exploration.

### Closure

The round closes with the following rules.

#### 1. Treat the repo as the database

The canonical knowledge base lives in explicit repo artifacts plus their
supersession-aware links.

#### 2. Keep derived surfaces subordinate

Visualization, query, and graph layers are useful only when they remain honest
projections over explicit state.

#### 3. Let `jj` lineage carry real semantic weight

The strongest unique value here is not "graph UI," but explicit replacement and
revision-aware rationale.

#### 4. Build schema and link integrity before graph UX

An honest thin knowledge base beats an impressive but inferred one.

#### 5. Make the knowledge base legible by default

If it only exists in hidden agent context or in a derived graph, the project has
missed the point.


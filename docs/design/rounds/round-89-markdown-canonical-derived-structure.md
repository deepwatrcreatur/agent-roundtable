# Round 89 — Markdown as Canonical Memory, Structured Indices, and Board-Integrated Resource Claims

**Status:** Closed  
**Tags:** structural, tooling, epistemic-integrity, governance  
**Voices used:** Copilot synthesis, local repo grounding  
**Additional note:** this round was prompted by two linked concerns: whether
markdown remains the right long-horizon storage substrate for both humans and
agents, and whether the new contention / lock model should ultimately live in
the bulletin board orchestration system

### Round question

The maintainer wanted a follow-up discussion on:

- whether markdown is still the right storage medium if agents need stronger
  machine readability, tag search, and structured retrieval
- whether the popularity and human readability of markdown are strong reasons to
  keep it
- whether the project should move to a better structured storage system instead
- how the emerging lock / contention system should integrate with the bulletin
  board orchestration model

### Relevant prior context

This round built directly on:

- **Round 62** — keep discussion, execution dispatch, and long-horizon memory as
  distinct layers
- **Round 73** — the graph/index layer should be derived, not canonical
- **Round 74** — the repo-native knowledge base should be explicit records plus
  derived query/view layers
- **Round 85** — `jj` metadata and change lineage are useful precisely because
  they remain legible inside ordinary repo artifacts
- **Round 87** — prediction calibration should be linked to graph outcomes
  through explicit structured fields
- **Round 88** — resource contention should become explicit queue/board/daemon
  semantics, not merely prose reminders

### Local grounding

The repo already embodies a hybrid answer:

- rounds and related design docs are markdown and work well for human review,
  diffs, `jj` lineage, and ordinary repo browsing
- work items already use small structured headers like `Status:` and `Tag:`
- the board execution model already expects structured tables for task state,
  attempts, leases, workflow policies, and heartbeats
- newer rounds are increasingly adding explicit machine-readable headers and
  typed fields rather than relying only on prose

So the real question is not "markdown or structure?" but **which layer should be
canonical for which kind of knowledge**.

### First-pass convergence

The round converged on the following points.

1. **Markdown should remain the canonical human-facing medium for rounds and
   design memory.**
   It is:
   - ubiquitous
   - easy to diff and review in git / `jj`
   - robust under ordinary repo tooling
   - readable without specialized infrastructure
   - naturally compatible with long-form disagreement, rationale, and audit

2. **Markdown alone is not enough for high-quality machine retrieval and
   orchestration.**
   Tag search, typed queries, prediction/outcome matching, and resource
   contention rules all become brittle if they rely on free-text scraping alone.

3. **The right move is a hybrid model: canonical markdown plus derived structured
   indices.**
   The project should not abandon markdown; it should derive structured layers
   from it where needed, and store inherently operational state in structured
   tables from the beginning.

4. **Execution state and resource locks belong in the board/orchestration layer,
   not in markdown.**
   A live-resource mutation lease is operational state:
   - time-bounded
   - claimable
   - renewable
   - expirable
   - enforceable at dispatch time
   That makes it a poor fit for markdown as the primary source of truth.

5. **Markdown should describe policy; structured tables should enforce it.**
   The docs should explain the contention model, but the board / daemon layer
   should carry the real resource-class and lease semantics.

6. **Machine readability should come from explicit fields and extraction, not by
   replacing prose with opaque databases.**
   The right pattern is:
   - small explicit headers in markdown
   - typed sidecar or extracted records where needed
   - derived indices for search/query
   - structured operational tables for live execution state

### Why markdown should stay

The round treated markdown as valuable for reasons beyond mere familiarity:

- it keeps long-form reasoning and disagreement legible
- it works naturally with repo history and `jj` supersession
- it avoids hidden state trapped inside tools or databases
- it keeps the project inspectable to humans who arrive with ordinary git-hosting
  habits
- it lowers the cost of reading, editing, and reviewing design memory

The round specifically rejected a full move to database-only design memory,
because that would make legitimacy and audit depend too much on custom tooling.

### Why markdown alone should not carry everything

The round was equally clear that some uses are a poor match for markdown-only
storage:

- tag-centric retrieval across many rounds
- typed link traversal
- prediction-to-outcome joins
- subsystem-scoped calibration summaries
- live resource claims / lock state
- runtime scheduling constraints

These need more explicit structure than prose archives can reliably provide by
themselves.

### Recommended storage split

The strongest converged split was:

#### 1. Canonical markdown layer

- round archives
- long-form design rationale
- synthesis docs
- human-readable work-item descriptions

#### 2. Canonical structured operational layer

- board work items
- attempt lineage
- workflow definitions
- human gates
- heartbeats
- resource claims / exclusive leases
- prediction / outcome records where live joining matters

#### 3. Derived structured index layer

- tag index over rounds
- typed cross-links
- adjacency and lineage exports
- search bundles
- graph/query surfaces

This preserves human legibility while allowing agents to query explicit derived
structure instead of scraping prose every time.

### What this means for tags

The round treated the newly repaired `**Tags:**` headers as a step in the right
direction, but not the endpoint.

The likely next stage is:

- standardize a small metadata vocabulary for rounds
- parse those headers into a structured index
- expose query paths over that index
- keep the markdown file as the legitimacy anchor

So the answer is not "stop using markdown because tags are awkward." It is:
**keep markdown, but stop making raw markdown parsing the only machine-readable
surface.**

### What this means for locks / contention

The round answered the bulletin-board question directly:

- yes, the lock / contention model should integrate into the board
- no, markdown should not be the enforcement surface for locks

The board should eventually carry resource-scoped fields such as:

- `contention_class`
- `resource_scope`
- `exclusive_lease_required`
- resource-affinity / resource-conflict rules in workflow or work-item policy

The local daemon should then respect those claims at dispatch and lease-renewal
time.

### Concrete recommendation now

1. Keep rounds canonical in markdown.
2. Add stronger, explicit metadata headers where useful.
3. Build a derived structured round index for tags and typed retrieval.
4. Keep operational execution state, including contention locks, in board tables
   rather than prose docs.
5. Treat markdown as the legitimacy/audit layer, structured indices as the query
   layer, and board tables as the enforcement layer.

### One-sentence verdict

The project should keep markdown as the canonical human-readable memory format,
add derived structured indices for machine retrieval, and place live contention
locks squarely inside the bulletin board / daemon orchestration layer rather
than trying to make prose docs carry enforceable operational state.

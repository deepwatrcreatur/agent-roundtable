## Round 73 — A Deliberation Graph Index, Not a Canonical Graph

**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, `opencode/big-pickle`, `opencode/ring-2.6-1t-free`, Copilot synthesis  
**Additional note:** `opencode/minimax-m2.5-free` and `opencode/nemotron-3-super-free` drifted into repo/tool exploration rather than returning a clean bounded answer, so they were excluded from synthesis  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wanted a follow-up on whether the project's current
chronological-markdown memory is enough, or whether the next stage should
include a graph-structured knowledge product for deliberation and fix
preservation.

The narrower question was:

- is a graph layer genuinely useful here or just another summarization artifact
- what should stay canonical: prose rounds, structured records, graph edges, or
  some combination
- what kind of node / edge types would actually matter for this project's
  deliberation and preservation goals
- what should be borrowed from tools like Graphify, and what should not

### Grounding facts used in this round

The round was grounded in public facts about `safishamsi/graphify`:

- the repo is **MIT licensed**
- it builds a queryable graph over folders of code / docs / media
- it emits artifacts such as:
  - `graph.html`
  - `GRAPH_REPORT.md`
  - `graph.json`
- it supports hook-based updates, optional MCP exposure, multiple export
  surfaces, and a workflow where graph outputs can be committed as durable
  derived artifacts
- its architecture follows an extraction/build/cluster/analyze/report/export
  pipeline

### Relevant prior context

This round built directly on:

- **Round 61** — fix cards, incident records, and discovery indexes are
  necessary to stop losing validated knowledge
- **Round 63** — embedded memory should be hybrid and supersession-aware
- **Round 70** — durable execution semantics belong in the board, not in a
  heavyweight external workflow engine

### Participation record

What actually happened:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Big Pickle:** substantive
- **Ring 2.6 1T free:** substantive
- **MiniMax M2.5 free:** drifted into repo exploration, excluded
- **Nemotron 3 Super free:** drifted into repo exploration, excluded

### Voice summaries

#### Codex

- Strongest on the three-layer hybrid:
  - canonical prose
  - canonical structured records
  - derived graph/index layer
- Treated the graph as a retrieval/navigation product, never the source of
  truth.
- Emphasized the difference between authored canonical edges and derived
  non-canonical similarity / cluster edges.

#### Gemini

- Strongest on the deterministic materialized-view approach.
- Rejected generic LLM-inferred graphs as a legitimacy risk.
- Recommended explicit frontmatter / tags and a deterministic graph export.
- Supported a small query surface or CLI/MCP tool only after the explicit edge
  schema exists.

#### Big Pickle

- Strongest on the claim that the project already has most of the raw material:
  rounds, work items, typed links, fix preservation ideas, and Dolt-backed
  structures.
- Rejected Graphify code reuse as a stack mismatch.
- Favored a small, static, derived graph index over any live graph runtime.

#### Ring 2.6 1T free

- Strongest on the "three tiers" framing:
  prose rounds, structured decision records, derived deliberation graph.
- Stressed that Graphify's ontology is about codebase discovery, not
  deliberation preservation.
- Recommended delaying any graph index until structured decision records are
  first proven.

#### Copilot

- Agreed with the converged answer:
  the graph is useful precisely because it is **not** the canonical memory
  layer.
- Treated the biggest value as reducing linear prose traversal for agents while
  preserving prose as the legitimacy anchor.

### First-pass convergence

All substantive voices converged on the following points.

1. **A graph layer is useful, but only as a derived index.**
   The round did not support replacing the archive with a canonical graph.

2. **Chronological prose still matters.**
   Rounds remain the legitimacy / audit surface because they preserve what was
   said, by whom, in what order, and with what disagreement.

3. **Structured records are the real missing canonical layer.**
   The most important next step is not graph visualization but explicit records
   for decisions, incidents, fixes, invariants, and related lineage.

4. **Graphify is a design-pattern source, not the right canonical substrate.**
   The pipeline idea is useful. The repo's ontology and Python implementation
   are not the right direct dependency for this Elixir / deliberation-focused
   system.

5. **False structure and legitimacy drift are the main risks.**
   If inferred relationships become trusted more than explicit records, the
   project recreates hidden state rather than reducing it.

### Recommended hybrid

The strongest converged model was:

#### 1. Canonical prose layer

- round notes
- synthesis documents
- append-only audit of discussion and closure

#### 2. Canonical structured record layer

- decisions
- incidents
- fix cards / repair patterns
- invariants
- work-item linkage
- explicit supersession and traceability fields

#### 3. Derived graph/index layer

- graph JSON or similar derived artifact
- compact adjacency and lineage surfaces
- queryable path for agents and dashboards
- graph visualization only as a study/view layer

### Candidate node and edge types

The round repeatedly converged on a small set of useful entities:

- `Round`
- `Decision`
- `WorkItem`
- `Incident`
- `FixCard`
- `Invariant`
- `Surface` / subsystem / module
- optionally `AgentPosition` where disagreement provenance matters

Most useful edges:

- `supersedes`
- `implements`
- `blocked_by`
- `caused_by`
- `mitigated_by`
- `decided_in`
- `applies_to`
- `evidence_for`
- `evidence_against`

The round strongly preferred:

- a few explicit, high-signal typed edges
- clear separation between authored canonical edges and derived suggestive ones

### What to build first

The converged first steps were:

1. Define structured record schemas for decisions, incidents, fix cards, and
   work-item linkage.
2. Add explicit supersession / traceability fields.
3. Backfill the highest-value historical items first rather than the whole
   archive.
4. Generate a static derived graph/index artifact from those records.
5. Only then consider richer graph queries, servers, or visual tooling.

The round repeatedly rejected starting with:

- a graph database
- an always-on query server
- heavy Graphify integration
- generic semantic inference over prose

### Closure

The round closes with the following rules.

#### 1. Do not make the graph canonical

The graph is a lens over canonical memory, not canonical memory itself.

#### 2. Prose remains the legitimacy anchor

Agents may use the graph to find what to read, but not to replace reading when
nuance or contestation matters.

#### 3. Build records before graph features

The graph only becomes honest after the canonical record layer exists.

#### 4. Borrow Graphify's pipeline idea, not its whole stack

Extraction / build / report / export is useful as a pattern. Canonical
deliberation semantics must remain local.

#### 5. Optimize for bounded retrieval, not pretty visualization

The graph is valuable if it cuts token cost and recovers active constraints
quickly. Anything else is secondary.


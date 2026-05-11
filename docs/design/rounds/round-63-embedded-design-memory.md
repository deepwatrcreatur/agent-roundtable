## Round 63 — Embedded Design Memory in `jj` / Code Context

**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, Copilot synthesis  
**Claude:** Omitted by maintainer preference for this run

### Round question

Independent agents keep reintroducing regressions because validated fixes and
design reasons are not remembered locally enough when later edits happen.

The project already has legible design history in round artifacts, but it is
moving toward history embedded within `jj` and thus more context-specific,
closer to affected code, less demanding on context windows, while still
preserving local design intent.

The round asked:

- what should "history embedded within `jj` and code context" concretely mean?
- what data should live near code versus in round archives versus in the task
  board?
- should design memory be represented as:
  - change metadata
  - sidecar files
  - code annotations
  - Dolt rows keyed by path / change
  - or some hybrid?
- how should this integrate the three-facet system:
  - `agent-roundtable`
  - the bulletin board
  - Vaglio / `jj`
- what are the next implementation steps that most reduce regression risk soon?

### Relevant prior context

This round built directly on two earlier conclusions:

- **Round 61** — fix preservation requires stronger durable operational memory
  than round archives alone
- **Round 62** — the bulletin board should become the execution-dispatch layer,
  with `dmux` demoted to operator console

The local work-item set also mattered:

- Work Item 49 — Virtual Working Copies (`jj`)
- Work Item 56 — Design History Integration (Embedded Model)

### Voice summaries

#### Codex

- Strongest on the need for **one canonical design-memory record model** rather
  than letting commit text, comments, and board entries compete as parallel
  truths.
- Favored a hybrid architecture:
  - canonical structured records keyed by path and `jj` change context
  - thin projections into sidecar files
  - selective code-local annotations
  - review-time surfacing
- Pressed hardest on lifecycle and supersession: old design memory must be
  explicitly replaceable rather than silently lingering forever.

#### Gemini

- Strongest on the metaphor that design memory should become a **geological
  record** rather than just an archive library.
- Emphasized "tethering" code to prior round / fix lineage so an agent entering a
  subtree can see the ghosts of earlier design decisions before breaking them.
- Favored:
  - `jj` change descriptions / metadata
  - subtree sidecars such as `_DESIGN.md`
  - a queryable provenance index
- Stressed that task-board state should remain execution-focused, not become the
  primary design-memory substrate.

#### DeepSeek

- Strongest on separating:
  - local intent near code
  - deliberative history in round artifacts
  - live execution state in the board
- Favored a **hybrid `jj` metadata + Dolt failure / fix index** model.
- Sharpened the need for bounded subtree lookup:
  agents should be able to ask what active fix records and recent design
  intentions apply to the path they are editing without ingesting whole rounds.
- Pushed hardest on operational validation: the system must prove that agents
  actually consult the metadata before edits.

#### Copilot

- Agreed with the hybrid direction and the need to preserve round archives while
  moving relevant intent closer to code.
- Emphasized the three-facet split:
  - roundtable = design reasoning and closure
  - board = live execution dispatch
  - Vaglio / `jj` = durable local memory substrate
- Accepted the strongest common constraint:
  embedded memory must remain **bounded, queryable, and supersedable**, or it
  becomes cargo-cult noise.

### First-pass convergence

All four voices converged on the following points.

1. **Round archives remain necessary, but they are not sufficient.**
   They preserve deliberative history, alternatives, and consensus, but they are
   too far away from the code path that a later agent is editing.

2. **Design memory should move closer to the edited subtree.**
   An agent working in a path should be able to discover the most relevant prior
   intent with bounded context rather than by replaying whole historical rounds.

3. **The right answer is hybrid, not singular.**
   No single representation is enough.
   The converged architecture combines:
   - canonical structured records
   - `jj`-native change context
   - local sidecar / projection surfaces
   - selective code-local annotations

4. **There must be one canonical memory record, not many competing ones.**
   Thin projections may appear in several places, but they must all point back to
   a single authoritative record model with explicit lifecycle / supersession.

5. **The task board should not become the design-memory warehouse.**
   It should carry live task linkage and execution pointers, not the full
   long-horizon rationale system.

6. **Supersession is mandatory.**
   Embedded design memory that cannot be marked stale, replaced, or narrowed will
   become cargo-cult baggage.

### Converged placement of information

The panel converged on the following placement rules.

#### Near code / subtree

Keep only the information needed for bounded local editing:

- current invariants
- "do not break" constraints
- pointers to the active canonical design-memory record
- possibly thin sidecar files for directory / subsystem context

#### In round artifacts

Keep the full deliberative record:

- alternatives considered
- trade-offs
- argument history
- satisfaction / closure state

#### In the task board

Keep live execution state:

- current task
- assignee / lease
- dispatch state
- links to the relevant design-memory record

The board is the traffic controller, not the archive of design truth.

### Converged representation model

The strongest cross-voice answer was:

- **canonical structured design-memory records**
  keyed by path / subsystem and `jj` change context
- **`jj` metadata / description fields**
  carrying local intent pointers
- **thin sidecars**
  for subtree-scoped invariant summaries
- **selective code annotations**
  only where local static discoverability is genuinely important
- **a Dolt-backed index**
  for querying active fix / design records and their lifecycle state

In short:

```text
round archives = deliberation
jj metadata    = local change-context pointers
sidecars       = bounded subtree summaries
Dolt index     = canonical query / lifecycle substrate
task board     = execution linkage
```

### Closure

The round closes with the following design rules.

#### 1. Keep round history, but demote it from sole memory substrate

Round artifacts remain the canonical deliberative archive, but agents should not
need to ingest full rounds to avoid breaking a known local invariant.

#### 2. Introduce one canonical structured design-memory record

That record should support:

- explicit status
- supersession
- active / stale lifecycle
- path / subsystem lookup
- links back to the originating round(s)

#### 3. Project that record into `jj` and local code context

Agents need bounded retrieval in the local subtree they are editing.
This implies:

- `jj`-visible intent pointers
- subtree sidecar summaries
- optional local annotations where warranted

#### 4. Keep the board linked, but secondary

The board should surface the relevant design-memory record for the task, but it
should not become the canonical home of rationale.

#### 5. Build for supersession from the start

Any embedded memory system that cannot say:

- current
- stale
- superseded-by

will quickly turn into an unreliable pile of ghost constraints.

### Immediate roadmap implications

The converged near-term sequence was:

1. create a canonical fix / design-memory index with explicit lifecycle
2. add `jj`-native metadata / hook support so relevant intent is surfaced during
   local work
3. add a bounded subtree query surface that returns:
   - active records
   - recent relevant change context
   - links to deeper round history

### Consensus summary

The consensus answer is:

- **yes**, the project should move from archive-only memory toward embedded local
  design memory
- **no**, this should not mean replacing round history
- **yes**, the right answer is hybrid:
  canonical structured records + `jj` context + sidecars + selective local
  annotations
- **critical guardrail:** there must be one canonical memory record model with
  explicit lifecycle / supersession


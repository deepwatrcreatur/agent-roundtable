## Round 70 — What to Borrow from Multica and Conductor

**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, `opencode/big-pickle`, `opencode/ring-2.6-1t-free`, `opencode/minimax-m2.5-free`, Copilot synthesis  
**Additional note:** `opencode/nemotron-3-super-free` was launched but did not return a usable answer body in this environment  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wanted a follow-up round on what this project should borrow from
other orchestration tools such as **Multica** and **Conductor**.

The goal was not to replace the local design, but to answer a narrower question:

- what ideas are genuinely worth stealing
- what code is safe or unsafe to reuse
- what belongs in `agent-roundtable` versus the future bulletin board versus
  Vaglio
- what should be rejected because it conflicts with the already-converged
  architecture

### Relevant prior context

This round builds directly on **Round 62**, which already converged on the
three-way split:

- `agent-roundtable` for structured design discussion
- a bulletin board / task system for execution dispatch
- Vaglio for forge, governance, and long-term memory

That earlier round already rejected a future centered on many supervised tabs as
the canonical operator surface. The remaining question was how to sharpen the
board and execution layers without reopening the broader architectural decision.

### Grounding facts used in this round

#### Multica

Public materials for `multica-ai/multica` present it as an open-source managed
agents platform where agents are treated as teammates assigned to issues on a
board. Its public architecture emphasizes:

- board-centric work assignment
- a local daemon for executing agent CLIs
- real-time status reporting
- reusable skills
- multi-workspace operation

Its repo license is **not** plain Apache 2.0. It is a modified Apache-style
license that adds meaningful restrictions around hosted third-party service use,
commercial embedding, and frontend branding.

#### Conductor

Public materials for `conductor-oss/conductor` present it as a durable workflow
engine for microservices, AI agents, and long-running orchestration. Its public
architecture emphasizes:

- persisted execution state
- retries, timeouts, and replayability
- explicit orchestration separated from worker logic
- human-in-the-loop checkpoints
- declarative workflow definitions

Its repo is under **Apache 2.0**.

### Participation record

The maintainer again wanted free `opencode` models included where possible.

Requested free-model roster:

- `opencode/big-pickle`
- `opencode/nemotron-3-super-free`
- `opencode/ring-2.6-1t-free`
- `opencode/minimax-m2.5-free`

What actually happened:

- **Big Pickle:** returned a substantive answer
- **Ring 2.6 1T free:** returned a substantive answer
- **MiniMax M2.5 free:** returned a substantive answer
- **Nemotron 3 Super free:** launched but did not return a usable answer body

To stabilize the round further, **Codex CLI** and **Gemini CLI** were also run
and both returned substantive answers.

### Voice summaries

#### Codex

- Strongest on preserving the existing separation of concerns rather than
  letting outside tools reopen it.
- Treated **Multica** as validation of the board-as-assignment-surface idea:
  visible work, agent assignees, status signals, and lightweight operator
  ergonomics.
- Treated **Conductor** as validation of durable execution patterns:
  explicit state transitions, retries, replay, and first-class human-review
  checkpoints.
- Argued that **Conductor is the only legally plausible reuse source**, but
  that even there the practical value is still mostly structural inspiration
  rather than direct code import.

#### Gemini

- Strongest on mapping borrowings onto existing work items and design surfaces
  rather than speaking only in product metaphors.
- Connected Multica's status surface to the already-planned prediction-error /
  status dashboard work.
- Connected Conductor's durable execution and HITL primitives to the existing
  `RoundRun` and phase-state-machine direction.
- Rejected both tools' full-stack runtime assumptions as mismatched with the
  BEAM-native architecture.

#### Big Pickle

- Strongest on a concrete board/backend split:
  Multica for the board metaphor, Conductor for the execution semantics.
- Explicitly framed the best adaptation as:
  - board-centered assignment and visibility from Multica
  - declarative work-item schema, retries, timeout policy, replay, and HITL
    gates from Conductor
- Rejected Multica code reuse as both license-risky and stack-mismatched.
- Strongly preferred adapting Conductor patterns into Elixir structs and Dolt
  records rather than importing a foreign runtime.

#### Ring 2.6 1T free

- Strongest on the clean **design-only borrowing** interpretation.
- Validated the board metaphor, real-time agent visibility, and reusable-skill
  ideas from Multica.
- Validated durable state, explicit orchestrator/worker separation, and
  declarative workflow templates from Conductor.
- Rejected the central server / worker-polling assumptions from Conductor and
  the web-first product stack from Multica as conflicting with the local
  architecture.

#### MiniMax M2.5 free

- Strongest on placement:
  - Multica-like issue-as-workstream and local-daemon ideas belong in the
    bulletin board / Symphony direction
  - skill rosters and persistent agent capabilities belong in Vaglio
  - roundtable itself should remain discussion-oriented
- Treated direct code reuse from both tools as practically not worth it, even
  when the license allows it, because the real gain is conceptual.
- Recommended a lightweight declarative round / workflow definition format
  inspired by Conductor rather than a heavyweight workflow-engine ambition.

#### Copilot

- Agreed with the converged split:
  Multica is useful mainly as **board UX / local-runner inspiration**; Conductor
  is useful mainly as **durability / workflow semantics inspiration**.
- Treated the key design rule as:
  borrow selectively, integrate locally, and do not let external tools collapse
  the boundaries between discussion, execution dispatch, and governance.
- Treated licensing as a real design input rather than a later legal cleanup.

### First-pass convergence

All substantive voices converged on the following points.

1. **These tools reinforce Round 62 rather than displacing it.**
   The panel did not treat Multica or Conductor as replacements for the local
   design. Instead:
   - Multica sharpens the board metaphor
   - Conductor sharpens the execution semantics

2. **Multica is mostly a product-UX and local-runner reference.**
   The most valuable parts are:
   - agents as visible assignees on work items
   - real-time agent status
   - local daemon patterns for subscription-backed CLIs
   - reusable skills / capability tags as a future forge concern

3. **Conductor is mostly a durability and workflow-semantics reference.**
   The most valuable parts are:
   - retries and timeout policies as first-class metadata
   - persisted execution state
   - replay / resume semantics
   - human-in-the-loop checkpoints
   - explicit separation between orchestration and worker logic

4. **The project should not adopt either tool wholesale.**
   The round rejected:
   - Multica's full product stack as the new center of gravity
   - Conductor's full runtime and workflow-engine ambition as the local path

5. **Direct code reuse is not the main story.**
   Even where the license is permissive, language/runtime mismatch makes direct
   reuse unattractive. The right move is selective pattern extraction and local
   reimplementation.

### What the round recommends borrowing from Multica

The strongest Multica borrowings were:

- **Agent-as-assignee board UX.**
  Work should be visibly assigned to agents the way issues are assigned to
  teammates.
- **Live status visibility.**
  Operators should be able to see which agents are idle, running, blocked, or
  failed.
- **Local daemon / runner model for subscription CLIs.**
  This matches the requirement to preserve multi-provider freedom and existing
  CLI subscriptions rather than forcing all execution through APIs.
- **Capability / skill tagging.**
  This is useful, but belongs more naturally in the future Vaglio layer than in
  the discussion orchestrator itself.

### What the round recommends borrowing from Conductor

The strongest Conductor borrowings were:

- **Durable execution state.**
  A work item should carry attempt lineage, not just a current assignee.
- **Retry and timeout policy as first-class schema.**
  These should be in the work-item model from the start.
- **Replay / resume semantics.**
  A failed or interrupted execution should not collapse into opaque operator
  improvisation.
- **Human-in-the-loop gates.**
  Approval, escalation, and intervention should be represented as structured
  workflow states.
- **Declarative workflow shape.**
  Not a full Conductor clone, but a lightweight way to express round or task
  policy as data instead of burying it entirely in ad hoc code paths.

### What the round says to avoid

#### Avoid from Multica

- direct code reuse
- hosted-service and embedding-license entanglement
- frontend / branding coupling
- taking its Go + Next.js + Postgres stack as the local architecture
- letting the board become a monolithic all-in-one product that swallows the
  other layers

#### Avoid from Conductor

- importing the full Java-centric runtime
- turning the project into a generic enterprise workflow platform
- copying workflow schemas verbatim instead of adapting the idea
- adopting a central-server worldview where it conflicts with local design
  constraints and existing execution surfaces

### Code-reuse and license conclusion

The round converged on a sober answer.

#### Multica

Treat as **design inspiration only**.

Reasons:

- the modified Apache-style license introduces restrictions the project does not
  want to inherit
- the stack is mismatched anyway
- the real value lies in product patterns, not implementation import

#### Conductor

Treat as **legally safer but still mostly design-level inspiration**.

Reasons:

- Apache 2.0 is friendly
- but the language/runtime gap is large
- the portable value is in schema ideas, retry semantics, replay concepts, HITL
  patterns, and orchestration discipline

The practical conclusion was:

- **little to no direct code reuse from either tool**
- **substantial design borrowing from both**

### Integration with the existing architecture

The round repeatedly returned to the same placement model.

#### `agent-roundtable`

Should remain the discussion and satisfaction engine.

It may eventually gain cleaner declarative round definitions and stronger
structured state transitions, but it should **not** become the general execution
backend.

#### Bulletin board / Symphony direction

Should absorb most of the concrete borrowings:

- agent assignment
- local daemon / runner contract
- work-item status surface
- retry / timeout policy
- attempt lineage
- HITL gates
- replayable execution records

#### Vaglio

Should absorb longer-horizon capability and governance ideas:

- persistent agent rosters
- capability / skill registry
- provenance-rich status and trust signals
- longer-term memory of execution behavior and outcomes

### Immediate roadmap implications

The panel converged on the following near-term artifacts.

1. **A bulletin-board work-item schema**
   with retry policy, timeout policy, attempt lineage, and human-review gates.

2. **A local daemon / runner contract**
   for subscription-backed CLIs, inspired by Multica's local-execution model but
   implemented in the local stack.

3. **A lightweight declarative workflow / round definition format**
   inspired by Conductor's workflow-as-data approach, but kept narrow and
   BEAM-native.

4. **A borrowed-patterns map**
   that records which ideas live in roundtable, which belong in the bulletin
   board, and which belong in Vaglio.

5. **An explicit design note on reuse boundaries**
   stating that Multica is design-only and Conductor is license-safe but still
   primarily a source of structural inspiration.

### Consensus summary

The consensus answer is:

- **borrow from Multica at the UX / local-runner layer**
- **borrow from Conductor at the durability / workflow-semantics layer**
- **do not adopt either system wholesale**
- **do not treat Multica as a code-reuse source**
- **treat Conductor as legally reusable in principle but practically more useful
  as a schema and architecture reference**
- **integrate all borrowing through the existing Round 62 split rather than
  reopening the architecture**

The round therefore strengthens the current direction:

build the board and execution semantics more clearly, keep roundtable focused on
discussion, and let Vaglio absorb the longer-lived capability and governance
surfaces.

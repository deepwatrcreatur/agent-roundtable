## Round 75 — DBOS, Temporal, and the Durable Execution Boundary

**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, `opencode/big-pickle`, `opencode/minimax-m2.5-free`, Copilot synthesis  
**Additional note:** `opencode/ring-2.6-1t-free` and `opencode/nemotron-3-super-free` drifted into repo exploration rather than returning a clean bounded answer, so they were excluded from synthesis  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wanted a new round on durable execution frameworks, especially
**DBOS** and **Temporal**, in light of the project's ongoing board / daemon /
workflow work.

The narrower question was:

- should the project rely on a developed workflow library or external service
  for durability, replay, scheduling, and workflow state
- or is the project mostly right to build this itself on top of BEAM / OTP /
  Jido plus explicit local persistence
- what should be borrowed from DBOS and Temporal
- what should be rejected
- where exactly should the boundary sit between BEAM-native implementation and
  external durable-execution infrastructure

### Relevant prior context

This round built directly on:

- **Round 11** — Jido / OTP is the right runtime substrate, but it does **not**
  by itself provide a Temporal-style durable workflow journal
- **Round 62** — discussion / board / Vaglio boundary
- **Round 70** — durable execution semantics are worth borrowing, but the
  project should not adopt a heavyweight foreign runtime wholesale
- work items **73**, **74**, and **75** — board schema, local daemon contract,
  and lightweight workflow definitions

Those earlier rounds already established:

- BEAM / OTP / Jido are useful runtime primitives
- durable workflow state still must be built explicitly
- the board / daemon model is already becoming a real execution substrate
- the project values architecture that remains aligned with local agent CLIs,
  forge semantics, and explicit memory boundaries

### Grounding facts used in this round

#### DBOS

Public materials for `dbos-inc/dbos-transact-ts` present DBOS as a lightweight
durable workflow library built on **Postgres**.

Its public architecture emphasizes:

- durable workflows
- durable queues
- scheduling
- notifications
- programmatic workflow management
- exactly-once event processing

It is positioned as an **in-process library** rather than a separate
orchestration server.

Its repo is under **MIT**.

#### Temporal

Public materials for `temporalio/temporal` present Temporal as a durable
execution platform / server for workflows.

Its public architecture emphasizes:

- durable execution history
- retries and recovery
- task queues
- visibility / inspection
- mature workflow/activity boundaries
- self-hosted or managed cloud deployment

It is a **dedicated workflow engine**, not a mere in-process library.

Its repo is under **MIT**.

### Participation record

What actually happened:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Big Pickle:** substantive
- **MiniMax M2.5 free:** substantive
- **Ring 2.6 1T free:** drifted into repo exploration, excluded
- **Nemotron 3 Super free:** drifted into repo exploration, excluded

### Voice summaries

#### Codex

- Strongest on the distinction between:
  - durability from explicit persisted workflow state
  - runtime supervision from OTP
- Accepted the current local direction, but only if the team stops pretending
  supervisor restarts are equivalent to durable execution.
- Treated DBOS and Temporal as specification references, not current
  dependencies.
- Recommended a battery of crash/replay/duplicate-delivery validation before
  confidence claims.

#### Gemini

- Strongest on staying fully local and stack-aligned.
- Rejected both Temporal and DBOS as direct dependencies:
  - Temporal because it is a heavyweight dedicated engine/server
  - DBOS because it is still a TypeScript/Postgres library mismatched with the
    BEAM / Elixir / Dolt stack
- Reaffirmed the local boundary:
  BEAM for execution/supervision, explicit persisted board state for durability.
- Recommended a hard-crash recovery suite immediately.

#### Big Pickle

- Strongest on the DBOS-inspired middle path.
- Argued that the local board / daemon model is correct, but the **Dolt runtime
  journal is the wrong durability substrate** for in-flight execution state.
- Proposed borrowing DBOS's Postgres-backed execution journal pattern while
  keeping OTP for actual runtime execution.
- Rejected Temporal as unnecessary server overhead for this architecture.

#### MiniMax M2.5 free

- Strongest on the "build local, validate hard" framing.
- Rejected Temporal outright as architectural overreach.
- Treated DBOS as a useful design reference, but not a dependency.
- Recommended benchmarking the build-vs-adopt question against real failure-mode
  progress rather than arguing from abstractions alone.

#### Copilot

- Agreed with the converged answer:
  stay mostly BEAM-native, but only if durable execution is treated as an
  explicitly engineered persistence problem rather than a side effect of OTP.
- Treated the real value of DBOS / Temporal as:
  clarifying exactly which guarantees the local system still must prove.

### First-pass convergence

All substantive voices converged on the following points.

1. **The current local direction is still justified.**
   No substantive voice recommended replacing the current board / daemon /
   workflow architecture with Temporal or another heavyweight engine today.

2. **BEAM / OTP does not equal durable execution.**
   The round strongly reaffirmed the older Round 11 point:
   supervision, crash isolation, and process restart are not a durable workflow
   journal.

3. **Temporal is too architecture-shaping for the current path.**
   The round treated Temporal as an excellent reference model for what "real"
   durable execution looks like, but as the wrong current runtime dependency for
   a system already committed to BEAM/Jido and local task semantics.

4. **DBOS is the more relevant comparator.**
   DBOS's in-process library + persistence-substrate model is much closer to the
   local design than Temporal's dedicated server model.

5. **DBOS is still not a clean dependency fit today.**
   The stack mismatch matters:
   - DBOS is TypeScript
   - DBOS assumes Postgres
   - the local system is Elixir / Jido / Dolt-backed

6. **The real question is validation, not slogans.**
   The project should keep building locally **only if** it proves replay,
   crash-recovery, timer durability, and dedup/idempotency boundaries in tests
   and drills.

### What BEAM / OTP genuinely gives

The round treated these as real BEAM-native strengths:

- process isolation
- supervision trees
- restart/backoff semantics
- mailbox/message coordination
- resilient in-memory control loops
- a runtime model well-suited to daemon coordination and local execution

### What BEAM / OTP does not give

The round repeatedly emphasized that OTP does **not** natively provide:

- durable workflow history
- durable timers across node/process restart
- replay/resume semantics
- explicit side-effect boundaries
- exactly-once external actions
- durable scheduling
- operator-grade execution visibility

Those must still be built in explicit persisted state machinery.

### What the round recommends borrowing

From **Temporal**:

- the seriousness of durable execution as a distinct problem
- persisted history
- replay / resume semantics
- operator visibility
- explicit workflow/activity boundaries

From **DBOS**:

- the lighter-weight in-process mental model
- explicit execution journaling against a persistence substrate
- exactly-once / dedupe / queue semantics
- durable timer and scheduling concepts without requiring a full external engine

### What the round says to reject

The round rejected:

- adopting Temporal as a core dependency or server
- assuming OTP restart semantics are enough
- calling the current model "durable" without proving hard failure cases
- importing DBOS directly without a real stack-aligned interoperability path

### Most important next validation steps

The strongest converged next steps were:

1. Crash-recovery drills:
   - kill orchestrator
   - kill daemon
   - kill host/node
   - verify exact post-restart behavior
2. Replay model proof:
   - which logic is replayable
   - which actions require explicit persisted side-effect markers
3. Duplicate-delivery / idempotency tests:
   - no double-post
   - no double-dispatch
   - no double-commit
4. Durable timer validation:
   - scheduled work survives restart
   - timer behavior stays sane under awkward restart windows
5. Operator history inspection:
   - an operator can reconstruct why a workflow is in its current state from
     durable records alone
6. Resume semantics:
   - interrupted HITL and agent-turn flows resume without hidden in-memory
     assumptions

### Open architectural tension

One real disagreement remained around the runtime journal substrate.

- **Gemini / localist view:** continue with BEAM + explicit local persistence on
  the current board / Dolt path
- **Big Pickle view:** the board/daemon direction is right, but in-flight durable
  execution should move toward a DBOS-like **Postgres execution journal** rather
  than leaning on Dolt for runtime history

The convergence was not that this question is settled, but that:

- the local architecture is still worth pursuing
- the durability substrate question must now be validated through real failure
  drills instead of theory

### Closure

The round closes with the following design rules.

#### 1. Stay mostly BEAM-native for now

The board / daemon / workflow-as-data model is still the right local direction.

#### 2. Treat OTP as runtime resilience, not durable state

Durability still lives or dies on the quality of explicit persisted workflow
machinery.

#### 3. Use Temporal as a standard of seriousness, not a dependency

The project should measure itself against Temporal-like guarantees before it
claims durable execution.

#### 4. Use DBOS as the more relevant comparator

The in-process library + persistence-substrate pattern is architecturally closer
to the local system than a dedicated workflow server.

#### 5. Prove durability with hard failure tests

If the local model cannot survive crash/replay/duplication/timer tests, it is
not yet durable regardless of what the code looks like on paper.


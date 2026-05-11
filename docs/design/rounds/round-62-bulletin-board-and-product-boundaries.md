## Round 62 — Bulletin Board, Product Boundaries, and Reducing Supervision Burden

**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, Copilot synthesis  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wants to replace the current awkward workflow of supervising many
CLI-agent terminal tabs, granting permissions, and context-switching manually.
They remain attracted to OpenAI Symphony's bulletin-board / issue-driven style
of orchestration, but do not want to simply adopt stock Symphony + Linear.

The round asked:

- should the project move toward a Symphony-style bulletin board now rather than
  optimizing the current `dmux` / multi-terminal workflow alone?
- where should that bulletin board live architecturally?
- how should existing subscription-backed models and cheaper API workers coexist?
- what is the right boundary between:
  - `agent-roundtable` as design discussion
  - a work-issue / bulletin-board system as execution dispatch
  - Vaglio as the long-term forge / governance / active-inference product?

### Triggering context

This round was not abstract architecture tourism. It came from direct operator
pain:

- switching between many CLI-agent tabs
- manually tracking which agent is doing what
- repeatedly granting permissions or noticing stalls by hand
- wanting to preserve the value of existing subscriptions:
  - Codex
  - Copilot
  - Gemini
- while also taking advantage of cheap API workers such as DeepSeek

The maintainer also explicitly wants stronger infrastructure integration across
three converging products:

1. **Vaglio** — the forge / governance / active-inference platform
2. **agent-roundtable** — the design-discussion system
3. **a work bulletin board** — the system that assigns and tracks actual work
   given to agents

Local prior art already in the repo mattered heavily to the panel:

- the earlier Symphony / orchestration survey in Round 11
- Work Item 35: Dolt-JJ orchestration layer
- Work Item 54: dmux Vaglio TUI
- Work Item 57: autonomous agent task delegation / queue

### Voice summaries

#### Codex

- Strongest on the claim that the real problem is **coordination state**, not
  terminal layout.
- Argued that `dmux` should remain a power-user console, but not the source of
  truth for orchestration.
- Favored a **hybrid issue surface + Dolt execution state** model.
- Wanted the bulletin board to exist as a distinct execution layer with clean
  boundaries from both design discussion and the forge.

#### Gemini

- Strongest on the claim that the current multi-terminal workflow is a
  **supervision bottleneck** and should be replaced now rather than polished.
- Wanted the board to preserve the Yegge / beads spirit through Dolt-backed
  traceability and lineage.
- Treated `dmux` as a board-facing TUI rather than as the orchestration core.
- Pressed hardest on bringing the board close to Vaglio so execution state,
  provenance, and future active-inference routing can share one substrate.

#### DeepSeek

- Strongest on **operator burden** as the design driver.
- Argued that the right split is:
  - design deliberation in `agent-roundtable`
  - execution dispatch in a bulletin board
  - long-horizon code / governance / project-memory reality in Vaglio
- Supported a capability-based provider layer so:
  - subscription-backed CLIs remain usable
  - cheaper API workers handle high-volume or lower-risk tasks
- Sharpened the case for a board that is socially legible on top and
  operationally structured underneath.

#### Copilot

- Agreed that the board should ship now and that `dmux` alone is not the right
  center of gravity.
- Accepted the hybrid issue-surface + Dolt-backend position.
- Proposed a practical implementation compromise:
  treat the bulletin board as its **own product conceptually**, but build v1 as
  a **bounded context inside the current Elixir / Jido stack** so it can ship
  sooner and integrate with existing roundtable work.
- Emphasized:
  - design discussion = "what should we do, and why?"
  - bulletin board = "who is doing what now, under what policy?"
  - Vaglio = "what is the durable forge / governance / memory reality?"

### First-pass convergence

All four voices converged on the following points.

1. **The project should move toward a Symphony-style bulletin board now.**
   The pain is not mainly that terminals are visually inconvenient; it is that
   the human is acting as the scheduler, dispatcher, and retry monitor.

2. **`dmux` should remain, but as an operator console rather than the canonical
   orchestration surface.**
   It still has value for:
   - monitoring
   - log tails
   - manual takeover
   - power-user control
   But it should not remain the primary place where work state lives.

3. **The right state model is hybrid.**
   The human-facing surface should be issue-like and socially legible.
   The execution backend should be structured and queryable, with Dolt a strong
   fit for:
   - assignments
   - attempts
   - retries
   - lineage
   - status transitions

4. **Existing subscriptions should be preserved behind a provider layer.**
   The board should not assume one vendor or one invocation method.
   It should mix:
   - subscription-backed CLI workers
   - API-backed cheap workers
   under one routing policy.

5. **The three product layers should remain conceptually distinct.**
   The panel did not support collapsing design discussion, execution dispatch,
   and forge / governance into one undifferentiated product blob.

6. **Prior local architecture work should be extended, not discarded.**
   The round did not recommend abandoning Jido / Elixir, Dolt-JJ integration, or
   the task-queue / `dmux` work already defined in the repo.

### Main disagreement

The only real disagreement was **placement**.

- **Codex** preferred a separate-but-integrated service / repo boundary for the
  bulletin board.
- **Gemini** preferred placing the board more directly inside Vaglio's orbit.
- **DeepSeek** argued primarily for conceptual separation rather than a hard repo
  answer.
- **Copilot** recommended a pragmatic compromise:
  keep the board as a distinct product / architectural layer, but build its v1
  implementation as a bounded context inside the existing Elixir / Jido system.

That compromise best fits the current state of the codebase and the desire to
reduce supervision burden quickly without prematurely freezing the long-term repo
boundary.

### Closure

The round closes with the following design rules.

#### 1. Build the bulletin board now

Do not spend the next phase merely polishing multi-terminal supervision.
The board is the next leverage point.

#### 2. Keep `dmux`, but demote it

`dmux` should become:

- a monitor
- a launcher
- a takeover console

not the canonical record of work state.

#### 3. Use a hybrid issue-surface + Dolt-backend model

The board should be:

- **issue-centric for operator UX**
- **Dolt-centric for structured execution state**

This preserves both legibility and machine-tractable provenance.

#### 4. Preserve multi-provider freedom

The board should route work through a provider abstraction that can mix:

- Codex CLI
- Copilot / local harness paths
- Gemini CLI
- DeepSeek API

and future backends without redesigning the control plane around any one vendor.

#### 5. Keep the three layers distinct

- **`agent-roundtable`** should remain the design-discussion and consensus layer
- **the bulletin board** should own work assignment, queue state, retries, and
  dispatch policy
- **Vaglio** should remain the forge / governance / long-term project-memory
  platform

#### 6. Ship v1 in the current Elixir / Jido stack

The cleanest near-term move is:

- conceptually treat the board as a distinct product layer
- implement v1 inside the current Elixir / Jido environment
- keep the internal boundaries clean enough that it can later remain embedded or
  split out with less pain

### Immediate roadmap implications

The round converged on a near-term sequence:

1. create Dolt-backed `work_items` / assignment state
2. add an auto-claim / auto-dispatch watcher
3. make `dmux` a monitor / control surface for the board rather than the board
   itself

### Consensus summary

The consensus answer is:

- **yes**, move to a Symphony-style bulletin board now
- **no**, `dmux` alone is not the right long-term fix
- **yes**, preserve subscriptions and cheap API workers behind a provider layer
- **yes**, keep design discussion, execution dispatch, and forge / governance as
  separate conceptual layers
- **best current implementation path:** build the bulletin board as a bounded
  context in the existing Elixir / Jido stack, with a hybrid issue-surface +
  Dolt-backend architecture


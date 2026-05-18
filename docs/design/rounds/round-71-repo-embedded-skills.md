## Round 71 — Repo-Embedded Skills as Deliberative Artifacts

**Tags:** tooling, structural, governance
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, `opencode/big-pickle`, `opencode/minimax-m2.5-free`, `opencode/nemotron-3-super-free`, Copilot synthesis  
**Additional note:** `opencode/ring-2.6-1t-free` repeatedly drifted into local file exploration for this round and was not used in the final synthesis  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wanted a follow-up on the growing ecosystem of agent-specific
skills that live alongside repos or local agent config.

The narrower question was:

- should this project have an equivalent concept for **repo-embedded skills**
- should those skills live alongside embedded discussion and design memory
- should the board / orchestrator be able to require or activate them for work
  items
- how should repo-local skills differ from shared cross-repo skills
- what would a concrete example such as a `pi-obsidian` skill imply for the
  architecture

### Relevant prior context

This round built directly on:

- **Round 62** — the split between discussion, execution dispatch, and
  long-horizon memory / governance
- **Round 63** — hybrid embedded design memory with bounded local retrieval and
  explicit supersession
- **Round 70** — selective borrowing from Multica and Conductor, especially
  board/daemon/workflow concepts

Those earlier rounds already established:

- `agent-roundtable` should remain the discussion and closure surface
- the board should handle assignment, activation, retries, timeout policy, and
  execution lineage
- Vaglio should own longer-horizon memory, cross-repo lineage, and governance
- embedded memory is only useful if it produces bounded, actionable local
  context rather than more transcript bulk

### Participation record

The maintainer has repeatedly asked to include free `opencode` voices where they
are available and usable.

Requested free-model roster:

- `opencode/big-pickle`
- `opencode/nemotron-3-super-free`
- `opencode/ring-2.6-1t-free`
- `opencode/minimax-m2.5-free`

What actually happened:

- **Big Pickle:** substantive
- **MiniMax M2.5 free:** substantive
- **Nemotron 3 Super free:** substantive
- **Ring 2.6 1T free:** repeatedly drifted into repo exploration rather than
  answering from the supplied round prompt, so it was excluded from synthesis

Standard local voices used:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive

### Voice summaries

#### Codex

- Strongest on treating skills as a **new artifact type**, not a vague prompt
  pile.
- Preferred a narrow, declarative format with explicit lifecycle metadata.
- Placed responsibilities cleanly across the Round 62 split:
  - roundtable proposes and ratifies
  - board/orchestrator resolves and attaches
  - Vaglio governs shared lineage
- Rejected silent or ambient activation.

#### Gemini

- Strongest on calling skills the **executable corollary** of embedded design
  memory.
- Treated repo-local skills as a way to bind operational quirks to the same
  versioned history as the code they operate on.
- Recommended a simple `skill.yaml`-style manifest and work-item
  `required_skills` references before any richer registry work.
- Emphasized vendor-neutral translation at daemon activation time.

#### Big Pickle

- Strongest on the distinction between:
  - workflow definitions = execution policy
  - skills = capability / cognition policy
- Argued that skills fill a real missing layer between deliberation and
  execution.
- Recommended transparent event-log injection so reviewers can see which skills
  shaped an attempt.
- Warned hardest about hidden behavior and stale skill drift.

#### MiniMax M2.5 free

- Strongest on the "build only if concrete need exists" constraint.
- Treated skills as a thin opt-in layer over work-item assignment, not a new
  architectural pillar.
- Recommended exact version resolution and explicit `requires` /
  `recommends` semantics at assignment time.
- Rejected starting with marketplaces, shared registries, or agent-specific
  adapters.

#### Nemotron 3 Super free

- Strongest on the basic affirmative case that repo-embedded skills are needed
  if automation is to stay aligned with evolving design memory.
- Preferred a simple manifest directory plus orchestrator activation hooks.
- Its answer was briefer and less nuanced than the other voices, but aligned on
  the same basic placement and lifecycle idea.

#### Copilot

- Agreed with the converged view that skills are justified only as **explicit,
  versioned, reviewable operational knowledge artifacts**.
- Treated the most important boundary as:
  skills guide work, but do not grant capabilities or become a covert tool /
  secret channel.
- Treated transparent activation and supersession as mandatory.

### First-pass convergence

All substantive voices converged on the following points.

1. **Repo-embedded skills should exist, but narrowly.**
   The round did not support a generic skill marketplace or prompt pile. It
   supported a bounded artifact type for reusable execution knowledge.

2. **Skills are distinct from workflows.**
   Workflow definitions express retry / timeout / HITL / runtime policy.
   Skills express repo- or domain-specific guidance, terminology, checklists,
   harness conventions, and bounded operational context.

3. **Activation must be explicit and visible.**
   The board/orchestrator should resolve exact skill versions and record them in
   the assignment / attempt history. No silent inheritance from local agent
   config.

4. **The Round 62 split still holds.**
   - `agent-roundtable` authors and ratifies
   - board/orchestrator resolves and attaches at task time
   - Vaglio owns cross-repo lineage, shared skill governance, and longer-horizon
     memory

5. **The primary risks are staleness, hidden behavior, and scope creep.**
   The round repeatedly warned against letting every useful prompting pattern
   become a "skill."

### Recommended design boundary

The strongest converged design was:

- skills are **declarative text+metadata artifacts**
- they are **vendor-neutral**
- they are **explicitly versioned**
- they are **ratified through discussion**
- they are **resolved by orchestration**
- they are **logged on activation**
- they are **supersession-aware**

The round rejected:

- hidden agent-local skill inheritance
- capability grants hidden inside skills
- skill SDKs or plugin runtimes
- starting with a shared registry or marketplace

### What to build first

The round recommended a narrow first slice:

1. A neutral skill schema containing:
   - identity and scope
   - purpose
   - applicability / triggers
   - concise guidance
   - lifecycle metadata
   - compatibility / tested runtimes
2. Repo-local skill storage adjacent to embedded design memory.
3. Work-item fields for `requires` and `recommends`.
4. Orchestrator resolution to exact versions at assignment time.
5. Attempt / event-log recording of activated skills.

Only after that should the project consider:

- shared cross-repo registries
- agent-specific adapters
- broader discovery surfaces

### Closure

The round closes with the following rules.

#### 1. Skills are justified only as explicit execution knowledge

They are not a synonym for "things the agent should know."

#### 2. Skills must remain inspectable and versioned

If humans cannot see what was attached and why, the model is untrustworthy.

#### 3. Activation must be deterministic

Assignments should carry exact skill references, not ambient local behavior.

#### 4. Capability control stays outside the skill

Skills can describe how to use an allowed harness or convention, but they must
not become covert permission channels.

#### 5. Supersession is mandatory

Because skills actively shape behavior, stale skills are dangerous. Lifecycle
metadata and explicit replacement chains are required from the start.


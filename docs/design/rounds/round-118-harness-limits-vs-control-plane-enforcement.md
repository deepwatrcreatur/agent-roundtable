## Round 118 — Harness Limits vs Control-Plane Enforcement

**Tags:** harnesses, coordination, tooling, product-boundary, governance  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** this round asked whether currently used major-agent
provider harnesses are structurally too weak to enforce multi-agent hygiene, and
whether shifting to more customizable harnesses materially changes the answer.

### Round question

The maintainer wanted a follow-up round on a common claim:

> “the harness should enforce good practices.”

The practical problem behind that claim was:

- multi-agent coding workflows still suffer from:
  - dirty shared checkouts
  - duplicated work
  - accidental overlap
  - publication races
  - and weak enforcement of worktree / workspace hygiene
- people often describe these as the harness's job
- but major provider harnesses often appear optimized for single-agent
  productivity rather than shared multi-agent coordination

The sharper decision questions were:

- are current major-provider harnesses structurally weak at enforcing
  multi-agent coordination
- is the weakness mainly:
  - missing features
  - product incentives
  - wrappers
  - or a deeper architecture-boundary problem
- how much can more customizable harnesses like Pi realistically fix
- how much can OpenCode-style customization realistically fix
- and whether the real leverage lies in changing harnesses or in building a
  control plane above them

### Grounding used in this round

Relevant local prior context carried into the round:

- **Round 108** — Pi is useful as a thin BYOK harness, but not a universal
  replacement for OpenCode or vendor-native CLIs
- **Round 112** — `jj` is useful but not sufficient; the real differentiated
  opportunity remains above the VCS layer in governance and execution
  discipline
- **Round 116** — recurring cleanup debt is a defaults/enforcement problem around
  shared checkouts and missing preflight guards
- **Round 117** — the forge should own a narrow coordination/trust plane above
  Git/`jj`
- **Round 98** — pluggable external/provider capabilities still need a host-owned
  control plane and final gate

External grounding carried in:

- Anthropic's production multi-agent writeup:
  multi-agent systems add substantial coordination overhead and many coding
  tasks are not naturally parallel in the way research tasks are
- Pi documentation:
  strong extension points, permission gates, protected paths, RPC/SDK, and a
  “primitives not features” design
- OpenCode documentation:
  strong single-agent UX, project initialization, plan mode, undo/redo, and
  customization

Important scope boundary carried into the round:

- the question was **not** which harness is “best” in the abstract
- it was whether harness choice meaningfully solves the deeper multi-agent
  coordination problem

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** substantive
- **DeepSeek API:** substantive
- **Copilot:** substantive

This round therefore had a **full substantive roster**.

### Voice summaries

#### Codex CLI

- Strongest on the phrase that the harness is the **wrong sovereign** for shared
  coordination.
- Treated current provider harnesses as structurally weak because they assume a
  single agent owns a private workspace.
- Most explicit that the key missing concepts are:
  - claims
  - leases
  - attempt lineage
  - promotion gates
  - and shared authority
- Favored building control-plane primitives above existing harnesses rather than
  switching harnesses first.

#### Gemini CLI

- Strongest on distinguishing:
  - local single-agent discipline
  - from cross-agent shared coordination
- Treated current major-provider harnesses as good at:
  - model interaction
  - tool execution
  - and single-session UX
  but weak at:
  - exclusive ownership
  - coordination across agents
  - publication sequencing
  - and durable handoff state
- Strongest that wrappers and harness changes help tactically, but the strategic
  leverage remains in the control plane.

#### Claude CLI

- Strongest on the architectural answer:
  current provider harnesses suffer from **workspace solipsism** —
  they assume the filesystem they see is their private playground.
- Most vivid that the missing primitive is **atomic lease semantics**:
  without a shared lock/lease service, harness improvements remain advisory.
- Treated Pi as useful for protected paths, permission gates, and extension
  hooks, but still not a final authority layer.
- Favored wrapping current harnesses rather than replacing them.

#### DeepSeek API

- Strongest on the claim that the harness is a **disciplined local executor**,
  not the source of truth for shared governance.
- Most explicit that provider harnesses are not “broken”; they are simply built
  for a different job:
  one user, one repo, one assistant.
- Favored a thin control-plane contract above current harnesses and warned
  against overinvesting in harness migration.

#### Copilot

- I agreed with the convergence that the harness can improve local behavior but
  does not solve the higher-layer distributed-system problem.
- My strongest synthesis point was:
  harnesses should be treated as policy-enforcement endpoints and provider
  adapters, while the forge/control plane owns shared coordination truth.

### First-pass convergence

The substantive voices converged on the following points.

1. **Current major-provider harnesses are structurally weak at multi-agent
   coordination.**
   The precise weakness is that they are designed as strong
   single-agent-to-model session managers, not as multi-actor coordination
   systems.

2. **The primary problem is a layer-boundary problem, not just missing features.**
   A harness is good at:
   - model interaction
   - tool routing
   - local permissions
   - and single-session UX

   It is not the right home for:
   - shared claims
   - leases
   - promotion sequencing
   - or cross-agent authority

3. **Customizable harnesses can improve local discipline, but not complete
   shared coordination by themselves.**
   Pi-style extension points can help with:
   - preflight checks
   - protected paths
   - permission gates
   - and local wrappers

   But they still need a shared control plane above them if multiple agents must
   coordinate reliably.

4. **OpenCode-style customization helps even less on the governance axis.**
   It improves UX, planning, and repeatable local workflows, but does not
   materially solve shared multi-agent authority and ownership.

5. **Switching harnesses is a tactical move, not the strategic answer.**
   Better wrappers/harnesses provide moderate gains in local discipline, but the
   real durable gain comes from claims, leases, attempt lineage, and promotion
   gates above them.

6. **The right long-term role of the harness is as a disciplined local
   executor.**
   It should:
   - run the model
   - enforce local constraints
   - expose hooks
   - emit events
   - and obey coordination decisions from a control plane

### Real disagreements that remained

There was no major strategic disagreement, but there were real differences in
how much a programmable harness could help before a host-side control plane
exists:

- **Codex** and **DeepSeek** were most conservative about harness gains
- **Gemini** was most willing to credit wrappers with meaningful tactical value
- **Claude** was most favorable to Pi as the programmable edge, but still not as
  the final authority layer

These were differences in emphasis, not architecture.

### Final synthesis

The strongest answer from this round is:

- the harness can improve single-agent discipline
- but it is the wrong layer to own shared multi-agent governance
- therefore the project should stop looking for a harness to “solve” a
  distributed coordination problem

The panel rejected two bad extremes:

- **bad extreme A:** “switch to a better harness and the problem is solved”
- **bad extreme B:** “harnesses do not matter at all”

The maintained line is:

- keep strong provider-native harnesses where they give pricing, quality, or
  model-specific UX advantages
- wrap them with preflight/postflight discipline where needed
- and put the real authority in a control plane above them:
  claims, leases, attempt lineage, scoped authority, and promotion gates

That makes harness choice secondary and policy/control-plane design primary.

### Best layer-boundary answer

The converged boundary is:

#### Control plane above the harness

- owns claims and leases
- owns attempt IDs and lineage
- owns promotion/publication gates
- owns authority and trust decisions
- records durable coordination state

#### Harness at the edge

- runs the model
- executes tools
- enforces local permissions
- obeys control-plane rules
- emits structured events

#### VCS below both

- stores content and history
- does not define shared coordination policy

#### Humans above promotion

- remain final merge/publish authority

### What to do now in practice

The round's practical answer was:

1. **Do not begin with a harness switch.**
2. **Wrap current harnesses with thin preflight discipline.**
3. **Build narrow control-plane primitives above them first.**

The preferred sequence was:

- make shared checkouts read-mostly
- require isolated workspaces/worktrees for mutation
- add a preflight guard that checks claim/lease state
- add promotion gates above raw push/merge
- record attempt lineage and handoff state durably

Only after that should the project evaluate whether Pi or other programmable
harnesses make the edge wrapper cleaner.

### Recommended follow-on work

The round converged on work near:

1. Define a control-plane contract for:
   - `claim`
   - `lease`
   - `start_attempt`
   - `request_promotion`
   - `handoff`
   - `release`
2. Implement a preflight guard that blocks write-capable sessions without valid
   coordination state.
3. Enforce isolated mutation by default through per-attempt worktrees/workspaces.
4. Add scoped path/resource authority to the wrapper/control-plane boundary.
5. Standardize structured event emission from harness runs.
6. Time-box a Pi spike only as a programmable edge, not as the new system core.

### Satisfaction marker

This round is satisfied if the project now treats harnesses as:

- useful
- replaceable
- policy-enforcement endpoints
- but not the source of truth for shared coordination

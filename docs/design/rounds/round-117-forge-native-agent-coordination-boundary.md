## Round 117 — Forge-Native Agent Coordination Without Workflow Maximalism

**Tags:** product, hosting, orchestration, jj, governance, security  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** this round asked what a GitHub-successor forge should natively own so users get cooperative multi-agent workflows without assembling an awkward local stack of `jj`/git, worktrees, issue graphs, wrappers, and custom leases.

### Round question

The maintainer wanted a product-design round on a next-generation forge / code
host in the age of coding agents.

The concrete problem statement was:

- users still need local tools like worktrees, `jj`, Beads/Dolt, and custom
  wrappers to avoid agents colliding
- even with better local VCS semantics, agents still duplicate work, dirty shared
  workspaces, race on publish, and interfere with each other
- and it is still unclear how much coordination state belongs inside the host
  versus in repo-local metadata or purely local runtime state

The sharper decision questions were:

- does `jj` actually eliminate the multi-agent coordination problem
- what should be first-class in the forge itself
- what should remain repo-portable
- what should stay transient/local
- and what is the smallest product slice that delivers large value without
  turning the forge into a bloated workflow appliance

### Grounding used in this round

Fresh external grounding carried into the round:

- **Thoughtworks Radar (Apr 2026)** assessed Beads as a real new category:
  agent-native project memory / task tracking built on Dolt for autonomous
  multi-agent coordination
- **Azure AI orchestration guidance** argued that multi-agent systems should be
  used only when specialization, security boundaries, or real parallelism justify
  the added coordination overhead
- **Anthropic's multi-agent research writeup** argued that parallel workers with
  separate contexts can materially outperform a single agent in the right
  problem class, but also emphasized that many coding tasks are less naturally
  parallel and that coordination/delegation remain hard
- **Jujutsu (`jj`) docs / README** reinforced the local value of:
  - working-copy-as-commit
  - operation log / undo
  - conflict-as-state
  - rewrite-friendly change identity
  but not a host-native coordination or governance layer

Relevant prior local rounds carried forward:

- **Round 67** — the plausible moat is not raw hosting, but decision/correction
  data and maintainer-facing trust support
- **Round 88** — parallel branch work should remain the default, while live
  mutable resources need explicit single-writer discipline
- **Round 112** — `jj` is more timely, not more sufficient; the differentiated
  product opportunity remains above the VCS layer
- **Round 113** — a better forge should assume endpoint compromise and minimize
  blast radius / authority aggregation
- **Round 116** — recurring cleanup debt is a defaults/enforcement problem, not
  just a doc problem

Important scope boundary carried into the round:

- the question was **not** whether the forge should become a full workflow engine
- it was what narrow host-native coordination authority would solve the highest
  pain without destroying portability or simplicity

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

- Strongest on the distinction between a **better mutation substrate** and a
  **coordination / trust plane**.
- Treated `jj` as materially helpful for local recovery and branch-parallel work,
  but explicit that it does not solve:
  - task ownership
  - resource authority
  - promotion sequencing
  - or durable attempt lineage
- Preferred the forge to own a narrow shared-truth layer:
  - work claims
  - resource leases
  - execution attempts
  - promotion gates
  - review checkpoints
  - and durable task/decision memory
- Strongest on the claim that the real moat remains trusted governance plus
  correction-memory, not “hosting `jj` better.”

#### Gemini CLI

- Strongest on the answer that `jj` may even make coordination failures feel
  subtler rather than making them disappear:
  semantic conflict and duplicated intent survive even if local merge pain drops.
- Most explicit that the forge should own **execution discipline and resource
  governance**, not a maximal orchestration engine.
- Favored a smallest slice centered on:
  - resource lease API
  - promotion gates
  - visible claims
  - and capability-scoped agent identity
- Strongest that the moat is **safety / control-plane trust** before it is
  convenience.

#### Claude CLI

- Strongest on the line that the forge should own a thin **claims-and-leases
  control plane** plus a durable execution log, and leave workflow engines and
  agent runtimes external.
- Framed the key split as:
  - forge-native coordination authority
  - repo-local knowledge/memory state
  - transient local runtime state
- Most explicit that execution events should be append-only and queryable, but
  that the forge should not turn into a compute scheduler.
- Strongest on the idea that the product should feel like a slightly smarter
  GitHub, not like an orchestration console for specialists.

#### DeepSeek API

- Strongest on the phrase that the forge should become an **active coordinator of
  intent** rather than a passive host of history.
- Favored a first slice around the **claimed worktree**:
  the agent claims the task, receives a lease, works in an isolated workspace,
  and returns a promoted candidate for review.
- Most explicit that durable memory should remain part of the integrated shape,
  but only the significant outcome-bearing pieces should become first-class.
- Strongest on the UX line that maintainers should see an “inbox of intent,” not
  a worktree manager.

#### Copilot

- I agreed with the strong convergence that `jj` remains helpful but insufficient:
  it solves local mutation semantics, not ownership, authority, or publish
  discipline.
- My strongest synthesis point was:
  the forge should become a narrow coordination authority above Git/`jj`, not a
  total workflow appliance.
- I also agreed that the right first-class host objects are the ones that need
  shared truth and enforcement:
  claims, leases, attempts, promotion boundaries, and scoped authority.

### First-pass convergence

The substantive voices converged on the following points.

1. **Users still have the core multi-agent coordination problem even if they move
   from Git to `jj`.**
   `jj` improves local mutation, recovery, and conflict handling, but not task
   ownership, authority boundaries, or promotion sequencing.

2. **The key problem is pre-mutation coordination, not just post-mutation merge
   recovery.**
   By the time the VCS sees a conflict, the duplicated work, token cost, and
   semantic divergence have already happened.

3. **The forge should own a narrow shared coordination authority.**
   The repeated preferred host-native objects were:
   - work claims
   - resource leases
   - execution attempts / attempt lineage
   - promotion or publish gates
   - human review checkpoints or review states
   - scoped agent identity / capability boundaries

4. **Repo-local memory should remain portable.**
   Beads/Dolt-style durable task graphs and reasoning memory remain valuable, but
   the forge should index and bind them rather than monopolize them.

5. **The forge should not become a giant workflow engine.**
   The panel repeatedly rejected turning the host into Temporal/Airflow for code
   agents. Runtime orchestration, compute scheduling, and full DAG execution
   should remain outside the core host.

6. **The smallest valuable slice is claims + leases + attempts + promotion gates.**
   This was the strongest repeated answer to “what can ship first and still
   matter?”

7. **The strongest moat remains governance/trust plus correction-memory.**
   Workflow convenience helps adoption, but the durable asset is the high-quality
   record of attempts, rejections, approvals, supersession, and downstream
   outcomes under a host-native control plane.

### Real disagreements that remained

There was no major strategic disagreement, but there were real differences in
emphasis:

- **Codex** favored a somewhat richer first-class host memory layer
- **Gemini** was most aggressive about keeping the server-side primitive set thin
- **Claude** most strongly preferred protocol-first control-plane design over
  product-surface maximalism
- **DeepSeek** was most willing to make “claimed worktree” language visible as a
  product metaphor

These were differences in boundary tuning, not direction.

### Final synthesis

The strongest answer from this round is:

- `jj` helps agent-era local mutation, but it does not eliminate multi-agent
  coordination failures
- therefore the successor forge should not merely host a better VCS
- it should provide a **narrow coordination and trust plane above the VCS**

The panel rejected two bad extremes:

- **bad extreme A:** “`jj` fixes the problem by itself, so the host can stay
  passive”
- **bad extreme B:** “the host should absorb all workflow, memory, scheduling,
  and runtime orchestration”

The maintained line is:

- keep Git/`jj` portable and local
- make the forge authoritative for:
  - who is working on what
  - who may mutate which shared resource
  - which attempt is current
  - what promotion boundary has been crossed
  - and what authority each agent actually holds
- keep project knowledge and task graphs repo-portable where possible
- keep agent runtime execution and worktree mechanics mostly local

That gives the project a product boundary that is structurally better than
today's GitHub + local-agent chaos without turning the host into an overfit
monster.

### Recommended product boundary

The converged boundary is:

#### Forge-native, first-class

- work claims
- resource leases with TTL / renewal / takeover semantics
- append-only execution attempts / attempt events
- promotion and publish gates
- scoped agent identity and capability profiles
- review / approval states that keep humans as final promotion authority

#### Repo-local, portable, host-indexed

- durable issue graph / memory graph
- project-specific resource names and policy manifests
- task decomposition conventions
- project knowledge that should travel with the repo

#### Local / transient runtime

- worktree paths and session layout
- editor/terminal/runtime state
- ephemeral caches and scratchpads
- model context that never becomes decision-relevant

### Smallest valuable slice

The repeated strongest MVP answer was:

1. **Claims** on logical work units
2. **Leases** on shared mutable resources
3. **Execution attempt log** with supersession lineage
4. **Promotion gate** that preserves human review / merge authority
5. **Simple maintainer dashboard** showing claims, attempts, blockers, and items
   awaiting review

This is large enough to stop the most expensive collisions and small enough to
avoid becoming a workflow appliance.

### Recommended follow-on work

The round converged on follow-up work close to:

1. Define a canonical host object model for:
   - `Claim`
   - `Lease`
   - `Attempt`
   - `PromotionGate`
   - `ReviewState`
   - `AgentCapability`
2. Define resource classes and lease semantics:
   - acquire
   - heartbeat
   - expiry
   - takeover
   - operator override
3. Define a repo-portable manifest for project-specific resource names and
   promotion policies that the forge can understand without owning all local
   logic
4. Design the maintainer UX as a calm activity/promotion surface, not as an
   orchestration console
5. Keep host-native authority narrow but real:
   push/publish/review gating should be enforceable, not merely advisory

### Satisfaction marker

This round is satisfied if the next-generation forge evolves toward:

- portable repo knowledge
- narrow but enforceable host-native coordination primitives
- explicit human promotion authority
- and a maintainer UX that makes agent work legible without demanding
  orchestration expertise

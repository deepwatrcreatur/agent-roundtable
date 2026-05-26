## Round 133 — AgentField / SWE-AF vs Our Control-Plane Boundary

**Tags:** control-plane, orchestration, swarms, governance, execution, agentfield, swe-af  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis

### Round question

The maintainer wanted a fresh round on whether `AgentField` and `SWE-AF`
meaningfully change the current `agent-roundtable` / Vaglio control-plane line.

This was not a generic “is this cool?” question.
The actual decision problem was:

- do these projects validate the current narrow control-plane thesis
- do they imply we are underbuilding
- do they suggest a different product boundary
- and which parts are worth borrowing versus explicitly keeping out of scope

### Grounding used in this round

Relevant prior local context carried in:

- **Round 117** — forge-native coordination should stay narrow:
  claims, leases, attempt lineage, promotion gates, scoped authority
- **Round 118** — harnesses are disciplined local executors, not the sovereign
  coordination layer
- **Round 119** — optional hosted control plane should stay small and
  comprehensible, not become a workflow monster
- **Round 120** — backend substrate and governance/control-plane truth are
  different layers
- **Round 121** — orchestration belongs in the control plane, but execution
  runtime can remain external
- **Round 130** — build an independent narrow control plane; do not let a hosted
  product or substrate secretly become the architecture
- **Round 131** — local collision mitigation still starts with default isolation
  and preflight discipline

Fresh external grounding carried in:

- **`AgentField`**
  - presents as an open-source control plane where agents become API-callable
    services
  - bundles routing, coordination, memory, async execution, human approval,
    cryptographic identity, verifiable credentials, policy enforcement, harness
    orchestration, and production-agent infrastructure
- **`SWE-AF`**
  - presents as an autonomous engineering-team runtime built on `AgentField`
  - offers one-call engineering swarms, planner/architect/coder/reviewer/tester
    roles, nested control loops, DAG replanning, multi-repo mode, isolated git
    worktrees, checkpoint/resume, and explicit compromise/debt tracking

Important scope boundary carried into the round:

- the question was **not** whether these projects are interesting or impressive
- it was whether they should change the local architecture boundary already
  maintained across the control-plane rounds

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

- Strongest on the distinction between **market validation** and **boundary
  expansion**.
- Treated `AgentField` as clear proof that a control-plane category is real, but
  not as evidence that Vaglio should widen into a full runtime platform.
- Saw the strongest fit in:
  - claims/leases/identity/policy
  - pause/resume tied to attempt state
  - and a thin compatibility surface for external runtimes
- Treated `SWE-AF` as evidence that higher-order swarms intensify the need for
  governance, not that the governance layer should become the swarm runtime.

#### Gemini CLI

- Strongest on the phrase that `AgentField` validates the model while targeting a
  **broader infrastructure boundary**.
- Most explicit that the current project should not widen its ambitions just
  because a broader platform exists.
- Favored an explicit comparative note that distinguishes:
  - VCS-native governance/control plane
  - from broader agent infrastructure
- Strongest on the claim that identity-first discipline is the most clearly
  reusable part of `AgentField`.

#### Claude CLI

- Strongest on the argument that `AgentField` is a **full-stack platform** while
  the local project is deliberately a **narrow governance layer**.
- Treated the most reusable ideas as:
  - cryptographic agent identity / credentials
  - policy enforcement
  - and human-in-the-loop pause/resume semantics
- Most skeptical of prototyping an adapter immediately, arguing that coupling to
  a broader platform too early risks architectural drift.
- Strongest on keeping DAG/swarm/factory orchestration out of scope for the
  control plane itself.

#### DeepSeek API

- Strongest on the line that `AgentField` validates the local control-plane
  thesis while `SWE-AF` validates a **higher layer above it**.
- Most explicit that the right next move is:
  - study and borrow identity/policy/human-in-the-loop ideas
  - add a comparative design note
  - and, only if needed, prototype a very small compatibility surface
- Treated memory/service-mesh/runtime-centralization as the area most at odds
  with the repo’s portable-memory and narrow-boundary stance.

#### Copilot

- I agreed with the strong convergence that `AgentField` is best read as:
  - a useful design reference
  - possible future substrate/partner at the executor/runtime edge
  - and proof that the category is real
  - but not as the architecture to copy
- My strongest synthesis point was:
  `SWE-AF` does not show that we are underbuilding.
  It shows that scaled autonomous engineering makes claims, leases, lineage, and
  promotion semantics more necessary beneath the swarm runtime, not less.

### First-pass convergence

The substantive voices converged on the following points.

1. **`AgentField` validates the category more than it changes the architecture.**
   It confirms that identity, policy, human approval, and coordination above raw
   harnesses are real product needs.

2. **`AgentField` is broader than the current desired boundary.**
   It bundles:
   - coordination truth
   - execution/runtime behavior
   - memory/discovery/service-mesh ideas
   - and production-agent infrastructure
   in a way the local project has repeatedly decided not to absorb into one
   small control-plane layer.

3. **The strongest overlaps are identity, policy, and pause/resume.**
   These were the most consistently named ideas worth studying or borrowing.

4. **`SWE-AF` belongs above the control plane, not inside it.**
   Its planner/architect/coder/reviewer/tester/merger loops, DAG replanning, and
   engineering-factory posture are exactly the sort of larger workflow/runtime
   layer that earlier rounds chose not to fold into the hosted control plane.

5. **The current claims/leases/attempt-lineage/promotion model looks more
   necessary, not less.**
   If engineering swarms become more real, the need for a narrow governance layer
   underneath them increases.

6. **The project should not widen into an engineering-factory runtime.**
   The panel strongly rejected treating `AgentField`/`SWE-AF` as evidence that
   the local architecture should become a broader workflow engine.

### Real disagreements that remained

There was one meaningful tactical disagreement:

- **Codex**, **Gemini**, **DeepSeek**, and **Copilot** were open to a **tiny
  compatibility/adaptor surface** later, as long as canonical truth remained
  outside `AgentField`
- **Claude** was more skeptical of even that, arguing that premature adaptation
  could encourage boundary drift before the local object model is sharper

There was also a softer emphasis difference:

- **Claude** most strongly resisted any adapter step
- **Gemini** most strongly wanted an explicit comparative design note
- **Codex** and **DeepSeek** were the most comfortable with a very small
  executor/runtime compatibility seam if it stays narrow

These were disagreements about timing and risk tolerance, not about the overall
architecture.

### Final synthesis

The strongest answer from this round is:

- `AgentField` is important because it validates the existence of a real control
  / coordination market around agents
- but it is broader than the current desired local boundary
- and `SWE-AF` should be read mainly as proof that high-order agent swarms need a
  governance/control plane beneath them

The panel rejected two bad extremes:

- **bad extreme A:** “these systems exist, so we should widen into a full swarm /
  engineering-factory runtime too”
- **bad extreme B:** “they are irrelevant because they are broader than our
  project”

The maintained line is:

- keep the current narrow boundary:
  claims, leases, attempt lineage, promotion gates, scoped authority
- study `AgentField` for identity, policy, and pause/resume patterns
- treat `SWE-AF` as a higher-layer runtime that strengthens the need for our
  thinner governance/control plane
- and make the comparison explicit so future work does not re-open the same
  boundary question from scratch

### Recommended next-month move

1. **Add an explicit comparative design note** mapping:
   - the local control-plane boundary
   - `AgentField`’s broader runtime/platform shape
   - and `SWE-AF`’s engineering-factory layer

2. **Explicitly reaffirm the narrow boundary** in that note so future work does
   not drift toward workflow-engine maximalism.

3. **Study and borrow selectively**, especially:
   - cryptographic identity / verifiable-credential patterns
   - policy enforcement shape
   - pause/resume and human-approval semantics

4. **Only consider a tiny compatibility surface later**, and only if it preserves
   local canonical truth outside `AgentField`.

### Verdict

AgentField and SWE-AF validate the need for a control plane, but they are broader than the current target; reaffirm the narrow claims/leases/lineage/promotion boundary, borrow identity/policy/pause-resume ideas selectively, and do not widen into an engineering-factory workflow engine.

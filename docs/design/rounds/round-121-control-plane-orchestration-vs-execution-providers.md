## Round 121 — Control-Plane Orchestration vs Execution Providers

**Tags:** strategy, product, orchestration, control-plane, ci-cd, security, migration  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI (partial), Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** this round asked whether multi-agent orchestration should be
treated as an essential part of the control plane for an agent-oriented forge,
and what the fastest practical path is if execution still runs on today's
GitHub-compatible CI providers.

### Round question

The maintainer wanted to expand the project's emerging control-plane thesis:

- multi-agent orchestration may not be a separable workflow add-on
- an agent-oriented forge may need to treat orchestration as part of the control
  plane itself
- but the host may still want a fast path that works with today's external CI
  execution providers rather than immediately owning all compute

The sharp decision questions were:

- is multi-agent orchestration an essential part of the control plane, or still a
  separable workflow/execution layer
- what belongs in the host control plane versus in external execution providers
- what quick path of innovation works inside the existing GitHub-compatible CI
  ecosystem
- how existing CI providers should be reframed in this model
- what security/control improvements become possible immediately
- and what the host must avoid if it wants orchestration advantage without
  becoming a giant workflow appliance

### Grounding used in this round

Relevant prior local context carried into the round:

- **Round 117** — the forge should own a narrow coordination/trust plane above the
  VCS: claims, leases, attempt lineage, promotion gates, scoped authority
- **Round 118** — harnesses help at the edge, but the control plane owns shared
  coordination truth
- **Round 119** — the control plane should remain small and comprehensible rather
  than ballooning into a workflow monster
- **Round 120** — the moat is above the substrate in governance/control-plane
  truth, while storage and lower infrastructure may commoditize
- earlier security rounds — especially the Mini-Shai-Hulud and GitHub internal
  compromise line — repeatedly treated cache poisoning, overbroad credentials,
  release-authority leakage, and endpoint blast radius as control-plane failures

Important ecosystem framing carried in:

- existing CI execution providers already offer runners, scheduling, broad
  integrations, and migration familiarity
- many teams may want to keep those providers, even if a successor forge offers a
  tighter security model
- the near-term architecture is therefore likely to involve host-controlled
  orchestration with provider-delegated execution

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** partial but substantive; returned a strong position and detailed
  reasoning, then the client failed before completing a clean response
- **Claude CLI:** substantive
- **DeepSeek API:** substantive
- **Copilot:** substantive

This round therefore had a **full conceptual roster, with one partial seat**.

### Voice summaries

#### Codex CLI

- Strongest on the crisp boundary:
  orchestration belongs in the control plane because authority, collision
  avoidance, supersession, promotion, and publish rights require one sovereign
  source of truth.
- Treated existing CI providers as useful **controlled workers**, not as the
  rightful sovereign for workflow authority.
- Favored a fast path where:
  - the host owns claims, leases, trust tiers, promotion gates, and publish
    decisions
  - while external CI keeps scheduling compute and executing jobs
- Strongest on the concrete first slice:
  host-brokered promotion and authority over external CI, with a claim API,
  attempt ledger, trust-tiered artifact/cache registry, and human approval UI.

#### Gemini CLI (partial)

- Strongest on the phrase that orchestration is fundamentally an
  **essential control-plane responsibility**, not a separable workflow layer.
- Most explicit that GitHub's security failures came from conflating workflow
  runtime with control authority.
- Favored treating existing CI providers as **dumb, pluggable execution workers**
  while reclaiming claims, leases, promotion, and trust-tier state into the
  host.
- Most vivid on the fast path:
  an OIDC-brokered executor architecture where today's CI workflows become thin
  callouts to a host credential/lease broker.

#### Claude CLI

- Strongest on the exact distinction between:
  - **coordination authority**
  - and **execution runtime**
- Treated orchestration as inseparable from the control plane because claims,
  leases, promotion gates, and scoped authority are simultaneously:
  - governance primitives
  - security primitives
  - orchestration primitives
- Argued that GitHub's actual failure pattern proves the need for separation:
  CI should execute and attest, but not mint publish authority or define the
  final meaning of “green.”
- Favored a phased migration path:
  credential interposition first, then attestation evaluation, then agent lease
  integration, with optional native execution only later.

#### DeepSeek API

- Strongest on the claim that orchestration is the control plane's **primary
  expression of authority**.
- Most explicit that if the runner decides execution order, trust transitions, or
  lease validity, it becomes a de facto authority and recreates GitHub-style
  failures.
- Favored reframing today's CI providers as **controlled executors under host
  authority**, not merely as “commodity CI” and not as trusted sovereigns.
- Strongest on immediate security wins:
  host-issued scoped credentials, cache-tier enforcement, revocable job leases,
  and host-side quarantine/revocation above external execution.

#### Copilot

- I agreed with the core convergence that multi-agent orchestration is part of
  the control plane for an agent-oriented forge, because the same primitives
  keep recurring:
  claims, leases, attempt lineage, trust tiers, promotion, and scoped authority.
- My strongest synthesis point was:
  do **not** separate orchestration from control authority, but do separate
  control authority from execution runtime.
- I also agreed that the fastest innovation path is not to replace all CI
  providers, but to demote them into controlled executors under host-brokered
  leases, attestation, and promotion gates.

### First-pass convergence

The substantive voices converged on the following points.

1. **Multi-agent orchestration is an essential part of the control plane.**
   The panel did not treat orchestration as a bolt-on workflow convenience
   layer.
   It treated orchestration as the operational expression of the same shared
   authority model already identified in earlier rounds:
   claims, leases, scoped authority, attempt lineage, trust transitions, and
   promotion.

2. **Execution runtime is separable, but orchestration authority is not.**
   The central recurring boundary was:
   - host owns coordination authority
   - external providers may still execute jobs

   This is the clean split between “who may act and what it means” versus “who
   ran the code.”

3. **Existing CI providers should be reframed as controlled executors.**
   They remain useful for:
   - runner infrastructure
   - scheduling
   - logs
   - job execution
   - integrations

   But they should not remain the sovereign for:
   - publish/release authority
   - cache trust transitions
   - supersession semantics
   - or the final meaning of CI success

4. **The fastest path works inside today's ecosystem.**
   The strongest recurring near-term path was:
   - host issues leases and scoped credentials
   - external CI runs jobs and returns attestations/artifacts
   - host records attempts, applies trust tiers, and evaluates promotion gates
   - humans remain final promotion/publish authority

5. **Immediate security gains are available before owning compute.**
   The recurring examples were:
   - untrusted CI success no longer implying publish authority
   - trust-tiered caches and artifacts
   - scoped short-lived credentials instead of ambient broad tokens
   - superseded attempts being blocked from promotion
   - centralized quarantine/revocation above external execution

6. **The host must avoid becoming a giant workflow engine.**
   The panel repeatedly rejected:
   - DAG-engine maximalism
   - absorbing all runtime scheduling logic
   - replacing CI configuration languages on day one
   - or building a Temporal/Airflow-for-code appliance

### Real disagreements that remained

There was no major strategic disagreement, but there were real differences in
emphasis and migration framing:

- **Gemini** most strongly pushed the “existing CI becomes dumb workers” framing
- **Claude** most carefully articulated the phased migration path and the bright
  line between authority and runtime
- **Codex** most strongly emphasized host-brokered promotion and authority as the
  smallest valuable product slice
- **DeepSeek** most strongly emphasized the security consequences if runners keep
  any de facto sovereignty

These were differences in product emphasis, not architecture.

### Final synthesis

The strongest answer from this round is:

- yes, multi-agent orchestration belongs in the control plane for an
  agent-oriented forge
- no, that does **not** mean the host must immediately own all execution runtime
- and the cleanest near-term architecture is for the host to own orchestration
  authority while external CI providers act as controlled executors

The panel rejected two bad extremes:

- **bad extreme A:** “leave orchestration in workflow YAML / CI providers and keep
  the host mostly passive”
- **bad extreme B:** “the host must immediately become a giant native workflow
  appliance that owns all compute”

The maintained line is:

- keep the host authoritative for:
  - claims
  - leases
  - trust tiers
  - attempt lineage / supersession
  - promotion gates
  - scoped credential issuance
  - final merge/release/publish authority
- keep external CI providers responsible for:
  - compute
  - scheduling
  - sandbox execution
  - logs
  - and attestations
- keep humans as final promotion/publish authority

### Concrete first slice

The strongest recurring first slice was a **host-brokered CI authority layer**
over existing execution providers:

- claim / lease API with TTL and scoped ownership
- credential broker for short-lived host-issued job credentials
- attempt ledger with supersession
- trust-tiered artifact/cache handling
- attestation ingestion/evaluation
- host-native promotion gate for merge/release/publish
- simple human approval UI

That slice works with today's GitHub-compatible ecosystem, immediately improves
security and authority boundaries, and preserves the path to tighter native
execution later.

### Concrete follow-on work

1. Define the external execution adapter contract:
   lease request, scoped credential issuance, attestation submission, artifact
   registration, lease expiry, and abort/supersession behavior.
2. Define a trust-tier taxonomy for execution contexts, caches, artifacts, and
   promotion transitions.
3. Design the host-side credential broker for GitHub Actions-class providers and
   at least one other execution provider.
4. Specify how host-brokered promotion gates bind to attestation, trust tier,
   and human approval without turning into a workflow DSL.
5. Prototype a GitHub-compatible migration path where existing workflows keep
   most job logic but move authority and credentials to the host boundary.
6. Define quarantine/revocation behavior for attempts, artifacts, caches, and
   execution-provider credentials.

[satisfied-conditional: this position holds if the project preserves the bright
line between host-owned coordination authority and provider-delegated execution
runtime, and if the first implementation slice is a brokered authority layer
rather than a full workflow engine]

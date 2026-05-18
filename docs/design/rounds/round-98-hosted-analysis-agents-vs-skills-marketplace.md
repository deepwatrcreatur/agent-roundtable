## Round 98 — Hosted Analysis Agents vs Skills vs Provider Marketplace

**Tags:** product, tooling, hosting, integrity
**Status:** Closed  
**Voices used:** Claude CLI, Gemini CLI, Codex CLI, Copilot synthesis  
**Additional note:** DeepSeek CLI was requested conceptually by prior roundtable
method, but it was not installed in this environment and was therefore not
simulated or substituted

### Round question

The maintainer wanted a round about a successor to GitHub and a specific class
of heavy safety-analysis agent:

- an agent that continuously checks repos for dangerous Rust issues
- not just obvious `unsafe` counting, but broader undefined-behavior hunting
- potentially using very large harness "skills" with many subagents, scripts,
  experiments, Miri sweeps, and long autonomous runs

The narrower product questions were:

1. should this live as a **hosted agent** on the forge, like an advanced CI /
   GitHub Action successor
2. is that structurally better than a giant **skill inside a harness**
3. does the agent need to live on the hosting site, inside the repo boundary
4. or should there be a competitive **marketplace of external analysis providers**
5. who should own the final release gate when dangerous-code findings matter

### Relevant prior context

This round builds directly on:

- **Round 71** — repo-embedded skills are real, but should remain narrow,
  explicit, versioned, and inspectable execution-knowledge artifacts
- **Round 76** — open `SKILL.md` can be adopted at the artifact layer, but
  orchestration, permissions, logging, and policy remain separate
- **Round 77** — skills are justified only when they wrap concrete repo-local
  procedures and stop conditions, not when they become giant capability bundles
- **Round 93** — the successor to GitHub should likely own core baseline search
  rather than outsource it wholesale
- **Round 95** — the host should contribute routing and quality signals, but
  routing should remain inspectable
- **Round 97** — distributed local knowledge and explicit cost/value signals are
  better than pretending one giant planner should encode the whole system

Those earlier rounds already implied an important distinction:

- **skills** are useful for narrow, transparent, repo-scoped execution guidance
- **platform capabilities** should live where scheduling, identity, policy,
  lineage, memory, and gating can be made durable and inspectable

### Participation record

What actually happened in this run:

- **Claude CLI:** substantive
- **Gemini CLI:** substantive
- **Codex CLI:** substantive
- **DeepSeek CLI:** unavailable in the environment, explicitly omitted

### Voice summaries

#### Claude CLI

- Strongest on the claim that this is a **hosted platform capability**, not a
  repo skill.
- Treated the giant unsafe/UB harness as proof that the capability is valuable,
  but not as proof that a giant skill is the right final packaging.
- Emphasized structural host advantages:
  - persistent compute
  - long-running orchestration
  - lineage-aware memory
  - release gating that does not trust a committer's local environment
- Supported external competition only behind a **platform-defined integration
  contract**.
- Strongest on the phrase:
  external providers contribute evidence; the host renders the verdict.

#### Gemini CLI

- Strongest on the image of this capability as a **scalable platform service**
  rather than a local artifact.
- Preferred the host as the authoritative data plane for:
  - lineage
  - search
  - memory
  - decision tracking
- Was the most affirmative about a competitive marketplace, especially for deep,
  specialist analysis engines.
- Preferred a **hub-and-spoke** architecture:
  - host as authoritative control/data plane
  - heavy processing in external or specialized environments
  - marketplace providers publish findings back into the host's memory system

#### Codex CLI

- Strongest on the clean architectural split:
  - host-native control plane
  - optional local / self-hosted / provider-run execution planes
- Treated repo skills as thin adapters only:
  - scope hints
  - suppressions
  - reproducible entrypoints
  - audit playbooks
- Emphasized that the **source of truth** for findings, waivers, prior
  experiments, and decision history should live on the hosting site even if the
  compute runs elsewhere.
- Most explicit that the marketplace is valuable precisely because no single host
  team is likely to dominate UB discovery forever.

#### Copilot

- Agreed with the converged answer that the quoted giant Rust safety skills are
  best understood as **makeshift packaging around a real platform capability**.
- Treated the important design move as:
  preserve the experiment registry, evidence model, and long-run audit loop, but
  relocate them into a host-owned analysis surface with pluggable analyzers.
- Treated repo-local skills as still useful, but only as bounded local adapters
  for invoking, scoping, or reproducing analyses.

### First-pass convergence

All three live CLI voices converged strongly on the following points.

1. **This capability should not remain primarily a giant repo-embedded skill.**
   The giant skill is evidence of demand and methodology, but it is not the best
   long-run product packaging.

2. **The successor forge should own a hosted analysis control plane.**
   The host is the natural home for:
   - scheduling
   - identity
   - policy
   - result storage
   - lineage-aware memory
   - reviewer UX
   - final gating

3. **Heavy execution does not need to be physically colocated with the host.**
   The compute can be:
   - host-managed
   - self-hosted by the customer
   - or provider-run

   But the host should remain the canonical place where findings, experiments,
   waivers, and outcomes become durable project memory.

4. **A provider marketplace is good, but only behind a host-owned contract.**
   The round did **not** support a raw external free-for-all where providers own
   the canonical truth surface. It supported competition behind:
   - normalized evidence schemas
   - provenance requirements
   - replay metadata
   - confidence and severity structures
   - policy-aware result ingestion

5. **Repo skills still have a role, but a narrow one.**
   Repo-local skills remain appropriate for:
   - scope hints
   - suppression conventions
   - reproducer entrypoints
   - local audit playbooks
   - bounded interpretation guidance

   They are not the right home for the full persistent analysis engine.

### Recommended architecture

The strongest converged design is:

#### 1. Host-owned control plane

The forge should own:

- repo identity and permissions
- analysis policy
- event triggers
- scheduling and routing
- evidence schema
- lineage-aware memory
- reviewer UX
- waiver / exception records
- release-gate enforcement

#### 2. Pluggable execution plane

The actual analysis engines can run as:

- first-party host agents
- customer self-hosted runners
- third-party specialist providers

This is especially attractive for UB hunting because:

- techniques evolve fast
- provider specialization matters
- no single engine will remain best forever

#### 3. Durable evidence model

Every provider should emit normalized artifacts such as:

- finding records
- taxonomy/classification
- reproducer or experiment metadata
- tool/runtime configuration
- confidence / severity claims
- remediation proposals
- later verification outcomes

This is where the host's lineage-aware memory becomes the differentiator rather
than merely "we also ran Miri."

#### 4. Repo-attached policy and config

The repo should still be able to declare:

- audit scope
- risk tiers
- suppressions / waivers
- escalation rules
- reproducible local harness tasks

But those config artifacts are attachments to the hosted system, not substitutes
for it.

### What the round rejected

The round rejected these weaker shapes:

1. **"Just keep it as a giant skill."**
   This leaves scheduling, persistence, gating, and evidence lineage too fragile
   and too dependent on local harness quality.

2. **"The whole thing must physically live inside the repo boundary."**
   That confuses policy/context locality with compute locality.

3. **"Let external providers own the canonical release gate."**
   That creates hold-up risk, fragmented trust anchors, and poor exception
   governance.

### Work items created from this round

- [`82-hosted-analysis-provider-contract.md`](../../work-items/82-hosted-analysis-provider-contract.md)
- [`83-hosted-analysis-release-gate.md`](../../work-items/83-hosted-analysis-release-gate.md)

### One-sentence verdict

The quoted giant Rust safety skills are best treated as prototypes of a real
platform capability: the successor to GitHub should own a hosted analysis
control plane and final release gate, while allowing a competitive marketplace
of first-party, self-hosted, and third-party analyzers behind a normalized
evidence and policy contract.

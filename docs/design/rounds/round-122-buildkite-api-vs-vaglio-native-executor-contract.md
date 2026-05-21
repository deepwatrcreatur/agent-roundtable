## Round 122 — Buildkite API Canonical Form vs Vaglio-Native Executor Contract

**Tags:** strategy, product, orchestration, ci-cd, execution, adapters, buildkite, depot  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** this round asked whether Vaglio should adopt Buildkite's API/job
model as the canonical internal form for controlled execution, or define its own
narrower executor contract and treat Buildkite and other providers as adapters.

### Round question

The maintainer wanted a follow-up to Round 121 that moved from the broad
"controlled executors under host authority" line into a sharper implementation
question:

- Buildkite is the clearest current example of a direct CI job/build API with
  polling agents
- Depot CI now has a real standalone CI engine, but its visible surface is still
  strongly GitHub Actions-shaped
- Blacksmith shows an agent-first execution experience, but still inside GitHub's
  workflow and permission model
- nix-ci looks meaningfully multi-forge, but publicly presents as
  integration-driven rather than as a generic job-submission API

The key decision questions were:

- should Vaglio simply adopt the Buildkite API/job model as canonical
- or should Vaglio define its own narrower internal execution contract and map
  Buildkite, Depot, local runners, and more GitHub-shaped providers onto it
- what should be copied from Buildkite versus kept out of the sovereign model
- what does this imply for the first local/homelab runner
- and should the project subscribe to Buildkite now or first prove the native
  local runner path

### Grounding used in this round

Relevant prior local context carried into the round:

- **Round 120** — the moat is the governance/control plane above the hosting
  substrate, not the substrate itself
- **Round 121** — orchestration authority belongs in the control plane, while
  execution runtime may remain separable and delegated to controlled executors
- `docs/design/BOARD_EXECUTION_MODEL.md` — the board already models work items,
  attempts, human gates, runtime heartbeats, attempt events, and workflow
  definitions in a Vaglio-native way
- `docs/design/LOCAL_DAEMON_CONTRACT.md` — the daemon contract already models
  register / poll / claim / start / renew / gate / complete / fail / release as
  the core executor loop
- work items **95–97** — the queue already points toward a
  Buildkite-compatible controlled executor, a board kanban read model, and a
  browseable board surface

Current provider facts used in the prompt:

- **Buildkite**
  - REST API v2 exposes pipelines, builds, jobs, artifacts, agents, annotations,
    and teams
  - builds can be created programmatically
  - agents poll over HTTPS for work, execute jobs, stream logs, and upload
    artifacts
  - source-control integrations exist for GitHub, GitLab, Bitbucket,
    Phabricator, and generic git servers
- **Depot CI**
  - describes itself as a programmable CI engine built on its own orchestrator
    and compute layer
  - today uses GitHub Actions YAML as its first supported syntax
  - exposes local runs and manual dispatch via CLI/dashboard without needing a
    GitHub event
  - remains GitHub-shaped in migration, workflow import, and much of its visible
    compatibility surface
- **Blacksmith**
  - presents primarily as a drop-in replacement for GitHub runners
  - inherits GitHub org/repo permissions
  - documents GitHub allowlisting requirements for its control plane
  - even its agent-first Testboxes run inside real GitHub Actions jobs
- **nix-ci**
  - visibly supports GitHub, GitLab, and Codeberg/Forgejo integrations
  - but does not currently present a clearly documented generic job-submission API

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** substantive, but slower than the other seats and recovered on a
  bounded retry
- **DeepSeek API:** substantive
- **Copilot:** substantive

This round therefore had a **real full roster**, with one slower recovered seat.

### Voice summaries

#### Codex CLI

- Strongest on the line that Buildkite should be treated as the **best external
  comparison point and first compatibility target**, not as the sovereign
  internal model.
- Emphasized that the repo already points the right way:
  Buildkite-compatible executor, not Buildkite-canonical control plane.
- Strongest on the concrete copy/not-copy split:
  keep agent polling, explicit job envelopes, log streaming, artifact upload, and
  programmatic build creation;
  do not inherit pipeline/YAML truth, provider state taxonomies, or provider-side
  promotion meaning.
- Favored the local runner speaking the Vaglio-native claim/lease/attempt
  contract directly, with Buildkite layered on later as an adapter.

#### Gemini CLI

- Strongest on the warning that adopting Buildkite as canonical would
  accidentally surrender orchestration authority to external provider concepts.
- Treated Buildkite as a strong reference for the *agent polling protocol*, but
  not for the full sovereign object model.
- Most explicit that Depot CI proves both:
  - a real backend/orchestrator can sit underneath
  - and market pragmatism still forces many providers to expose GitHub-shaped
    surfaces today
- Argued that Blacksmith is mostly evidence of demand for separated compute, not
  a model for the internal contract.

#### Claude CLI

- Strongest on reframing work item 95 as already basically correct:
  Buildkite-informed and Buildkite-compatible, but not Buildkite-bound.
- Favored documenting a native controlled-executor protocol first, then
  implementing a local runner against it.
- Most explicit about what to borrow from Buildkite:
  - poll model
  - job as unit of execution
  - artifact upload pattern
  - compact result/annotation ideas
- Also most explicit that the project should resist paying for Buildkite before
  the native local runner has validated the contract.

#### DeepSeek API

- Strongest on the market-structure point:
  Buildkite is the only provider in the researched set that currently looks
  cleanly Buildkite-shaped, while much of the rest of the market remains
  GitHub-shaped.
- Most skeptical that Buildkite could ever become the universal canonical form.
- Strongest on the lock-in risk:
  if Vaglio becomes Buildkite-shaped internally, every GitHub-shaped provider
  would first need to be translated into Buildkite concepts and only then back
  into Vaglio meaning.
- Favored the narrowest internal contract:
  claim, lease, attempt, event log, artifact, HITL gate.

#### Copilot

- I agreed with the strong convergence that Buildkite is the best current
  **reference architecture and likely first adapter target**, but not the
  canonical internal truth model.
- My strongest synthesis point was:
  Vaglio should copy the **executor boundary** lessons from Buildkite, not the
  full provider ontology.
- I also agreed that Depot is both:
  - a serious future backend worth keeping in view
  - and evidence that external providers can remain GitHub-shaped at the surface
    even when they have a deeper internal engine

### First-pass convergence

The substantive voices converged on the following points.

1. **Buildkite is the best current comparison point, not the canonical internal
   model.**
   The panel treated Buildkite as the strongest current external example of a
   direct programmable execution provider:
   API-visible builds/jobs, polling agents, logs, artifacts, and self-hosted or
   managed execution.
   But it did not treat that as grounds to make Buildkite's ontology sovereign
   inside Vaglio.

2. **Vaglio should keep a narrower native execution contract.**
   The recurring native primitives were:
   - claim
   - lease
   - attempt
   - attempt event
   - human gate
   - artifact / attestation reference
   - terminal result

   This matches the board and daemon documents already in the repo and preserves
   control-plane authority over supersession, trust tier, scoped credentials,
   promotion meaning, and attestation interpretation.

3. **Some Buildkite ideas should be copied into the adapter boundary, but not
   into the sovereign model.**
   The strongest recurring pieces worth copying were:
   - pull/poll agent model
   - explicit job envelope
   - programmatic dispatch
   - streaming logs
   - artifact upload
   - compact annotations/result summaries
   - clean separation between controller and worker

   The strongest recurring pieces to keep *out* of the canonical model were:
   - pipeline/YAML as the main truth model
   - provider-specific build/job lifecycle as canonical status
   - provider team/RBAC assumptions
   - SCM integration assumptions
   - any implication that executor success defines promotion meaning

4. **Depot CI should be treated as both a serious future backend and a
   GitHub-shaped transitional target.**
   The panel did not dismiss Depot.
   Its local run/dispatch capabilities and independent orchestrator matter.
   But the visible migration and compatibility surface remains GitHub Actions
   YAML-first today, so it should be treated as an adapter target, not as the
   sovereign contract.

5. **Blacksmith is mostly negative evidence for the internal contract.**
   The panel treated Blacksmith as useful evidence that:
   - fast isolated execution matters
   - agent-first test loops matter
   - and GitHub-shaped acceleration layers are commercially attractive

   But because it still inherits GitHub workflow and permission semantics, it was
   not treated as a model for the internal executor contract.

6. **The first local/homelab runner should speak the Vaglio-native contract
   directly.**
   This was one of the clearest convergences in the round.
   The local runner should directly implement the repo's native lease/attempt
   semantics rather than becoming a Buildkite-agent clone.

7. **Do not subscribe to Buildkite immediately.**
   The recurring recommendation was:
   - prove the native contract and local runner first
   - then build a Buildkite adapter as the first serious external compatibility
     layer
   - subscribe when external-executor validation, market access, or product demo
     value justifies it

### Real disagreements that remained

There was no major disagreement on the main decision.

The real differences were differences of emphasis:

- **DeepSeek** was the most skeptical that Buildkite should influence the native
  contract beyond a narrow executor reference boundary
- **Claude** was the most explicit about sequencing:
  document the protocol, validate the local runner, only then consider a paid
  Buildkite step
- **Codex** was the most comfortable calling Buildkite the first external adapter
  target
- **Gemini** most strongly emphasized the danger of external-provider ontology
  leakage into the sovereign model

These were not contradictions.
They all pointed to the same maintained line:
Buildkite-informed, Vaglio-native, adapter-layered.

### Final synthesis

The strongest answer from this round is:

- Vaglio should **not** adopt Buildkite's API/job model as its canonical internal
  form
- Vaglio **should** maintain a narrower internal controlled-executor contract
  based on claim, lease, attempt, event, gate, artifact, and terminal-result
  primitives
- Buildkite is the best current external reference and likely the best first
  serious adapter target
- Depot should remain in view as a future backend/adaptation target, but its
  current GitHub-shaped surface is exactly why the sovereign model should not be
  outsourced
- Blacksmith is evidence of the value of better execution substrate and
  agent-first testing loops, but not evidence that GitHub-shaped workflow
  semantics should shape Vaglio's core

The panel rejected two bad extremes:

- **bad extreme A:** “just make Buildkite the canonical form and map everything to
  that”
- **bad extreme B:** “invent a giant provider-neutral workflow universe inside
  Vaglio”

The maintained line is:

- keep the internal contract narrow and execution-facing
- let the control plane remain authoritative for trust/promotion meaning
- borrow Buildkite's useful executor lessons
- and add compatibility layers outward from the Vaglio-native core

### Concrete follow-on work

The round did not require a new queue item to make progress.
It instead clarified the intended sequencing of work already in the queue:

- **95** should remain Buildkite-compatible, not Buildkite-canonical
- the first implementation slice should prove the native local/homelab executor
  contract directly
- the first external compatibility layer should likely be a thin Buildkite
  adapter
- Depot remains worth tracking as a later adapter/backend target once the native
  contract is proven

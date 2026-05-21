## Round 120 — Backend Substrate vs Governance Startup Boundary

**Tags:** strategy, product, hosting, governance, control-plane, backend  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, Copilot synthesis  
**Additional note:** this round asked whether a startup can credibly specialize
in orchestration, governance, tracking of code decisions, and the optional
hosted control plane while relying on providers such as ERSC or `code.storage`
for the lower code-hosting / storage substrate.

### Round question

The maintainer wanted a direct startup-boundary answer:

- can a company focus on orchestration, governance, code-decision tracking, and
  the optional hosted control plane
- while delegating lower-level code-hosting / storage concerns to providers such
  as ERSC or `code.storage`

The sharp decision questions were:

- whether outsourcing the substrate gives away too much of the product
- what remains differentiated if the lower layer is rented
- whether this is smart specialization or dangerous dependence
- how to draw the boundary between:
  - backend provider
  - governance/orchestration startup
  - repo-local memory and artifacts
- whether this helps or hurts go-to-market
- whether the moat survives if the backend later moves upward
- and how the product should present itself publicly

### Grounding used in this round

Relevant local prior context carried into the round:

- **Round 60** — `jj` and `code.storage` solve different layers:
  local mutation / workspace model versus hosted infrastructure
- **Round 112** — `jj` is useful, but it is not sufficient as the whole product
  thesis
- **Round 117** — the forge should own a narrow coordination / trust plane above
  the VCS, not the whole workflow
- **Round 119** — the hosted control plane should be explained as a small shared
  coordination layer, not a giant orchestration monster

External factual grounding carried in:

- `code.storage` public positioning as API-first Git infrastructure for
  AI-driven coding products, with low-latency Git cloud, SDK/API surfaces,
  webhooks, sync, and uptime/SLA framing
- earlier local ERSC / Pierre analysis that treated better VCS/backend
  infrastructure as strategically relevant, but not as the whole product

Important grounding limit:

- direct fresh ERSC fetches were unreliable in this environment during the
  earlier research pass, so this round leaned partly on prior local ERSC
  analysis rather than on a fully refreshed live ERSC product read

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** non-conforming; it attempted repo-side edits instead of
  returning a clean seat answer, so it is not counted as a substantive voice
- **DeepSeek API:** substantive
- **Copilot:** substantive

This round therefore had a **degraded but substantive roster**.

### Voice summaries

#### Codex CLI

- Strongest on carrying forward the real lesson from Round 60:
  `jj` / Git substrate choice and governance/control-plane product are different
  layers, but the substrate still becomes strategically decisive if scale or
  latency forces dependence on one provider.
- Argued that the thesis remains credible only if the startup's canonical truth
  stays above the VCS in:
  - claims and leases
  - attempt / supersession lineage
  - review and promotion semantics
  - decision memory
  - maintainer trust support
- Sharpened the portability story with a tiered backend posture:
  - ordinary Git transport as the baseline contract
  - API-first providers such as `code.storage` as an optimization tier
  - a future `jj`-native backend as another optional tier
- Strongest warning:
  if the product only works well with one high-performance backend, then the
  claimed backend abstraction is rhetorical rather than real.

#### Gemini CLI

- Strongest on the strategic upside of outsourcing the substrate:
  do not spend the company on storage engines, packfiles, replication, and
  uptime plumbing if the real bet is the decision plane.
- Framed the real product as an **AI-native forge governance layer** that
  filters agent-scale change volume before humans see it.
- Most bullish on the idea that governance and organizational memory are the
  real moat, not repository persistence.
- Strongest on focus:
  let providers compete on infrastructure while the startup owns policy,
  orchestration, trust-weighting, and the human-to-agent handoff.

#### DeepSeek API

- Strongest on the need for **provider portability** and a real adapter
  boundary.
- Argued that the thesis works only if the startup owns:
  - decision semantics
  - orchestration policy
  - trust attestations
  - execution discipline
  - repo-portable memory
- Most explicit that the risk is commercial as well as technical:
  API drift, pricing leverage, outages, and upward feature expansion all become
  threats if the company binds too tightly to one backend.
- Strongest on public positioning:
  market the product as an **opinionated governance control plane that works
  with multiple backends**, not as a nicer skin on top of `code.storage`.

#### Copilot

- I agreed with the main convergence that the startup thesis is real **only if**
  the company refuses to collapse into “better hosting by proxy.”
- My strongest synthesis point was that the layer boundary must stay legible:
  - backend providers own persistence, transport, durability, and hardware
  - the startup owns governance truth, promotion semantics, and maintainer trust
  - repo-local artifacts preserve portable understanding across backend changes
- I also agreed with Codex's Round 60 addendum:
  backend-independence should be real at the product-contract level, while
  higher-performance provider APIs can still exist as optional performance
  tiers.

### First-pass convergence

The substantive voices converged on the following points.

1. **There is a credible startup thesis here.**
   The panel did not treat this as surrendering the product.
   It treated it as a sensible specialization move **if** the differentiated
   product is governance above the VCS rather than the code-host substrate
   itself.

2. **The durable differentiator is not storage.**
   The recurring list of differentiated assets was:
   - claims and leases
   - attempt and supersession lineage
   - decision records and rationale
   - review / objection / approval state
   - promotion discipline with humans as final authority
   - maintainer-facing trust and oversight surfaces

3. **The substrate still matters strategically.**
   No voice treated backend providers as neutral utilities.
   The panel repeatedly warned that scale, latency, API shape, outages, and
   pricing give infrastructure providers real bargaining power.

4. **The thesis only works if provider portability is real.**
   The startup must own its own canonical object model and avoid encoding its
   truth purely as provider-native branches, workflow artifacts, or event logs.

5. **Repo-local memory still matters.**
   Portable project knowledge should not become hostage to the hosted control
   plane or to any single backend provider.
   The repo should continue to carry the durable artifacts worth versioning with
   the work.

6. **The public story must not sound derivative.**
   The strongest positioning is:
   an opinionated governance/control plane over interchangeable backends,
   not “we happen to be the nicer UI for someone else's hosting stack.”

### Important tension that remained

There was broad agreement on the direction, but a real tension remained around
how strongly to commit to backend neutrality early.

- **Gemini** leaned more toward aggressive focus:
  do not sink the company into infrastructure work if the moat is elsewhere.
- **DeepSeek** leaned more toward defensive architecture:
  portability must be proven early or the company will end up strategically
  trapped.
- **Codex** sharpened the compromise:
  keep ordinary Git transport as the baseline contract, then treat faster
  provider-specific APIs as optional performance tiers rather than as hard
  product dependencies.

This was not a disagreement about the product boundary so much as a disagreement
about how much engineering must be spent up front to keep that boundary honest.

### Recommended product / stack boundary

The clearest boundary from the round is:

#### Backend code / storage provider

Owns:

- repository persistence
- VCS transport / sync
- branch / commit / object storage semantics
- replication, durability, uptime, and hardware choices
- webhook or event surfaces tied to code-host state changes
- optional performance primitives for high-velocity agent traffic

Should **not** be the canonical owner of:

- the startup's decision model
- human governance policy
- review and promotion semantics beyond base repo permissions
- repo-specific deliberation memory

#### Governance / orchestration startup

Owns:

- claims on work
- leases on contested mutable resources
- attempt records and supersession lineage
- review / objection / approval state
- promotion gates with humans as final authority
- trust / authority scopes
- maintainer-facing oversight, queue, and decision surfaces
- the cross-backend abstraction layer

This is the actual product.

#### Repo-local memory / artifacts

Owns:

- portable project memory
- rationale docs worth versioning with the repo
- policy or constraint artifacts that should survive host changes
- durable context that prevents the hosted control plane from becoming the sole
  custodian of project understanding

### Final synthesis

The strongest answer from this round is:

- yes, a startup can plausibly specialize above the substrate
- no, that does not mean the substrate is strategically unimportant
- and yes, this only remains a strong business if the company owns the
  authoritative governance truth above the VCS rather than turning into a thin
  frontend for another startup's infrastructure

The real moat is therefore not:

- better repo storage
- better packfile plumbing
- or better raw code-host throughput

It is:

- governance semantics
- decision and supersession memory
- promotion discipline
- maintainer trust support
- and the human-gated control plane that makes agent-heavy development legible
  and safe

The best design consequence is:

- make ordinary Git-compatible hosting the baseline portability contract
- support faster API-first backends like `code.storage` as optimization tiers
- preserve repo-local durable memory
- and refuse to let any single backend provider become the sole owner of the
  startup's canonical governance state

### Concrete follow-on work

1. Define the startup-owned canonical objects:
   `Claim`, `Lease`, `Attempt`, `Supersession`, `ReviewState`,
   `PromotionGate`, `AuthorityScope`, `DecisionRecord`.
2. Specify which objects are:
   - host-side live state
   - repo-local durable artifacts
   - derived/indexed views.
3. Design a backend adapter contract that supports:
   - plain Git-compatible hosting as the baseline
   - API-first Git hosting as an optimization tier
   - future `jj`-forward hosting as another optional tier.
4. Prove the product on at least one ordinary backend so the thesis does not
   depend on one infrastructure startup being right.
5. Define explicit export and migration semantics so customers can change
   backends without losing governance history.
6. Keep human promotion authority explicit in every path so the product does not
   drift into agent auto-merge with decorative oversight.

[satisfied-conditional: pursue this path only if the control plane is designed
as provider-portable from the beginning and the startup refuses to let any one
backend become the sole owner of its canonical governance state]

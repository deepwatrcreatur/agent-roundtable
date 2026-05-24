## Round 130 — Hosted Control Plane Backend, Cloud Partners, and Durable Execution

**Tags:** product, hosting, control-plane, exe.dev, replit, dbos, temporal  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, OpenCode free-model seat, Copilot synthesis  
**Additional note:** Gemini again required a shorter retry prompt before it
returned a substantive seat. OpenCode was again used as a real enrichment seat
via `opencode/nemotron-3-super-free`.

### Round question

The maintainer wanted a follow-up round on what the cloud/backend path should be
if the project moves beyond local collision mitigation and starts building a
real agent control plane.

The concrete question bundle was:

- should the future backend/control-plane story be built inside a Replit-like
  hosted product shape
- should exe.dev be treated as the likely execution-substrate partner while the
  project owns the control plane itself
- is exe.dev or Replit more strategically aligned for an eventual agent-control
  product
- how should durable execution systems such as DBOS or Temporal fit
- and how should the project evolve from today's GitHub Issues + Dolt +
  markdown work queues without overbuilding

### Grounding used in this round

Relevant prior local context carried in:

- **Round 117** — the forge-native system should own a narrow coordination/trust
  plane above Git/`jj`: claims, leases, attempt lineage, promotion boundaries,
  and scoped authority
- **Round 119** — the optional hosted control plane should be a small shared
  coordination layer, not a giant orchestration platform
- **Round 70** — orchestration borrowing is useful, but roundtable itself should
  not collapse into a total workflow engine
- **Round 129** — current local pain is real enough that isolated cloud
  substrates are already relevant operationally

Fresh external grounding carried in:

- **Replit docs / product shape**
  - shared task board
  - isolated task copies
  - shared backend/deployment/data across multi-artifact projects
  - parallel execution under one hosted product surface
- **exe.dev docs**
  - fast internet VMs
  - persistent disks
  - HTTPS/IAM defaults
  - GitHub integration
  - preinstalled coding agents
  - stronger evidence of agent-ready infrastructure than of a native control
    plane
- **DBOS docs**
  - durable workflows resume after crashes
  - workflow IDs can function as idempotency keys
  - durable/background workflow handles and step-level structure are first-class
- **Temporal docs**
  - crash-proof execution for long-running workflows
  - explicit resumption and durable workflow state are core product promises

Important scope boundary carried into the round:

- the goal was **not** to design a giant scheduler
- it was to find the clearest product/backend boundary for an agent control
  plane that stays aligned with prior rounds

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive after a shorter retry prompt
- **Claude CLI:** substantive
- **DeepSeek API:** substantive via direct HTTP API and local decrypted key
- **OpenCode free-model seat:** substantive via `opencode/nemotron-3-super-free`
- **Copilot:** substantive

This round therefore had a **full substantive core roster plus one substantive
enrichment seat**.

### Voice summaries

#### Codex CLI

- Strongest on the recommendation to **build the control plane independently**
  and keep it narrow
- Treated exe.dev as strategically better aligned than Replit because it looks
  more like agent-ready compute than an already-opinionated hosted workflow
  product
- Most explicit that the first serious slice should be durable
  `WorkItem`/`Claim`/`Lease`/`Run`/`Promotion` objects with substrate adapters
- Favored borrowing durable-execution ideas early but delaying any hard
  commitment to a heavyweight workflow engine

#### Gemini CLI

- Strongest on the distinction between **unbundled compute** and a **walled
  garden hosted product**
- Favored exe.dev as the more strategically compatible substrate because it does
  not collapse coordination logic into its own IDE/product layer
- Most favorable to a DBOS-like philosophy over Temporal, especially because the
  project already thinks in terms of durable state and lineage rather than a
  giant orchestration console
- Preferred a hot/cold state split:
  - hosted control plane for active coordination
  - repo-local artifacts for slower-changing work definition and history

#### Claude CLI

- Strongest on calling Replit a likely **competitor-shaped dependency** rather
  than a clean substrate
- Most explicit that exe.dev is the better substrate partner precisely because
  it is thinner and less semantically invasive
- Favored an independent control plane with multiple substrate targets as the
  cleanest architecture boundary
- Strongest against adopting Temporal or DBOS too early as product-shaping
  dependencies

#### DeepSeek API

- Strongest on the line that both Replit and exe.dev should be treated as
  **external execution substrates**
- Most explicit that Replit's built-in coordination surfaces are attractive but
  boundary-confusing for a project that wants to own the trust plane itself
- Favored a strangler-fig migration:
  first move attempt lineage and lease state into a hosted service, while
  keeping work definitions and durable project artifacts repo-local
- Most concrete that the first backend slice should be a hosted
  attempt-lineage + lease service, likely targeting exe.dev first

#### OpenCode free-model seat

- Reinforced the same independent-control-plane boundary as the stronger seats
- Favored exe.dev as the better substrate because it is less bundled with
  coordination semantics than Replit
- Strongest on keeping DBOS/Temporal out of the first slice and treating them as
  optional later additions rather than immediate foundations

#### Copilot

- I agreed with the convergence that Replit is stronger today as a hosted
  product, but exe.dev is more strategically aligned as a substrate if the
  project wants to own the control plane
- My strongest synthesis point was that the backend should first become a narrow
  hosted claim/lease/lineage layer with substrate adapters, not a general
  workflow system
- I also agreed that DBOS/Temporal ideas are more valuable right now than a hard
  dependency on either product

### First-pass convergence

The substantive voices converged on the following points.

1. **The project should own an independent narrow control plane.**
   The cleanest architecture is not Replit-as-everything or exe.dev-as-the-whole
   product, but project-owned coordination logic above multiple possible
   substrates.

2. **exe.dev is the better-aligned substrate partner.**
   It behaves more like agent-ready infrastructure and less like an already
   opinionated hosted workflow product.

3. **Replit is strategically informative but boundary-dangerous.**
   Its product proves the value of isolated task copies and hosted coordination,
   but that very strength makes it less suitable as the neutral substrate for a
   project that wants to own the coordination layer.

4. **DBOS/Temporal should not define the first serious slice.**
   The round liked durable execution concepts such as idempotency, resumability,
   and crash recovery, but did not favor adopting a full workflow platform
   before the control-plane object model is proven.

5. **The first migration target should be active coordination state.**
   Claims, leases, heartbeats, attempt lineage, and promotion state are the
   pieces that most want a single hosted source of truth.

6. **Repo-local work definition should remain portable longer.**
   Markdown queue files, durable discussion artifacts, and code/project history
   should not be the first things absorbed into a hosted backend.

### Real disagreements that remained

There was no major strategic disagreement, but there were real differences in
implementation taste:

- **Codex** was most willing to define the first serious hosted object model in
  concrete API terms immediately
- **Gemini** was the most favorable to a DBOS-style philosophy once the project
  is ready for more durability
- **Claude** was most skeptical of taking on workflow-engine dependencies early
- **DeepSeek** was strongest on the phased migration path from today's
  GitHub/Dolt/markdown state

These were differences in timing and mechanism, not direction.

### Final synthesis

The strongest answer from this round is:

- **build the control plane independently**
- keep it narrow around claims, leases, lineage, promotion, and scoped
  authority
- target multiple substrates
- use exe.dev as the most plausible first execution substrate
- and avoid letting Replit's stronger hosted product shape become the hidden
  architecture of your own system

The panel rejected two bad extremes:

- **bad extreme A:** “just become a Replit plugin / workflow layer”
- **bad extreme B:** “adopt a heavyweight durable workflow platform before the
  control-plane boundary is even proven”

The maintained line is:

- repo-local and forge-local artifacts remain important
- hosted backend state should first absorb the active coordination layer
- durable execution ideas matter
- but the first backend slice is still a boring coordination service, not a
  full-blown orchestration engine

### Recommended product/backend boundary

#### Project-owned hosted control plane

- work claims
- expiring leases / heartbeats
- attempt lineage / supersession
- promotion boundaries
- scoped agent authority
- substrate adapter state
- minimal operator inspection surface

#### First execution substrate

- exe.dev VMs as the initial agent-ready substrate adapter

#### Strategic reference, not foundation

- Replit as evidence that hosted isolated task copies and apply-back semantics
  are product-valuable

#### Deferred or optional later layer

- DBOS/Temporal-class durable workflow engines, only if the narrow hosted
  control plane proves it needs them

### If only one serious backend slice ships next year

The repeated strongest answer was:

- **ship the hosted claim/lease/attempt-lineage service first**

That slice should:

- own active coordination truth
- expose a simple API
- sync with GitHub / forge state rather than replacing it
- attach to substrate adapters such as exe.dev
- and give operators a clean view of who owns what and which attempt is current

### Satisfaction marker

This round is satisfied if:

- the project commits to the independent-control-plane boundary
- exe.dev is treated as the first substrate partner rather than the whole
  product
- Replit is treated as a strategic reference point rather than an accidental
  architecture dependency
- and durable-execution dependencies stay deferred until the narrow hosted slice
  proves real pressure for them


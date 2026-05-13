## Round 72 — Obsidian as Interface, Not Canonical Memory

**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, `opencode/big-pickle`, `opencode/minimax-m2.5-free`, `opencode/nemotron-3-super-free`, Copilot synthesis  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wanted a follow-up on Obsidian, framed not as a random tooling
wishlist but as a question about interfaces to the council's knowledge
products.

The specific question was:

- should Obsidian become one important interface to the markdown files produced
  by the council
- is the Obsidian CLI / skills stack a good candidate for inclusion in the
  Vaglio appliance
- what parts of `obsidian-skills` are worth borrowing or packaging
- what must remain outside the canonical architecture

### Grounding facts used in this round

The round was grounded in public facts about `kepano/obsidian-skills`:

- the repo is **MIT licensed**
- it follows the **Agent Skills specification**
- it supports skills-compatible agents including Claude Code and Codex CLI
- it includes an `obsidian-cli` skill for interacting with a running Obsidian
  instance:
  - read / create / search / manage notes
  - manipulate tags, backlinks, tasks, and properties
  - support plugin/theme development through reload, error inspection,
    screenshot capture, DOM/CSS inspection, and app-context JavaScript eval
- it also includes adjacent skills such as:
  - Obsidian-flavored Markdown
  - Bases
  - JSON Canvas
  - defuddle

### Relevant prior context

This round built directly on:

- **Round 62** — discussion / board / Vaglio boundary
- **Round 63** — hybrid embedded design memory
- **Round 70** — selective borrowing from outside tools without reopening the
  architecture

Those earlier rounds already established:

- canonical memory must remain explicit and supersession-aware
- execution/runtime concerns must stay separated from discussion and
  long-horizon governance memory
- external tooling should be borrowed only where it sharpens an already-set
  boundary

### Participation record

Free-model roster requested where possible:

- `opencode/big-pickle`
- `opencode/nemotron-3-super-free`
- `opencode/ring-2.6-1t-free`
- `opencode/minimax-m2.5-free`

What actually happened:

- **Big Pickle:** substantive
- **MiniMax M2.5 free:** substantive
- **Nemotron 3 Super free:** substantive
- **Ring 2.6 1T free:** substantive

Standard local voices used:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive

### Voice summaries

#### Codex

- Strongest on the distinction between:
  - "canonical because it is a repo artifact"
  - "canonical because Obsidian understands it"
- Treated Obsidian as both a useful human-facing interface and a limited agent
  tool substrate, but never the system of record.
- Accepted optional packaging in the appliance, but only as a non-authoritative
  layer.
- Warned hardest about vault-centric drift and app-context side effects.

#### Gemini

- Strongest on the headless-server boundary.
- Rejected shipping the full Obsidian app / active `obsidian-cli` path inside
  the core Proxmox appliance.
- Favored a **BYO client** model:
  canonical markdown is Obsidian-ready, but humans or local agents open it
  outside the server appliance.
- Recommended borrowing Obsidian-flavored Markdown and JSON Canvas conventions
  as stateless output standards.

#### Big Pickle

- Strongest on "one-way export only."
- Treated Obsidian as a useful downstream human lens over canonical memory, not
  a write path.
- Rejected shipping the CLI/skills stack in the appliance now.
- Valued the Markdown/frontmatter conventions more than the app-coupled skill
  runtime.

#### MiniMax M2.5 free

- Strongest on the basic human-versus-governance distinction.
- Treated Obsidian as a high-quality optional human interface for markdown
  knowledge products.
- Rejected default bundling in the appliance.
- Preferred a documented one-way sync contract from canonical markdown into a
  vault.

#### Nemotron 3 Super free

- Strongest on keeping Obsidian as a read-only mirror or optional local
  interface.
- Accepted that it may be useful for human browsing and limited agent querying.
- Warned against letting Obsidian-specific metadata become governance truth.

#### Ring 2.6 1T free

- Strongest on the proprietary / GUI coupling objection.
- Treated Obsidian as a downstream viewer and pattern source for a future skill
  / export layer, not as a core appliance component.
- Supported a small factual experiment rather than broad adoption.

#### Copilot

- Agreed with the strong converged boundary:
  Obsidian is useful as an **optional interface layer**, but canonical memory
  and governance must remain outside the vault and outside Obsidian-specific
  state.
- Treated the most likely valuable borrowings as:
  - formatting conventions
  - export targets
  - local human/agent interface patterns

### First-pass convergence

All substantive voices converged on the following points.

1. **Obsidian is useful as an interface, not as the system of record.**
   No voice supported Obsidian becoming canonical memory.

2. **Canonical memory should remain repo-managed and tool-agnostic.**
   The project's durable truth should stay in markdown, explicit structured
   records, and related repo-native metadata, not `.obsidian`, plugin state, or
   vault-local conventions.

3. **The appliance should not depend on a running Obsidian app.**
   Voices repeatedly rejected turning a headless Proxmox / Nix appliance into an
   Obsidian/Electron runtime just to preserve a human interface pattern.

4. **Selective borrowing is still worthwhile.**
   The most promising parts are:
   - Obsidian-flavored Markdown conventions
   - export targets / derived views
   - `obsidian-cli` as a local optional bridge for human+agent workflows
   - Bases / JSON Canvas as derived views, not canonical data

5. **One-way export is the safest pattern.**
   The strongest recurring design was:
   canonical repo memory → derived Obsidian vault, never the reverse.

### What the round recommends borrowing

The most favored borrowings were:

- Obsidian-ready formatting conventions where they remain plain markdown
- export to a vault-like view as an optional downstream interface
- `obsidian-cli` as a local workstation tool for humans or local agents
- limited exploration of JSON Canvas / Bases as analytical or visualization
  surfaces

### What the round says to avoid

The round repeatedly rejected:

- making Obsidian artifacts canonical
- bundling Obsidian/Electron as a core server-side appliance dependency
- relying on plugin-specific schemas or vault metadata for governance truth
- bidirectional sync between vault state and canonical repo memory
- treating Obsidian's UX assumptions as the shape the rest of the system must
  fit

### Recommended experiments

The strongest small-scale experiments were:

1. Export a bounded slice of council artifacts into an Obsidian vault.
2. Test whether backlinks / graph view materially improve human review.
3. Test local-agent retrieval with and without `obsidian-cli`.
4. Standardize wikilinks / frontmatter where useful, but only as plain-text
   conventions.
5. Verify that explicit supersession remains legible without any Obsidian-only
   feature.

### Closure

The round closes with the following design rules.

#### 1. Obsidian is an optional interface layer

Useful, possibly even important for some operators, but not canonical.

#### 2. Canonical memory remains outside the vault

The project must not let convenience UI state become governance truth.

#### 3. Headless reliability beats desktop convenience in the appliance

The Proxmox / Nix appliance should remain server-safe first.

#### 4. Borrow conventions before dependencies

Formatting, exports, and simple integration points are safer than making the
stack depend on an Electron app.

#### 5. Use one-way export if this is pursued

Regenerable derived views are safer than sync-heavy shared-authority models.


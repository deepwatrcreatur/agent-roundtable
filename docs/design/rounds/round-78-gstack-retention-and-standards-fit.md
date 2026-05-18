# Round 78 — `gstack` Retention, Standards Fit, and Whether It Should Stay Installed

**Tags:** tooling, hosting, governance
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, free `opencode` voices where substantive, Copilot synthesis  
**Additional note:** `big-pickle`, `minimax`, and `ring` produced short but useful bounded comments late in the run; Codex and Gemini remained the main substantive voices  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wanted a grounded follow-up on Garry Tan's `gstack`:

- should it remain installed locally
- should it be removed now
- or should it survive only as an archive/reference source
- does it actually conform to the December 2025 open Agent Skills standard
- if adapted, what would the real gain be
- what should be preserved conceptually even if the local installation is removed

### Relevant prior context

This round built directly on:

- **Round 27** — earlier council discussion that treated `gstack` as a selective methodology reference rather than an end-state architecture
- **Round 71** — repo-embedded skills should be narrow, explicit, versioned, transparent, and activation-logged
- **Round 76** — the project should likely adopt external `SKILL.md` at the artifact layer while keeping local governance and activation stricter
- the current repo-skills push in `unified-nix-configuration` and `nix-router-optimized`, where the project is now creating its own local skill artifacts

### Local grounding

Before running the round, the local environment was checked.

Observed state:

- `gstack` was **not** on `PATH`
- `gstack-config` was **not** on `PATH`
- a full clone still existed at `~/.claude/skills/gstack`
- `~/.gstack` did not exist, so no obvious active runtime state was present there
- `~/.config/opencode/skills` did not exist
- `~/.codex/skills` contained only system skills, not `gstack`

Repo-local grounding:

- the active work repos did **not** appear to depend on `gstack` for current work
- `unified-nix-configuration` already had historical cleanup item
  `docs/tooling-work-items/10-remove-gstack-and-browse-coupling.md`
- old `/office-hours`-style generated docs still existed as evidence of prior use,
  but not of present dependency

External grounding gathered for the round:

- the current public `gstack` README
- an example `gstack` skill such as `office-hours/SKILL.md`
- the public Agent Skills specification from `agentskills.io`

### Participation record

What actually happened:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **`opencode/big-pickle`:** short but useful
- **`opencode/minimax-m2.5-free`:** short but useful
- **`opencode/ring-2.6-1t-free`:** non-substantive stub, excluded from synthesis

### Voice summaries

#### Codex

- Strongest on the distinction between:
  - `gstack` as a methodology/reference corpus
  - `gstack` as a live installed dependency
- Recommended archive/reference status rather than active use.
- Rejected trying to preserve the whole runtime or build compatibility shims.
- Strongest practical line: keep only the useful patterns, then rewrite selected
  skills into local, vendor-neutral artifacts.

#### Gemini

- Strongest on the claim that `gstack` is only **superficially adjacent** to the
  Agent Skills standard.
- Treated `gstack` as a proprietary runtime wrapped around `SKILL.md`, not as a
  portable standards-compliant skill layer.
- Recommended preserving the best ritual logic:
  - planning
  - review
  - QA
- Argued for relocation out of the ambient active skill path if it is kept at all.

#### Supporting free voices

- Reinforced the view that `gstack` creates ambient-activation and conceptual-drift
  risk if left lying around as if it were active tooling.
- Added that unused runtime-heavy skill trees still expand attack surface and
  create false affordances for future agents.

#### Copilot

- Agreed with the converged answer that the project's current direction is now
  clearer than the old `gstack` install:
  narrow repo-local and shared `SKILL.md` artifacts, explicit activation, local
  governance, and no hidden host runtime assumptions.

### First-pass convergence

The round converged on the following points.

1. **`gstack` should not remain as active local tooling.**
   The local environment does not currently rely on it, and its continued presence
   mainly creates ambiguity about whether it is part of the supported toolchain.

2. **If retained at all, it should be retained only as archive/reference material.**
   The strongest keep-case is as a methodology corpus to mine for useful ritual
   patterns, not as something agents should discover and activate implicitly.

3. **`gstack` is not meaningfully conformant with the recent Agent Skills standard.**
   It is adjacent in the weak sense that it uses `SKILL.md` and a directory-based
   packaging pattern. But its deeper structure depends on host-specific metadata,
   executable preambles, helper scripts, runtime assumptions, and product-specific
   conventions that conflict with the standard's portability and Markdown-first
   simplicity.

4. **Adapting it toward the standard would help only at the artifact level.**
   The real gain would be easier portability, clearer inspection, and less
   host/runtime lock-in. The round rejected trying to "standardize `gstack`" as a
   whole; instead, only selected rituals should be rewritten as fresh,
   standard-aligned local skills.

5. **Several conceptual pieces are still worth preserving.**
   The best survivors are:
   - explicit role/mode entry points
   - clear ritual framing for planning, review, and QA
   - skill directories bundling instructions with supporting artifacts
   - stronger output-contract thinking

6. **Leaving it installed but mostly unused has real costs.**
   The round repeatedly named:
   - false affordances for future agents
   - policy confusion about the real skill strategy
   - drift away from the new standards-aligned local direction
   - extra unused runtime and script surface

### Strongest reasons to keep or purge

#### Reasons to keep only as archive/reference

- it contains some genuinely useful orchestration ritual ideas
- it validates that directory-scoped skill artifacts and role/mode entry points can
  be effective
- it may still be worth mining for a small number of planning/review/QA patterns

#### Reasons to purge from active installation paths

- it is not part of the current supported workflow
- it is not on `PATH`, so it is already half-detached
- it is easy for future agents or maintainers to misread it as active capability
- it does not match the project's current standards-aligned local skill direction

### How well `gstack` fits the Agent Skills standard

The converged answer was: **only superficially adjacent**.

Shared traits:

- `SKILL.md` naming
- directory-based packaging
- a notion of reusable skill artifacts

Important divergence:

- heavy host/runtime coupling
- custom metadata and preamble logic
- executable/script assumptions outside the portable Markdown body
- product-specific activation and telemetry/update expectations

So the answer is not "already compliant" or even "mostly compliant." The project
should treat `gstack` as an independent nearby lineage, not as a drop-in
implementation of the standard.

### What to preserve even if purged

The round did **not** recommend throwing away every idea inside `gstack`.

The best candidates for preservation are:

- the ritual structure behind planning/review/QA modes
- role-scoped skill framing rather than giant omnibus prompts
- the idea that a skill directory can bundle instructions with local support files
- explicit output expectations and review posture

What should **not** be preserved:

- ambient activation
- host-specific runtime assumptions
- heavy executable preambles
- the implication that a local install is itself the orchestration architecture

### Concrete recommendation now

1. Treat the existing `~/.claude/skills/gstack` tree as **non-active** immediately.
2. Either move it to an archive location or delete it if the maintainer does not
   want it as a reference corpus.
3. Audit local config so no current settings or hooks still point at it.
4. If one or two rituals remain valuable, rewrite them from scratch as narrow,
   standards-aligned `SKILL.md` artifacts inside the relevant repo rather than
   trying to port the full `gstack` runtime model.

### One-sentence verdict

`gstack` should not remain as a live local dependency; at most it should survive
as quarantined reference material whose best ideas are selectively rewritten into
narrow, standards-aligned local skill artifacts.

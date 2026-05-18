## Round 101 — Depot and Blacksmith vs GitHub and the Other CI Providers

**Tags:** security, hosting, ci-cd, runners
**Status:** Closed  
**Voices used:** Claude CLI, Gemini CLI, Codex CLI, Copilot synthesis  
**Additional note:** the round was grounded in current vendor docs/summaries for
Depot and Blacksmith plus the prior comparison against GitHub Actions, GitLab,
CircleCI, Buildkite, and Azure Pipelines; DeepSeek CLI was not available in this
environment and was therefore not simulated

### Round question

The maintainer wanted a follow-up to Round 100 focused specifically on:

- **Depot**
- **Blacksmith**

The question was not just whether they are "better" than GitHub-hosted runners,
but how they compare on the specific Mini Shai-Hulud attack dimensions:

- pull-request trust confusion
- cache poisoning
- runner-memory token extraction
- trusted publish through the legitimate release pipeline

### Grounding facts used in this round

The round used the following current provider facts:

#### Depot

- a drop-in replacement for GitHub-hosted runners
- ephemeral single-tenant EC2 instances that are never reused
- repository-scoped cache
- **no branch isolation by default**; branches share the same namespace unless
  users encode isolation in cache keys
- per-job OIDC issued from `https://identity.depot.dev`
- still sits under GitHub Actions workflow and release control-plane behavior

#### Blacksmith

- a drop-in replacement for GitHub-hosted runners
- ephemeral Firecracker microVMs
- single-job JIT token adoption for the GitHub runner
- branch/tag cache scoping by default, with opt-out available
- still sits under GitHub Actions workflow and release control-plane behavior

### Relevant prior context

This round builds directly on:

- **Round 99** — `jj` helps with lineage and forensics, not innate prevention of
  raw CI/release-control-plane compromise
- **Round 100** — stricter CI providers can narrow the first stage of an attack,
  but the deeper lesson is release-authority separation

### Participation record

What actually happened in this run:

- **Claude CLI:** substantive
- **Gemini CLI:** substantive
- **Codex CLI:** substantive
- **DeepSeek CLI:** unavailable in the environment, explicitly omitted

### Voice summaries

#### Claude CLI

- Strongest on calling ephemeral single-tenant runners **table-stakes hygiene**
  rather than a full solution.
- Saw Depot as improved runner hygiene but still weak on the specific chain
  because cross-branch cache sharing remains open by default.
- Saw Blacksmith as marginally stronger because branch-scoped cache is the safer
  default on the exact poison-then-trust pattern that mattered here.
- Most explicit that neither touches the deeper control-plane problem.

#### Gemini CLI

- Strongest on the direct comparison:
  **Blacksmith offers better secure defaults to narrow this specific attack
  chain.**
- Treated Depot's lack of default branch-isolated caching as the critical
  weakness for this threat model.
- Saw Blacksmith's combination of Firecracker isolation, JIT job tokens, and
  default branch/tag cache scoping as the stronger package for this particular
  scenario.
- Still insisted both remain subordinate to GitHub's workflow trust model.

#### Codex CLI

- Strongest on the two-level framing:
  - substrate hardening
  - control-plane redesign
- Treated Depot as clearly better than plain GitHub-hosted runners on reuse and
  runner isolation, but still an incremental improvement rather than a redesign.
- Treated Blacksmith as stronger than Depot on the specific chain because
  branch/tag cache scoping is safer by default and directly relevant.
- Repeated the key limit:
  both remain under GitHub Actions for workflow triggering, trust decisions, and
  release execution.

#### Copilot

- Agreed with the converged answer that Depot and Blacksmith matter, but mostly
  as **runner-layer improvements**.
- Treated the strongest product lesson as:
  runner isolation is good hygiene; safe-by-default cache isolation is better
  hygiene; neither substitutes for host-native release-authority separation.

### First-pass convergence

All three live CLI voices converged on the following points.

1. **Both Depot and Blacksmith are stronger than plain GitHub-hosted runners on
   execution isolation.**
   Ephemeral, single-job, never-reused runners are meaningfully better than
   weaker shared-runner assumptions.

2. **Blacksmith appears stronger than Depot on the specific Mini Shai-Hulud
   attack dimensions used in this comparison.**
   The main reason is:
   - **branch/tag cache scoping by default**

   That directly narrows the cache-poisoning step without relying on user
   discipline.

3. **Depot still improves the runner substrate, but leaves a more meaningful
   cache-poisoning opening by default.**
   Repository-scoped cache is better than cross-repo ambiguity, but shared
   branch namespace remains too permissive for this threat model.

4. **Neither provider solves the deeper issue because both remain inside
   GitHub's workflow/release control plane.**
   If GitHub's workflow model still allows a bad trust transition, and if
   workflow success still implies access to trusted publish authority, neither
   Depot nor Blacksmith can fully override that architecture.

### Comparative assessment

#### Versus GitHub-hosted runners

Both Depot and Blacksmith look materially better on:

- runner ephemerality
- job isolation
- substrate hygiene

Blacksmith additionally looks better on:

- safer default cache trust boundaries

#### Versus GitLab / CircleCI / Buildkite / Azure

The round did **not** conclude that Depot or Blacksmith are obviously superior to
the stricter full-provider models from Round 100, because:

- those other providers can influence more of the workflow trust model itself
- Depot and Blacksmith mainly improve the runner substrate while inheriting
  GitHub's higher-level workflow semantics

So the round's comparative answer was:

- **better than plain GitHub-hosted runners**
- **Blacksmith > Depot on this specific chain**
- **still not a substitute for a safer full control plane**

### What the successor forge should learn

The strongest product lessons were:

1. **Runner hardening matters**
   Ephemeral isolated runners should be the floor.

2. **Cache trust boundaries matter just as much**
   Safe-by-default cache isolation across branches and trust domains should be
   the default, not left to user key design.

3. **Control-plane authority matters most**
   Even the best runner substrate is insufficient if the forge still lets
   ordinary workflow execution inherit trusted release authority.

### Work item created from this round

- [`87-safe-default-cache-trust-boundaries.md`](../../work-items/87-safe-default-cache-trust-boundaries.md)

### One-sentence verdict

Depot and Blacksmith both improve the runner substrate relative to plain GitHub
Actions runners, but Blacksmith appears stronger on the concrete Mini
Shai-Hulud-style chain because its branch/tag cache isolation is safer by
default; even so, both inherit GitHub's deeper workflow/release control-plane
limits, so neither replaces the need for host-native release-authority
separation.

## Round 77 — Skill Candidates for `unified-nix-configuration` and `nix-router-optimized`

**Tags:** tooling, structural, hosting
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Copilot synthesis  
**Additional note:** free `opencode` voices were attempted; `big-pickle` returned
only a non-substantive stub and the remaining free voices did not produce useful
bounded answers within the run window, so they were excluded from synthesis  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wanted a concrete round based on two real repos:

- `unified-nix-configuration`
- `nix-router-optimized`

The question was not whether "skills" sound generally useful, but whether these
specific repos actually justify them, and if so:

- which skills should exist
- which should be repo-local
- which should be shared across both repos
- whether some overlap justifies a dedicated shared skills repo

### Relevant prior context

This round built directly on:

- **Round 62** — the split between discussion, execution dispatch, and
  long-horizon governance/memory
- **Round 70** — borrow good orchestration ideas without adopting heavyweight
  foreign runtimes wholesale
- **Round 71** — repo-embedded skills should be narrow, explicit, versioned,
  transparently activated, and logged
- **Round 76** — the project should likely adopt the external `SKILL.md` format
  at the artifact layer while keeping local governance and activation stricter

### Grounding from the two repos

#### `unified-nix-configuration`

Observed recurring work loops included:

- `nix flake check`
- `nixos-rebuild switch --flake`
- `home-manager switch`
- `nh os switch`
- `nh home switch`
- repo-level `justfile` procedures for:
  - `rekey`
  - `gen-identity`
  - `install`
  - `clean-identity`
  - `router-smoke-check`
- agent guidance around:
  - host detection with `hostname`
  - choosing shared checkout vs worktree
  - preferring `/run/wrappers/bin/sudo` on NixOS where appropriate
  - remote tmux workflows
  - remote testing workflows
  - `agenix-edit` wrapper usage
  - queue-oriented onboarding
- architectural boundary docs such as:
  - `network-source-of-truth.md`
  - `router-spare-cutover.md`

This repo is also the live environment repo where the router flake is consumed
and where actual rebuild / deployment / management-plane decisions happen.

#### `nix-router-optimized`

Observed recurring work loops included:

- flake/module authoring and validation
- exported package `router-diag`
- substantial flake `checks` under `tests/`
- router-focused module work around:
  - networking
  - firewall
  - Technitium
  - Kea
  - DDNS
  - HA / VRRP / Keepalived
  - NAT64 / DNS64
  - VPNs
  - BGP
  - MWAN
- operator-style diagnostics through `router-diag.sh`:
  - `show interfaces`
  - `show firewall`
  - `show vpn`
  - `show health`
- contribution onboarding via work-item queue docs

This repo is more of a logic/module/test repo than a live environment repo, but
it still has important integration boundaries with the unified repo.

### Participation record

What actually happened:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Requested free `opencode` voices:** attempted, but not used in final
  synthesis because they were non-substantive or incomplete for this run

### Voice summaries

#### Codex

- Strongest on the distinction between:
  - low-authority shared workflow patterns
  - repo-local operational skills
- Recommended a two-layer model:
  - a very small shared skills library
  - richer repo-local adapters
- Treated obvious commands such as `flake check` as insufficient by themselves;
  they become skills only when wrapped in repo-specific procedures, stop
  conditions, and expected outputs.
- Recommended safety classes such as `readonly`, `local-mutation`, and
  `remote/live`.

#### Gemini

- Strongest on the phrase "orchestrated localism":
  shared reusable machinery, repo-local safety/context.
- Recommended strong repo-local skills for secret lifecycle, host provisioning,
  smoke testing, and router-state inspection.
- Rejected generic skills like `nixos-rebuild-switch` and `fix-networking` as
  too broad and too dangerous.
- Proposed that shared skills provide the "verbs" while repo-local skills add the
  "adverbs" that make those verbs safe in a specific environment.

#### Copilot

- Agreed with the converged answer that:
  - both repos justify skills
  - but the biggest risks live in the environment-specific procedures
- Treated the main architectural decision as:
  shared low-risk Nix workflow skills vs repo-local skills for rebuilds,
  secrets, diagnostics interpretation, and router boundary awareness

### First-pass convergence

The round converged on the following points.

1. **Both repos justify skills, but not the same kind.**
   `unified-nix-configuration` needs more operational/environment skills.
   `nix-router-optimized` needs more authoring/validation/diagnostic skills.

2. **A small shared library makes sense.**
   There is real overlap around Nix flake validation, targeted eval/test loops,
   queue/onboarding patterns, and documentation/example synchronization.

3. **The dangerous parts should stay local.**
   Rebuilds, secret operations, host provisioning, live router ops, and
   source-of-truth interpretation should not be flattened into generic shared
   skills.

4. **Commands alone are not skills.**
   `nix flake check`, `nixos-rebuild`, or `router-diag show health` are raw
   commands. They only become skills when packaged with:
   - entry criteria
   - boundaries
   - expected outputs
   - stop conditions
   - handoff/escalation rules

5. **A dedicated shared skills repo is not obviously justified yet.**
   The round saw the case for shared reuse, but the converged answer was to start
   much smaller than a full new catalog/registry/marketplace.

### Best repo-local skill candidates

#### For `unified-nix-configuration`

1. **`host-context-and-execution-mode`**
   - detect local host with `hostname`
   - choose shared checkout vs worktree
   - choose local vs remote execution path
   - remember `/run/wrappers/bin/sudo` expectations on NixOS

2. **`safe-rebuild-and-switch`**
   - wrap host-scoped rebuild commands
   - require preflight checks and post-switch verification
   - explicitly forbid ambient "just rebuild it" behavior

3. **`agenix-identity-and-rekey`**
   - wrap `rekey`, `gen-identity`, `install`, and `clean-identity`
   - capture repo-specific secret/identity lifecycle assumptions

4. **`router-management-plane-smoke-check`**
   - wrap `router-smoke-check`
   - preserve the management-plane invariants expressed in the repo

5. **`remote-router-ops-workflow`**
   - encode tmux-backed remote execution norms, caution boundaries, and stop
     points before live-impacting actions

6. **`boundary-doc-aware-change-planning`**
   - ensure relevant source-of-truth docs are consulted before making certain
     router/DNS/failover changes

#### For `nix-router-optimized`

1. **`router-module-eval-and-smoke-loop`**
   - map touched module areas to the relevant flake checks and eval suites

2. **`router-module-authoring-checklist`**
   - when a router module changes, update matching tests/examples/docs

3. **`router-diag-operator-readonly`**
   - standardize the safe, read-only use of `router-diag`

4. **`integration-contract-with-unified-config`**
   - clarify what belongs in this repo vs what remains source-of-truth in
     `unified-nix-configuration`

5. **`router-feature-invariant-review`**
   - for HA/firewall/networking composition work, ensure invariants and examples
     still match intended behavior

### Best shared skill candidates

The round supported a **small** shared library of narrow, low-authority patterns:

1. **`nix-flake-validation-loop`**
   - run `nix flake check`
   - narrow to targeted eval/checks where appropriate
   - interpret failures and stop follow-on risky steps if validation fails

2. **`targeted-nix-eval-for-changed-scope`**
   - map changed files/areas to narrower eval/test loops instead of always
     running everything

3. **`queue-onboarding-and-work-item-pickup`**
   - read `START-HERE`
   - find queue
   - pick bounded work
   - report assumptions/ownership clearly

4. **`docs-and-example-sync`**
   - ensure examples/docs stay aligned with module or procedure changes

5. **`attempt-history-and-provenance-discipline`**
   - ensure explicit recording of what was activated, why, and under which
     boundaries

The round also tolerated a very narrow abstract pattern for diagnostics, but only
as a pattern, not as a strong shared skill in itself.

### Skills or pseudo-skills to reject or defer

The round rejected or deferred:

- `nix flake check` as a standalone skill
- generic `rebuild`
- generic `fix networking`
- generic `manage secrets`
- generic `router diagnostics`
- shared `remote tmux workflow`
- `live router cutover`
- `cross-repo-sync`
- a marketplace/plugin-style skills system
- creating a large dedicated shared skills repo before there is clearer evidence
  of reuse across more repos

### Guidance on the maintainer's examples

The maintainer asked whether examples like `flake check` and router diagnostics
are actually good skill candidates.

The round's answer was:

- **not as-is**
- **yes when constrained**

That means:

- `flake check` is not a skill by itself, but a **validation loop** can be
- `router diagnostics` is too broad, but a read-only `router-diag` interpretation
  skill can be
- `rebuild` is usually too hazardous unless strongly gated and repo-local

### Smallest practical first slice

The strongest practical first slice was:

1. Add one or two **shared low-risk skills** for:
   - flake validation
   - targeted eval/test selection
2. Add one or two **repo-local skills**:
   - `router-management-plane-smoke-check` or `agenix-identity-and-rekey` in
     `unified-nix-configuration`
   - `router-module-eval-and-smoke-loop` in `nix-router-optimized`
3. Keep all of these:
   - explicit
   - versioned
   - logged on activation
   - safety-classed (`readonly`, `local-mutation`, `remote/live`)

### Open question left by the round

The main remaining disagreement was not over whether reuse exists, but over
**where to host the first shared layer**:

- Codex/Gemini-compatible view: a small shared library/trait layer is justified
- Big Pickle-like caution: do not create a separate dedicated skills repo yet

The convergence was:

- start with a **tiny** shared layer
- do **not** jump straight to a large standalone skills repo

### Closure

The round closes with the following rules.

#### 1. Shared skills should stay narrow and low-authority

They should encode repeatable workflow patterns, not broad power.

#### 2. Repo-local skills should own hazardous context

Rebuilds, secrets, remote execution, router ops, and source-of-truth boundaries
belong locally.

#### 3. Commands are not enough

A skill must include boundaries, interpretation, and stop conditions.

#### 4. Start with practical reuse, not catalog-building

Prove reuse with a handful of skills before creating a dedicated shared-skills
repo.


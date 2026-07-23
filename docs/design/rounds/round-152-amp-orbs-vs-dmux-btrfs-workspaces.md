## Round 152 — Amp Orbs vs the `dmux` / Btrfs Workspace Plan

**Tags:** amp, orbs, dmux, btrfs, workspaces, hosted-execution, agents  
**Status:** Closed  
**Voices used:** Codex CLI, DeepSeek API, Copilot synthesis  
**Additional note:** Gemini and Claude were requested as part of the practical
roster but did not produce usable seats. Gemini blocked on an authentication
browser prompt. Claude failed because its OAuth access token had expired. This is
therefore a degraded roster, not a full quorum.

### Round question

The maintainer asked for an actual roundtable after adding
`docs/design/AMP_ORBS_ROUNDTABLE_GUIDE.md`.

The question was whether Amp Code's Orbs should change the repo's current local
workspace direction:

- keep upstream `dmux` wrapper-first
- use a capability-based workspace backend layer
- treat Btrfs subvolumes as the strongest first Linux backend
- keep claims, leases, promotion, and scheduling above the filesystem backend

The competing external claim was that Amp Orbs are a superior alternative to
managing worktrees: each Amp thread can run in a fresh remote machine with a
cloned repo, setup/resume hooks, remote terminal/tmux, managed secrets/OIDC,
service portals, and `amp sync` back to local.

The round was explicitly instructed to compare Orbs against the actual maintained
`dmux` / Btrfs plan, not against bare `git worktree` alone.

### Grounding used in this round

Local grounding carried in:

- `docs/design/WORKSPACE_BACKEND_CAPABILITY_CONTRACT.md`
- `docs/design/BTRFS_BACKEND_AND_DMUX_WRAPPER_MODEL.md`
- **Round 131** — Btrfs subvolumes are valuable but secondary to isolated
  mutation by default; wrapper-before-fork remains the maintained line
- **Round 135** — under current means, the efficient frontier is wrapper-first
  on `dmux`, with only a narrow sidecar if measured use proves necessary
- **Round 140** — `rift` is a useful workspace-manager reference but not a
  substitute for the current `dmux` wrapper path
- **Round 141** — `herdr` is a stronger long-term control-plane candidate but
  not a reason to abandon the current implemented `dmux` guard
- **Round 150** — bare repos are ledgers, while agents still need materialized
  cognition and mutation surfaces
- **Round 151** — storage can become more virtual, but code agents still need a
  filesystem-real execution surface

External Amp grounding carried in from public docs checked for the guide:

- Amp news, "Agents in Orbs", published 2026-06-30
- Amp manual, "Orbs"
- Amp note, "Putting an Agent in an Orb", published 2026-07-02
- Amp news, "More Orb Sizes", published 2026-07-03

The shared prompt summarized Orbs as remote machines per Amp thread, with fresh
repo clones, `amp -ox`, `amp sync`, tmux/terminal sharing, project secrets,
short-lived OIDC, `.agents/setup`, `.agents/resume`, `.amp/services.yaml`,
Debian 12 tooling, 40GB documented disks, minute billing, and paused-orb
non-billing.

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive after rerun outside the restricted sandbox because
  Codex app-server initialization hit a read-only filesystem path
- **DeepSeek API:** substantive via direct HTTP API and local decrypted key after
  rerun outside the restricted sandbox because DNS was blocked
- **Gemini CLI:** unavailable; it blocked on an authentication/browser prompt
- **Claude CLI:** unavailable; OAuth access token had expired
- **Copilot:** substantive synthesis and independent position

This round therefore closes with **two real external seats plus Copilot
synthesis**, and must be treated as degraded compared with a full roster.

### Voice summaries

#### Codex CLI

Codex took the conservative architecture position.

It argued that Orbs should **not** change the current plan as a replacement.
They should be treated as a complementary hosted execution backend and
benchmark/watch item.

Codex's strongest distinction was that Orbs bundle many layers together:

- fresh clone
- hosted machine
- terminal/tmux
- setup hooks
- secrets
- services
- sync
- billing

That bundling is useful, but Vaglio's current plan intentionally separates
storage, mutable workspaces, execution, leases, promotion, and operator flow so
they remain inspectable and substitutable.

On failure modes, Codex judged:

- shared-checkout mutation: solved for Amp threads
- cleanup debt: partially solved, but cleanup authority moves into Amp
- long-running execution: strong fit
- tool availability: strong fit
- stale-success promotion: not solved by `amp sync`
- multi-agent contention: solved only at workspace/execution level, not at
  claims, leases, scheduling, or promotion

Codex placed Orb primarily in the **execution host** layer, with bundled support
for mutation workspace, cognition surface, operator terminal, environment
provisioning, secrets, and OIDC.

Against Btrfs-backed workspaces, Codex emphasized Orb's wins in hosted execution,
managed secrets, service portals, and lower setup burden, but its losses in
local snapshot/rollback inspectability, offline control, Nix-level
reproducibility, cost predictability, data residency, and provider neutrality.

Codex's recommended next step was a narrow benchmark:

- run one representative task through local `dmux` / Btrfs
- run the same task through `amp -ox`
- bring changes back with `amp sync`
- measure setup time, first action latency, sync behavior, stale-base handling,
  cost, secrets posture, logs, and promotion handoff

Codex ended `[satisfied]`.

#### DeepSeek API

DeepSeek was more favorable to Orbs on the concrete operational failure modes.

It argued that Orb wins on most immediate execution concerns:

- fresh clone avoids shared-checkout mutation
- whole-machine destroy reduces cleanup more comprehensively than subvolume
  deletion because it also clears processes, listeners, and temporary files
- remote execution handles long-running agents better than a local terminal tied
  to host uptime
- documented machine images improve tool availability
- machine-level isolation is stronger than filesystem-only isolation

DeepSeek also treated `amp sync` more favorably than Codex, calling it a clean,
explicit promotion path. But it still acknowledged that Orb does not own durable
ledger state, real coordination, or publish authority.

DeepSeek placed Orb primarily in the **execution host** layer, with significant
overlap into mutation workspace and operator console. It did not treat Orb as a
storage/ledger layer, durable cognition layer, full coordination plane, or
promotion/publish plane.

Against Btrfs-backed workspaces, DeepSeek saw Orb as stronger on:

- whole-machine cleanup
- fixed machine image
- managed secrets/OIDC
- remote long-running execution
- machine-level isolation

It saw Btrfs as stronger on:

- offline use
- zero marginal provider cost
- low latency
- local data residency
- operator-owned quota and lifecycle mechanics

DeepSeek's recommendation was still not a full pivot. It proposed adding Orb as
a **hosted execution backend** in the capability diagnostics layer, with a
possible wrapper flag such as `--backend orb` beside `--backend btrfs`.

DeepSeek ended `[satisfied-conditional: Orb is a complementary hosted execution
backend that should be added as an alternative target in the capability
diagnostics layer, not a replacement for the local Btrfs plan. The current plan
should continue with the Btrfs-first approach, but add Orb as a probed backend
option. The decision to elevate Orb above Btrfs requires evidence of local
workspace inviability, acceptable cost, inspectability closure, and wrapper
compatibility.]`

#### Copilot

I agree with the shared conclusion that Orb should not replace the current
`dmux` / Btrfs line now.

The important comparison is:

- not Orb vs raw worktrees
- but Orb vs a wrapper-first, capability-based workspace architecture that
  already separates execution, workspace lifecycle, claims, leases, promotion,
  and governance

On that comparison, Orb is highly relevant but mostly at the **hosted execution
backend** layer.

I give DeepSeek's pro-Orb arguments real weight. Whole-machine isolation and
cleanup are not trivial. Btrfs subvolume deletion does not kill stray processes,
clear process-local state, or provide remote continuation when a laptop sleeps.
Setup/resume hooks, service portals, managed secrets, OIDC, and terminal
inspection are product ideas worth taking seriously.

But those are not the same as replacing the architecture. Orb still leaves open:

- provider-neutral orchestration
- non-Amp seats such as Codex, Gemini, DeepSeek, and Copilot
- claim issuance and lease renewal
- stale-success detection
- promotion and publish authority
- repo-native auditability
- self-hosted and offline execution
- cost and data-residency boundaries

I therefore think Orb should be classified as:

- **complementary hosted execution backend**
- **strong benchmark target**
- **source of product-pattern borrowing**
- **not a replacement for the local workspace backend contract**

The most useful borrowable ideas are:

- `.agents/setup` and `.agents/resume` as explicit lifecycle hooks
- service declarations and preview portals
- remote terminal/tmux inspection as an operator affordance
- whole-execution cleanup as a capability worth naming separately from
  filesystem destroy
- managed short-lived credentials as an execution-provider capability

My decision threshold for changing the plan is similar to Codex's:

- Orb must be drivable non-interactively by the orchestrator
- lifecycle state, logs, result state, and sync semantics must be inspectable
- cost must be acceptable under realistic parallel-agent load
- sync must compose with stale-base and promotion checks
- provider-specific state must stay behind an adapter
- Amp must not become the durable governance or publish authority

Until that evidence exists, the maintained line should remain intact.

### First-pass convergence

The substantive voices converged on these points.

1. **Orb is relevant and should not be dismissed.**
   It is not merely a UI improvement. It provides a real remote execution
   substrate with fresh repo clones, agent-visible terminals, setup/resume hooks,
   secrets, OIDC, services, and whole-machine lifecycle.

2. **Orb is not a replacement for the whole `dmux` / Btrfs architecture.**
   Both Codex and DeepSeek placed Orb primarily at the execution-host layer, not
   at the durable ledger, coordination, claim/lease, or promotion/publish layers.

3. **Orb solves shared-checkout mutation for Amp-backed threads.**
   Fresh remote clones are a strong default against local shared-checkout damage.

4. **Orb is strong on remote long-running execution.**
   This is a real advantage over local `dmux` sessions tied to one host's uptime,
   network path, and process table.

5. **Orb weakens local autonomy and inspectability if made foundational.**
   Proprietary control-plane behavior, provider billing, data residency, and
   product-specific sync semantics are not acceptable as Vaglio's durable
   governance foundation.

6. **`amp sync` is not enough to replace governed promotion.**
   DeepSeek was more favorable to `amp sync`, but all voices still left durable
   ledger and publish authority outside Orb.

7. **The right near-term move is benchmark/adapt, not pivot.**
   The panel converged on treating Orb as an optional hosted execution backend
   and a benchmark target.

### Real disagreement that remained

The main disagreement was how much credit to give Orb for cleanup and promotion.

- **DeepSeek** gave Orb a stronger operational win because whole-machine
  lifecycle can delete more than a filesystem workspace and because `amp sync`
  gives an explicit handoff point.
- **Codex** was more cautious, arguing that cleanup and sync are provider
  product semantics and should not be confused with repo-native lifecycle,
  rollback, or promotion authority.
- **Copilot** agreed with DeepSeek on whole-machine cleanup value, but with
  Codex on not treating sync as governed promotion.

There was no disagreement that Orb should not replace the local architecture now.

### Decision

The maintained decision from this degraded but substantive round is:

- **do not pivot away from the `dmux` wrapper and workspace-backend contract**
- **treat Amp Orbs as a complementary hosted execution backend**
- **use Orbs as a benchmark/watch item**
- **borrow specific product patterns into local design**
- **do not let Orb own governance, claims, leases, durable state, or promotion**

The local `dmux` / Btrfs line still carries requirements that Orb does not:

- provider-neutral CLI orchestration
- local/offline and self-hosted operation
- capability-based backend selection
- explicit workspace lifecycle semantics under local control
- repo-native inspectability
- separation between mutation workspace, execution host, lease plane, and
  promotion authority

But the local design should add one concept sharpened by Orb:

> whole-execution cleanup is a separate capability from filesystem workspace
> cleanup.

That capability may be satisfied by remote VMs, containers, NixOS VMs, or other
execution providers, not by Btrfs alone.

### Recommended follow-up

1. Add a design note or work item for **hosted execution backends**, with Amp
   Orbs as the first comparator.

2. Extend the backend/capability vocabulary outside the filesystem layer to
   include:
   - whole-execution cleanup
   - remote continuation
   - setup hook
   - resume hook
   - service portal
   - managed short-lived credentials
   - provider billing visibility
   - sync-back handoff

3. Run a practical benchmark when Amp access is available:
   - one representative task through local `dmux` / Btrfs
   - the same task through `amp -ox`
   - measure cost, latency, setup success, tool parity, logs, sync behavior,
     stale-base handling, and promotion friction

4. Do not add Orb as a first-class backend until the API/CLI path can be driven
   non-interactively and inspected enough for Vaglio's orchestration model.

### Final synthesis

Amp Orbs are a serious hosted execution product, not a reason to abandon the
current workspace plan.

They should change the project's thinking by adding a sharper execution-provider
axis: local Btrfs workspaces solve isolated mutable filesystem lifecycle; Orbs
solve hosted whole-machine execution and continuation for Amp agents.

Those are complementary layers. The right architecture is therefore:

- keep local `dmux` / Btrfs as the first serious self-hosted workspace path
- preserve the capability-based backend contract
- add hosted execution providers as a separate adapter category
- borrow Orb's setup/resume/service/portal/secrets ideas where they fit
- require benchmark evidence before promoting Orb beyond optional backend status

[satisfied-conditional: this conclusion should be revisited after a hands-on
Orb benchmark that measures non-interactive control, sync semantics, cost,
inspectability, stale-base handling, and promotion handoff.]

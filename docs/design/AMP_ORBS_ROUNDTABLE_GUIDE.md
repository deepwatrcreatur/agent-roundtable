# Amp Orbs Roundtable Guide

**Status:** Draft leader guide

## Purpose

Use this guide to lead a real multi-agent roundtable on Amp Code's **Orbs** and
whether they should change the project's current local workspace direction.

The comparison is intentionally narrow:

- Amp Orbs as a remote, fresh-machine-per-thread execution product
- the repo's current wrapper-first `dmux` plan
- the workspace-backend contract with Btrfs subvolumes as the strongest first
  Linux backend

Do not let the round collapse into a generic "cloud agents vs local agents"
debate. The question is whether Orbs are actually a superior alternative to the
worktree and subvolume plan for this project's concrete failure modes.

## Source Packet

Read these local sources before launching the round:

- `docs/design/ORCHESTRATION_GUIDE.md`
- `docs/design/DISCUSSION_LEADER_SUMMARY.md`
- `docs/design/WORKSPACE_BACKEND_CAPABILITY_CONTRACT.md`
- `docs/design/BTRFS_BACKEND_AND_DMUX_WRAPPER_MODEL.md`
- `docs/design/rounds/round-131-dmux-btrfs-subvolumes-vs-wrapper.md`
- `docs/design/rounds/round-135-greenfield-worktree-btrfs-vs-dmux-efficient-frontier.md`
- `docs/design/rounds/round-140-rift-workspace-manager-vs-dmux-wrapper.md`
- `docs/design/rounds/round-141-herdr-vs-dmux-wrapper-and-what-to-do-now.md`
- `docs/design/rounds/round-150-bare-repos-vs-materialized-thinking-surfaces.md`
- `docs/design/rounds/round-151-agent-storage-backends-vs-posix-execution-surfaces.md`

Use current Amp material as external grounding:

- Amp news, "Agents in Orbs", published 2026-06-30:
  `https://ampcode.com/news/agents-in-orbs`
- Amp manual, "Orbs":
  `https://ampcode.com/manual/orbs`
- Amp note, "Putting an Agent in an Orb", published 2026-07-02:
  `https://ampcode.com/notes/putting-an-agent-in-an-orb`
- Amp news, "More Orb Sizes", published 2026-07-03:
  `https://ampcode.com/news/more-orb-sizes`

If running this guide after July 2026, re-check the Amp sources first. Orbs are a
new product surface and pricing, limits, setup hooks, and sync semantics may have
changed.

## Current Local Baseline

The maintained local plan is not "plain git worktrees forever."

The current baseline is:

- canonical repo storage may be bare
- agents need a materialized cognition surface for browsing and search
- mutating work should happen in isolated writable workspaces
- the `dmux` wrapper owns launcher discipline and operator flow
- the workspace backend contract owns isolated mutable workspace lifecycle
- Btrfs is the strongest first Linux backend because it can provide subvolumes,
  snapshots, writable clones, quotas, and fast cleanup
- claims, leases, promotion, and scheduling remain above the filesystem backend

The maintained escalation path is:

1. keep upstream `dmux` wrapper-first
2. add Btrfs-backed workspace creation where available
3. expose backend capability diagnostics
4. add a narrow lifecycle / lease sidecar only if wrapper hooks prove too weak
5. avoid a full greenfield workspace manager unless measured use justifies it

## Amp Orbs Baseline

As of the checked public documentation:

- an orb is a remote machine where an Amp agent can run without supervision
- each orb-backed thread starts with a fresh clone of the repository
- orbs can be started from the web, CLI, or TUI
- `amp -ox "prompt"` starts an execute-mode thread in an orb
- `amp sync <thread-id>` mirrors an orb thread's changes into a local checkout
- the orb terminal shares a filesystem and tmux session with the agent
- project secrets and environment variables can be configured for orb runtime
- an orb can mint short-lived OIDC tokens for cloud or internal service access
- committed lifecycle hooks include `.agents/setup` for fresh-orb preparation
  and `.agents/resume` for wake-up repair
- `.amp/services.yaml` can declare supervised dev services and portal exposure
- orbs run Debian 12 with common tools such as Git, SSH, authenticated `gh`,
  `amp`, PostgreSQL, Redis, tmux, ripgrep, ast-grep, Node tooling, Python, and
  `agent-browser`
- documented sizes range from `a0.tiny` to `a0.large`, with 40GB disk and
  minute billing; paused orbs do not bill

For this round, treat Orbs as a **managed remote execution surface** with fresh
repo clones, setup hooks, preview/terminal affordances, and sync-back workflows.
Do not assume they are literally a replacement implementation of local git
worktrees or Btrfs subvolumes unless the evidence shows that.

## Round Question

Ask every voice the same question:

> Amp Code now offers Orbs: fresh remote machines per Amp thread, with a cloned
> repo, setup/resume hooks, remote terminal/tmux, managed secrets/OIDC, portals,
> and `amp sync` back to local. Amp's public framing suggests this makes parallel
> remote agents much easier than managing local checkouts or worktrees.
>
> Given this repo's current maintained plan to build a wrapper around upstream
> `dmux`, backed by a capability-based workspace layer where Btrfs subvolumes are
> the strongest first Linux backend, should Amp Orbs change the plan?
>
> Compare Orbs directly against the current plan, not against bare git worktrees
> alone. Should Orbs be treated as a superior replacement, a complementary hosted
> execution backend, a benchmark/watch item, or mostly irrelevant to the local
> `dmux`/Btrfs direction?

## Required Subquestions

Each voice must address:

1. **Failure mode fit**
   Does Orb solve the repo's known problems: shared-checkout mutation, cleanup
   debt, long-running agent execution, tool availability, stale-success
   promotion, and multi-agent contention?

2. **Layer fit**
   Which layer does Orb primarily occupy?
   Choose explicitly among:
   - storage / ledger
   - cognition surface
   - mutation workspace
   - execution host
   - operator console
   - coordination / lease plane
   - promotion / publish plane

3. **Comparison against Btrfs-backed workspaces**
   What does Orb improve over local Btrfs subvolume-backed workspaces?
   What does it lose?
   Consider snapshots, rollback, quotas, fast destroy, offline control,
   reproducibility, secrets, network access, cost, latency, and data residency.

4. **Comparison against `dmux` wrapper**
   Does Orb replace the need for a local terminal/operator workflow, or does it
   merely provide one hosted execution backend that a future wrapper/control
   plane could target?

5. **Provider lock-in and inspectability**
   Does Orb's proprietary control plane, billing, and hosted runtime introduce a
   dependency that conflicts with Vaglio's repo-native, inspectable-governance
   direction?

6. **Adoption path**
   If Orb is useful, what is the smallest practical next step?
   Options include:
   - no implementation change, just benchmark/watch
   - document Orb as an optional remote backend for Amp-only tasks
   - add an adapter concept under the execution-provider layer
   - copy setup/resume/portal/service ideas into local workspace tooling
   - pivot away from `dmux`/Btrfs

7. **Decision threshold**
   What concrete evidence would justify changing the current plan?
   Require observable evidence, not product excitement.

8. **Satisfaction marker**
   End with one of:
   - `[satisfied]`
   - `[satisfied-conditional: X]`
   - `[needs more evidence: X]`

## Suggested Roster

Use the current real-round roster rules from `docs/design/ORCHESTRATION_GUIDE.md`.

Recommended minimum:

- Codex
- Gemini
- DeepSeek
- Copilot synthesis / independent position

Use Claude when available. Add an OpenCode/free-model enrichment seat only if it
can produce a real answer and is clearly labeled as experimental.

Do not simulate Amp, Sourcegraph, or any other vendor voice. If Amp itself is not
available as a CLI/product seat, treat Amp through public documentation only.

## Comparison Axes

Score each approach on these axes during synthesis:

| Axis | What to look for |
|---|---|
| Isolation | Can concurrent agents mutate without trampling each other? |
| Cleanup | Can abandoned workspaces be destroyed cleanly and cheaply? |
| Rollback | Are snapshots or equivalent recovery points first-class? |
| Cognition | Does the agent get a materialized, searchable repo surface? |
| Execution fidelity | Do builds, tests, browsers, daemons, and package managers behave normally? |
| Operator control | Can a human inspect terminals, logs, files, diffs, and running services? |
| Coordination | Are claims, leases, stale success, and promotion handled or merely displaced? |
| Cost | What is the steady-state and burst cost under many agents? |
| Portability | Does it work across Linux/macOS/local/offline/self-hosted constraints? |
| Inspectability | Can governance and lifecycle decisions be audited repo-natively? |
| Lock-in | How much does the workflow depend on Amp-specific infrastructure? |
| Integration effort | What can be adopted by one maintainer without a broad product rewrite? |

## Likely Hypotheses To Test

The leader should keep these hypotheses separate:

1. **Strong replacement hypothesis**
   Orb makes local worktree/Btrfs management mostly obsolete for this project.

2. **Hosted backend hypothesis**
   Orb is useful as one execution backend, but the local architecture still
   needs the same workspace, lease, promotion, and governance abstractions.

3. **Product-pattern borrowing hypothesis**
   Orb is most valuable as a pattern source: setup hooks, resume hooks, services,
   portals, managed secrets, and remote terminal inspection.

4. **Benchmark-only hypothesis**
   Orb should be watched and benchmarked, but should not alter current work
   because the `dmux`/Btrfs line solves local safety and offline autonomy better.

The synthesis should say which hypothesis won and why.

## Synthesis Traps

Avoid these mistakes:

- comparing Orb only to raw `git worktree` instead of the repo's actual
  wrapper-plus-backend plan
- treating "remote VM per agent" as proof that coordination, claims, stale
  success, or promotion policy are solved
- treating Btrfs as the architecture rather than one backend implementation
- ignoring that Orbs may be excellent for Amp agents while not helping Codex,
  Gemini, DeepSeek, or Copilot CLI orchestration directly
- ignoring costs when many long-running agents are active
- ignoring the value of local/offline control and self-hosted inspectability
- dismissing Orb because it is hosted even if it has useful operational patterns
- assuming `amp sync` is equivalent to a governed promotion path

## Expected Decision Shape

The most useful close is likely one of these:

- **No change:** continue `dmux`/Btrfs and re-evaluate after hands-on Orb tests.
- **Borrow patterns:** keep the plan, but add setup/resume/service/portal ideas
  to local workspace design.
- **Add optional backend:** treat Orb as an Amp-specific hosted execution provider
  that can sit beside local workspaces.
- **Pivot:** only if evidence shows Orb handles isolation, execution,
  inspection, cost, and promotion better than the local plan across the actual
  multi-agent roster.

The round should not close with "Orb is better than worktrees" unless it has
answered the stronger question:

> Better than the current `dmux` wrapper plus capability-based workspace backend,
> including Btrfs subvolume support where available, for this project's local and
> governance requirements?

## Durable Output Checklist

When the round is complete, persist:

- actual voices used and any degraded seats
- exact Amp docs checked and dates checked
- each voice's stance on replacement vs complement vs benchmark
- the final decision
- evidence required for changing the maintained line
- any concrete borrowed ideas that should become work items

If the round produces a decision, archive it as a normal round note under
`docs/design/rounds/` and update `docs/design/rounds/historical-synthesis.md`.

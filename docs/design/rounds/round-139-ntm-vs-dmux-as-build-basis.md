## Round 139 — `ntm` vs the `dmux` Wrapper Path as the Build Basis

**Tags:** tooling, tmux, dmux, ntm, orchestration, leases, control-plane  
**Status:** Closed  
**Voices used:** GPT-5.2-Codex, Claude Sonnet 4.6, GPT-5.4 mini, Copilot synthesis

### Round question

The maintainer wanted to know whether the `ntm` orchestration tool is a better
basis for this project to build on than the current local direction around
upstream `dmux`.

This was not a generic "is `ntm` interesting?" round.
The actual decision problem was:

- whether `ntm` should replace the current wrapper-first `dmux` direction as the
  practical near-term foundation
- whether `ntm`'s broader control-plane surface materially changes the local
  conclusion from recent `dmux` rounds
- and whether the project is actually missing something essential that `ntm`
  already provides, or merely noticing the same narrow sidecar gap already named
  by earlier rounds

### Grounding used in this round

Relevant prior local context carried in:

- **Round 131** — Btrfs worktree improvements are secondary; the primary next
  move is a wrapper around upstream `dmux` rather than an immediate fork or
  replacement.
- **Round 134** — VFS / virtual-working-copy work is mostly orthogonal to the
  current failure mode; keep the `dmux` wrapper path.
- **Round 135** — under current means, remain wrapper-first on upstream `dmux`;
  the only plausible escalation beyond that is a very small lifecycle / lease
  sidecar if measured use shows the seam is too weak.
- **Round 138** — terminal-centric orchestration tools belong more naturally in
  the orchestration / operator-shell layer than in the backend truth layer.

Fresh local evidence carried in:

- `dmux` is installed locally on `PATH` at
  `/etc/profiles/per-user/deepwatrcreatur/bin/dmux`.
- `ntm` is **not** on `PATH` in the current environment.
- `unified-nix-configuration` already wires in a local `dmux` package path:
  - `flake.nix` defines `dmux-flake = { url = "github:deepwatrcreatur/nix-dmux"; ... };`
  - `modules/home-manager/common/dmux.nix` exposes `programs.dmux.enable`
  - `users/deepwatrcreatur/hosts/workstation/default.nix` enables
    `programs.dmux.enable = true;`
- `unified-nix-configuration` currently shows no local `ntm` packaging or
  integration evidence.

External grounding carried in:

- the public `ntm` README positions it as a much broader local control plane on
  top of `tmux`, including:
  - session orchestration
  - graph-aware work triage via `br` / `bv`
  - Agent Mail coordination
  - file reservations / assignments
  - safety policy and approvals
  - checkpoints, timelines, audits, and pipelines
  - robot JSON plus REST / SSE / WebSocket / OpenAPI surfaces
- the local `dmux` README describes a much thinner operator loop:
  pane-per-task, isolated git worktrees, merge / cleanup flow, multi-project
  sessions, and lifecycle hooks

Important scope boundary carried into the round:

- the question was **not** whether `ntm` is architecturally ambitious
- it was whether `ntm` is the better basis **for this project now**, given the
  already-established local `dmux` direction and current integration state

### Participation record

What actually happened in this run:

- **GPT-5.2-Codex:** substantive
- **Claude Sonnet 4.6:** substantive
- **GPT-5.4 mini:** substantive
- **Copilot:** substantive synthesis

This round therefore had a **four-seat substantive roster**.

### Voice summaries

#### GPT-5.2-Codex

- Most disciplined about repo-grounded evidence over architectural attraction.
- Treated `ntm` as compelling only from the scope claimed by its README, not from
  any local operating evidence.
- Strongest on the point that the existing local decision history already
  converged on wrapper-first, while `ntm` is not yet packaged, installed, or
  integrated here.
- Recommended staying on the `dmux` wrapper path unless measured evidence later
  proves the hook seam cannot carry leases, cleanup, or rollback.

#### Claude Sonnet 4.6

- Most willing to acknowledge that `ntm` appears to bundle the exact class of
  sidecar capabilities earlier rounds predicted might eventually matter:
  reservations, approvals, checkpoints, audit, and richer coordination.
- Strongest on the argument that `ntm` is interesting because it covers the
  narrow lifecycle / lease sidecar gap natively rather than as an add-on.
- But still concluded that adopting it now would be a substrate bet before the
  current wrapper path has been made load-bearing.
- Treated `ntm` as a serious watch item, not a near-term replacement.

#### GPT-5.4 mini

- Most explicit that the project's current pain is still workspace isolation more
  than orchestration breadth.
- Strongest on the local evidence asymmetry:
  - `dmux` is already packaged and enabled in the local Nix environment
  - `ntm` has no local integration footprint
- Framed the real threshold clearly:
  `ntm` only becomes the better basis if the project's center of gravity shifts
  from isolated mutation workspaces toward a much broader agent-governance
  platform that `dmux` plus a small sidecar cannot cover.

#### Copilot

- I agreed with the overall convergence that `ntm` is not "just another pane
  tool"; it is a much fatter local control plane.
- My strongest synthesis point was that this broadness cuts both ways:
  - it is the strongest argument **for** `ntm`, because it includes the same
    kind of lease / approval / audit primitives the local rounds have been
    circling around
  - but it is also the strongest argument **against** switching now, because it
    expands scope sharply at the exact moment recent rounds kept saying the
    project should stop substrate-shopping and make the wrapper path real
- I therefore treated `ntm` as a plausible future comparator if the predicted
  sidecar gap becomes real, but not as a justified replacement today

### First-pass convergence

The substantive voices converged on the following points.

1. **`ntm` is broader than `dmux` in a meaningful way.**
   This is not just another UI for panes.
   Its claimed surface includes:
   - reservations / assignments
   - approvals / safety policy
   - timelines / audit / checkpoints
   - and machine-readable APIs

2. **That breadth does not overturn the current local conclusion.**
   The local project has already decided across several rounds that the next real
   move is to make the `dmux` wrapper path load-bearing, not to start a new
   substrate or orchestration migration.

3. **Local evidence strongly favors `dmux` today.**
   `dmux` is:
   - installed locally
   - packaged in `unified-nix-configuration`
   - and enabled on the workstation

   `ntm` is:
   - not on `PATH`
   - not locally packaged here
   - and not presently integrated into the Nix environment

4. **`ntm` mainly validates the predicted sidecar gap.**
   The most interesting thing about `ntm` is not that it disproves Round 135.
   It is that it packages a lot of the narrow lifecycle / lease / safety /
   coordination layer that Round 135 said might become the only justified
   escalation beyond the wrapper.

5. **The near-term recommendation still remains wrapper-first.**
   No substantive voice concluded that the project should switch to `ntm` now.

### Real disagreements that remained

There was one main difference of emphasis:

- **Claude** put the most weight on `ntm` as a serious future candidate because
  it appears to cover the same governance / reservation / approval layer the
  project may eventually want anyway.
- **Codex** and **mini** were more disciplined about the lack of local evidence
  and more resistant to granting `ntm` any near-term status beyond "watch item."

There was also a softer framing difference:

- **mini** emphasized that the current problem is still isolation, not broader
  orchestration
- while **Claude** emphasized that `ntm` becomes relevant precisely where the
  project starts caring more about who may act, what is reserved, and how risky
  operations get approved

These were differences of emphasis, not of direction.

### Final synthesis

The strongest maintained answer from this round is:

- `ntm` is a real control-plane-shaped tool, not merely a `tmux` wrapper
- that makes it architecturally interesting
- but it does **not** become the better build basis for this project today,
  because the project has not yet exhausted the narrower `dmux` wrapper path it
  already packages and uses
- and the current local evidence does not justify paying the migration and
  integration cost of adopting a much broader tool before the predicted wrapper
  seam has actually failed

The panel rejected two bad extremes:

- **bad extreme A:** "`ntm` is broader, therefore it must be the better basis"
- **bad extreme B:** "`ntm` is irrelevant because `dmux` already exists"

The maintained line is:

- keep the current `dmux` wrapper direction
- make isolated mutation, preflight discipline, cleanup, and lease-aware
  behavior actually load-bearing
- treat `ntm` as a serious watch item specifically at the boundary where a
  narrow sidecar might otherwise be built
- and only revisit the substrate question after real wrapper usage shows that
  the existing seam cannot carry the needed coordination model

### Recommended next step

1. **Proceed with the `dmux` wrapper path.**
   Shared-checkout mutation should keep moving toward abnormal / discouraged
   status.

2. **Measure whether the predicted sidecar gap becomes real.**
   Watch for concrete failures around:
   - reservations
   - stale ownership
   - cleanup / rollback lifecycle
   - and approval-gated risky actions

3. **Treat `ntm` as the comparison target if that gap opens.**
   If the project truly needs more than the wrapper seam can carry, the right
   next question is not "invent a bespoke control plane from scratch," but
   "does `ntm` already provide the narrow extra layer we now know we need?"

4. **Do not switch now on README scope alone.**
   First make the existing local path real; only then decide whether `ntm` is a
   complement, a sidecar replacement, or a later migration candidate.

### Verdict

Stay on the `dmux` wrapper path for now. `ntm` is best understood as a meaningful watch item that validates the likely future lifecycle / lease / coordination layer, not as evidence that the project should abandon the already-packaged and already-supported `dmux` basis before the current wrapper path has been made genuinely load-bearing.

## Round 141 — `herdr` vs the `dmux` Wrapper Path, and Whether to Add It Now

**Tags:** tooling, dmux, herdr, terminal, orchestration, worktrees, agents  
**Status:** Closed  
**Voices used:** GPT-5.4 mini, Claude Sonnet 4.6, GPT-4.1, Copilot synthesis

### Round question

The maintainer asked for a roundtable on `herdr` with two explicit questions:

- is `herdr` a better long-term basis than the current `dmux` direction for
  terminal-centric multi-agent work
- and should it be added now, or should attention stay on learning and using
  `dmux` well first

This was not a generic "is `herdr` cool" discussion.
The real decision was about whether a promising new terminal-native agent
multiplexer should change the current local implementation path.

### Grounding used in this round

Relevant prior local context carried in:

- **Round 131** — keep the first move small and wrapper-first rather than
  jumping immediately to a heavier workspace substrate
- **Round 134** — keep VFS / virtual working copy ideas separate from the
  immediate agent-collision problem
- **Round 135** — the practical efficient frontier under current means is still
  a narrow `dmux` wrapper with only a later sidecar/backend if real use proves
  it necessary
- **Round 139** — `ntm` is an interesting watch item because it bundles a future
  coordination layer, but it still does not displace the wrapper-first `dmux`
  line
- **Round 140** — `rift` is a useful backend/safety reference, but not a reason
  to abandon the current `dmux` wrapper direction

Fresh local implementation state carried in:

- `dmux` is already packaged and enabled in the local Nix environment
- a first real `dmux` safety slice is implemented locally in a clean
  `nix-dmux` worktree
- upstream installs as `dmux-upstream`, while the exposed `dmux` entrypoint is
  now a wrapper
- that wrapper:
  - classifies a Git root as **primary checkout** vs **linked worktree**
  - adds `dmux preflight`
  - blocks normal launches from the primary checkout by default
  - allows linked-worktree launches
  - preserves an explicit one-shot override via
    `DMUX_ALLOW_SHARED_CHECKOUT=1 dmux --allow-shared-checkout`
- the build succeeded and smoke checks confirmed:
  - primary-checkout preflight blocks
  - linked-worktree preflight allows
  - override preflight allows
- this is intentionally only a launcher-level guard:
  it does **not** yet provide leases, file claims, single-writer ownership,
  heartbeats, automatic worktree allocation, cleanup lifecycle, or a full
  control plane

Fresh external evidence carried in about `herdr`:

- upstream describes it as an **agent multiplexer that lives in your terminal**
- it provides:
  - workspaces
  - tabs
  - panes
  - mouse-native pane management
  - detach / reattach
  - a background session server
  - agent awareness with blocked / working / done / idle states
- the local socket API exposes:
  - workspace creation/list/focus/rename/close
  - tab creation/list/focus/rename/close
  - pane split/list/read/send input/close/wait
  - agent list/read/send/start/focus
  - event subscription / waiting
  - integration install / uninstall
  - and notably:
    `worktree.list`, `worktree.create`, `worktree.open`, and
    `worktree.remove`
- `worktree.remove` is explicitly conservative:
  it removes the linked checkout and **never deletes the branch**
- `herdr` session-state docs also describe:
  - detach with server persistence
  - restart restore
  - optional pane-history replay
  - native agent-session restore for several agents
  - experimental handoff
- supported or integrated agents include Codex, Claude Code, OpenCode, Pi,
  Hermes Agent, and Qoder CLI
- repo metadata at review time:
  - Rust
  - created `2026-03-27`
  - default branch `master`
  - about `3.4k` stars
  - includes `flake.nix`

Important scope boundary carried into the round:

- the local problem already solved in first slice is **shared-checkout mutation**
- the question is whether `herdr` changes what should happen **next**
- not whether `herdr` is more featureful on paper

### Participation record

What actually happened in this run:

- **GPT-5.4 mini:** substantive
- **Claude Sonnet 4.6:** substantive
- **GPT-4.1:** substantive
- **Copilot:** substantive synthesis

This round therefore had a **four-seat substantive roster**.

### Voice summaries

#### GPT-5.4 mini

- Most direct on the distinction between the present problem and the long-term
  platform question.
- Judged `herdr` to be the stronger long-term orchestration/control-plane shape
  because it already has worktrees, a socket API, agent semantics, and durable
  sessions.
- But still recommended **not** adopting it now because the current local
  `dmux` guard already addresses the specific observed bug, while `herdr`
  introduces a much larger platform commitment.
- Strongest recommendation:
  keep `dmux` near term, mine `herdr` for design ideas, and revisit only after
  the wrapper-first path hits real limits.

#### Claude Sonnet 4.6

- Most detailed on architectural shape.
- Treated `herdr` as genuinely closer to the future coordination/control-plane
  target than the current `dmux` wrapper is.
- Highlighted that the things currently being reconstructed manually around
  `dmux` — worktree lifecycle, state, control surface, durable session model —
  are first-class in `herdr`.
- But also stressed that `herdr` is very new, that the current `dmux` guard is
  not even merged yet, and that the next unknown failure mode should be learned
  from real use before switching substrates.
- Strongest borrow recommendations:
  conservative worktree removal semantics, semantic agent state, and eventual
  socket-shaped control-plane design.

#### GPT-4.1

- Most concise and conservative.
- Agreed that `herdr` is architecturally ahead for multi-agent terminal work.
- Still concluded that the team should focus on mastering and extending the
  current `dmux` path because it is already working against the concrete
  collision issue at hand.
- Framed `herdr` as a future-input source rather than a present migration
  target.

#### Copilot

- I agreed with the convergence:
  `herdr` looks more like a future **terminal-native control plane** than just a
  fancier multiplexer, and that makes it more structurally relevant than several
  earlier watch items.
- But I also agreed that the strongest current fact is still local:
  the first `dmux` safety slice is implemented, builds, and addresses the exact
  failure mode already observed.
- My strongest synthesis point was that the right comparison is not
  "`herdr` vs old `dmux` as-shipped upstream";
  it is "`herdr` vs the current wrapper-first local path that has already begun
  solving the concrete bug."
- Under that comparison, `herdr` becomes a strong **future-basis candidate**
  rather than a justified immediate switch.

### First-pass convergence

The voices converged on the following points.

1. **`herdr` is more structurally relevant than a pure UI novelty.**
   Its socket API, worktree lifecycle commands, semantic agent state, and
   durable session model make it meaningfully closer to a real terminal-native
   orchestration layer.

2. **`herdr` is a stronger long-term basis candidate than the current narrow
   `dmux` wrapper alone.**
   If the destination is a terminal-native control plane with worktree-aware
   orchestration, persistent sessions, and observable agent state, `herdr`
   already embodies much more of that shape.

3. **That does not mean it should replace the current path now.**
   The wrapper-first `dmux` line exists to solve an already-observed problem
   cheaply and safely.
   It is now doing that.
   Jumping to `herdr` immediately would trade a proven first slice for a newer,
   larger, less-proven runtime model.

4. **The local implementation frontier still favors continuing with `dmux`
   first.**
   The guard is implemented, documented, and validated.
   It should be landed and exercised before declaring that the underlying basis
   must change.

5. **`herdr` is best treated as a future control-plane reference and watch item.**
   It deserves more respect than a curiosity repo because it already includes
   precisely the classes of mechanism that later rounds have predicted would be
   needed:
   worktree lifecycle, control surface, state reporting, and durable sessions.

### Main disagreements or emphasis differences

There was no real disagreement on the recommendation.
The differences were about emphasis:

- **GPT-5.4 mini** was strongest on near-term practicality:
  do not switch while the current fix is working
- **Claude Sonnet 4.6** was strongest on long-term architecture:
  `herdr` is closer to the likely eventual substrate, but too new and too early
  for an immediate basis change
- **GPT-4.1** emphasized minimizing migration and retraining cost
- **Copilot** emphasized that the comparison must stay anchored to the already
  implemented local `dmux` guard rather than a hypothetical clean-slate tool
  choice

These were differences in weight, not in direction.

### What should be borrowed from `herdr`

Even without adopting it now, the round judged several `herdr` ideas to be
worth carrying forward:

1. **Explicit worktree lifecycle semantics**
   especially the conservative contract that removal of a linked workspace does
   not silently delete the branch

2. **Semantic agent state as a first-class observable**
   `working`, `blocked`, `done`, and similar status should eventually be visible
   to orchestration logic rather than inferred only from process existence

3. **Socket-shaped control plane thinking**
   if a future lease/heartbeat/ownership sidecar appears, a local socket surface
   is a better long-term shape than only environment variables or ad hoc lock
   files

4. **Durable session and handoff awareness**
   not necessarily to implement immediately, but to keep in mind when deciding
   how agents and worktrees are resumed, reattached, or cleaned up

5. **Richer preflight / inspection**
   today `dmux preflight` answers only whether launch is allowed
   later it could grow into "what workspace am I in, who owns it, what linked
   worktrees exist, and what state are they in"

### Strongest reasons not to switch immediately

The round judged the strongest anti-switch reasons to be:

1. **The current local `dmux` slice already solves the real observed bug.**
   That matters more than upstream feature count.

2. **`herdr` is still very new.**
   High star velocity is interesting, but not the same thing as operational
   maturity.

3. **Adopting `herdr` now would widen the surface area dramatically.**
   New daemon/session behavior, new integration model, new failure modes, new
   learning costs.

4. **The next real bottleneck has not yet been measured.**
   It is more disciplined to land and exercise the current guard, then let the
   next observed failure mode identify whether the missing piece is cleanup,
   claims, heartbeats, or something else.

5. **A switch now would outrun the current evidence.**
   The project has local evidence for one concrete failure mode and one concrete
   fix.
   It does not yet have enough evidence to justify migrating to a fuller
   terminal-control substrate.

### Decision

The maintained conclusion of this round is:

- **yes, `herdr` looks like a stronger long-term basis candidate than the narrow
  `dmux` wrapper alone**
- **no, it should not be added now**
- **the immediate focus should remain on using and hardening the current `dmux`
  path**
- **`herdr` should be treated as a serious future watch item and a source of
  concrete ideas to borrow**

Stated more plainly:

- keep learning good use of `dmux`
- land and exercise the shared-checkout guard
- let real use reveal the next missing control-plane primitive
- revisit `herdr` when there is either:
  - another concrete failure mode the wrapper cannot cover cleanly, or
  - enough maturity signal that adopting `herdr` would reduce total complexity
    rather than increase it

### What to do next

The practical next steps coming out of this round are:

1. **Finish the current `dmux` track**
   commit, publish, and exercise the shared-checkout guard

2. **Keep the next step narrow**
   if another failure mode appears, prefer a small addition such as richer
   preflight, ownership reporting, or cleanup semantics before jumping to a full
   new substrate

3. **Borrow one or two `herdr` contracts deliberately**
   the best candidates are:
   - worktree-remove semantics that never delete the branch by surprise
   - an eventual status model for agent/workspace state

4. **Revisit `herdr` later as a maturity check**
   especially if it stabilizes its socket/worktree APIs and continues to prove
   itself in real terminal-agent workflows

### Recommendation

Do **not** switch to `herdr` now.
Treat it as the strongest terminal-native control-plane watch item seen so far,
but keep the project on the current wrapper-first `dmux` path until real use of
the landed guard proves that a heavier substrate is actually needed.

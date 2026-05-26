## Round 131 — Should We Fork `dmux` for Btrfs-Backed Worktrees?

**Tags:** tooling, hygiene, worktrees, btrfs, dmux, t3code  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** `OpenCode` was requested as an enrichment seat, but it did not return usable output before the round was closed and is therefore not counted as a substantive voice.

### Round question

The maintainer wanted a practical local-tool decision, not a vague future-architecture
round.

The concrete question was:

- should the project fork `dmux` or another nearby agent/worktree tool
- so that every agent worktree is created inside its own Btrfs subvolume
- in order to reduce shared-checkout writes and recurring cleanup / replay debt
- with the expectation that a Nix package would replace the currently installed
  local `dmux`

The sharper decision questions were:

- is Btrfs-subvolume-per-worktree actually the right abstraction for the local
  failure mode
- if a fork is justified, what base is best: `dmux`, `maw`, something
  T3Code-adjacent, or something else
- whether Btrfs meaningfully improves safety over plain git worktrees
- whether `dmux` hooks are enough for a wrapper/prototype before owning a fork
- and whether T3Code / VSmux belong only in the UI/session layer

### Grounding used in this round

Relevant prior local context carried in:

- **Round 116** — recurring cleanup debt comes from bad writable defaults;
  shared checkout should become read-mostly / sync-only; disposable worktrees plus
  a preflight guard are the highest-leverage intervention.
- **Round 129** — better local harnesses do not structurally solve shared mutable
  checkouts; real isolation matters more than more prose.
- Existing local `agent-roundtable` intent already treats `dmux` as an operator
  console / TUI direction rather than the canonical orchestration or control plane.

Fresh external grounding carried in:

- **`standardagents/dmux`**
  - markets itself as “Parallel agents with tmux and worktrees”
  - says each pane gets its own git worktree and branch
  - advertises lifecycle hooks on worktree create / merge / cleanup
- **`boxabirds/maw`**
  - is a Rust CLI that runs any command inside an isolated git worktree
  - commits inside that worktree
  - and replays the result back into the main repo with Git merge machinery
- **`pingdotgg/t3code`**
  - presents itself as a minimal web GUI for coding agents
  - the fetched repo page did not claim built-in worktree or filesystem-isolation
    semantics
- **`maddada/VSmux`**
  - presents itself as an IDE/session manager for CLI agents and T3Code
  - again looking more like a session/UI layer than a mutation-isolation primitive
- **GitHub search evidence**
  - showed a small but growing family around “multi agent worktrees,” including
    `maw`, `conductor-trees`, and similar tools

Important scope boundary carried into the round:

- the question was **not** whether Btrfs is cool in the abstract
- it was whether owning a fork to create Btrfs subvolumes per worktree is the
  right next move for this maintainer’s current local collision problem

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** substantive
- **DeepSeek API:** substantive via direct HTTP API and local decrypted key
- **Copilot:** substantive
- **OpenCode free-model seat:** requested, but did not return usable output before
  the round was closed

This round therefore had a **full five-seat substantive roster** plus one failed
attempted enrichment seat.

### Voice summaries

#### Codex CLI

- Strongest on the claim that the real abstraction is still **isolated mutation
  with enforcement**, not Btrfs itself.
- Treated `dmux` as the best nearby base **if** the maintainer wants the operator
  console and the worktree helper in one place.
- Saw `maw` as a useful narrower reference implementation, but less aligned with
  the current desired console shape.
- Most explicit that Btrfs gains are real but secondary:
  snapshots, quotas, and cleanup are useful, but the highest-leverage move remains
  making the shared checkout read-mostly and guarded.
- Recommended **wrapper-before-fork**:
  prototype around upstream `dmux` hooks first, and only fork if the hooks prove
  insufficient in real use.

#### Gemini CLI

- Strongest on the argument that Btrfs subvolume-per-worktree is a **real
  enforcement improvement**, not just filesystem aesthetics.
- Most favorable to **forking `dmux` now**, because it argued the subvolume has to
  be created early enough in the worktree lifecycle that a post-hoc wrapper or
  generic hook may not be enough.
- Treated `dmux` as clearly the best base because it already owns the local pane /
  worktree lifecycle and is already installed in the maintainer’s workflow.
- Dismissed T3Code / VSmux as UI/session surfaces only.
- Maintained the most aggressive next step:
  fork `dmux`, add Btrfs-aware worktree creation directly, package it in Nix, and
  replace the local install.

#### Claude CLI

- Strongest on keeping the stack **layered**:
  `dmux` as operator console, `maw`-like tooling as isolation primitive,
  T3Code/VSmux as UI/session layers.
- Treated Btrfs as a **narrow but real** improvement:
  useful for snapshots, quotas, and easier deletion, but not the primary fix.
- Most skeptical of collapsing console UX and isolation semantics into one fork
  too early.
- Explicitly favored **not forking yet**, because the Round 116 preflight guard and
  write-path discipline still look more important than owning a downstream tool
  branch.
- Recommended:
  ship the guard first, test `dmux` hooks with optional Btrfs-backed workspaces,
  and only fork if the hook interface proves too weak.

#### DeepSeek API

- Strongest on the framing that Btrfs can turn a worktree from a plain directory
  into a more explicit **managed state object** with snapshots and rollback.
- More sympathetic to a **hard fork** than Codex or Claude, especially in a Nix
  workflow where built-in behavior is easier to verify than shell-hook glue.
- Still agreed that T3Code / VSmux are not where isolation should be solved.
- Saw `dmux` as the most natural base because it already owns the session/worktree
  lifecycle the maintainer is using.
- Recommended a built-in Btrfs-backed `dmux` mode with snapshot/rollback support.

#### Copilot

- I agreed with the prior local rounds that the root bug is still **bad writable
  defaults**, not absence of a more sophisticated filesystem wrapper.
- I also agreed that Btrfs subvolumes are not fake value:
  they can materially improve cleanup, snapshot/rollback, and optional quota
  policy.
- My strongest synthesis point was that these benefits are **secondary unless the
  mutation path is already isolated by default**.
- I therefore favored a **Nix-packaged wrapper around upstream `dmux` first**,
  with Btrfs as an optional backing for worktree creation, and a fork only if
  real use proves that the hook/wrapper seam is insufficient.

### First-pass convergence

The substantive voices converged on the following points.

1. **T3Code / VSmux should be treated as UI/session layers, not as the place to
   solve mutation isolation.**
   There was no meaningful support for making them the filesystem or worktree
   authority.

2. **`dmux` is the closest current fit if the maintainer wants to improve the
   existing local operator-console workflow.**
   Even the voices more interested in `maw` treated it as a useful narrow
   isolation primitive or reference, not the obvious replacement for the current
   console habit.

3. **Btrfs subvolume-per-worktree has real operational value, but it is not the
   main conceptual fix.**
   The main fix remains:
   - shared checkout as read-mostly / sync-only
   - disposable mutation workspaces by default
   - and a preflight guard that makes unsafe writes abnormal

4. **Btrfs benefits are real but mostly second-order.**
   The panel repeatedly pointed to:
   - cheap snapshots / rollback
   - quotas
   - cleaner deletion / garbage cleanup
   as the real gains over plain worktrees.

5. **`maw` is interesting as a reference point, but not the most natural main
   path for this maintainer right now.**
   The roster generally treated it as a useful isolation/replay primitive, not the
   current best operator console.

### Real disagreements that remained

There was one meaningful strategic disagreement:

- **Gemini** and **DeepSeek** were more willing to fork `dmux` soon, arguing that
  built-in Btrfs-aware worktree creation may need earlier control than a generic
  wrapper or hook can safely provide.
- **Codex**, **Claude**, and **Copilot** preferred **wrapper-before-fork**, arguing
  that the project should prove the gain first and avoid owning a downstream Nix
  fork until upstream hooks or launcher seams are shown to be insufficient.

There was also a softer architectural difference:

- **Claude** was most interested in keeping isolation as a separate primitive and
  not overloading the `dmux` console layer with too much filesystem policy
- while **Gemini** and **DeepSeek** were more comfortable making `dmux` itself the
  Btrfs-aware enforcement point

So the disagreement was not over whether Btrfs has value.
It was over whether that value is large and early enough to justify ownership of a
fork now.

### Final synthesis

The strongest maintained answer from this round is:

- **do not treat Btrfs subvolumes as the primary fix** for shared-checkout damage
- treat them as a meaningful local upgrade on top of the more important Round 116
  discipline:
  - read-mostly shared checkout
  - worktree-by-default mutation
  - explicit preflight guardrails
- if the maintainer wants to improve the current console workflow, `dmux` is the
  nearest sensible place to integrate that improvement
- but the project should avoid owning a fork until it has real evidence that a
  wrapper / hook-based prototype is insufficient

The panel rejected two bad extremes:

- **bad extreme A:** “plain worktrees plus more reminders are enough forever”
- **bad extreme B:** “Btrfs subvolumes solve the problem by themselves, so fork now
  and call it done”

The maintained line is:

- first make isolated mutation the actual default
- then add optional Btrfs-backed worktrees to make cleanup, rollback, and quotas
  better
- start that as cheaply as possible around upstream `dmux`
- and only fork if the evidence shows the lifecycle seam is too weak for the job

### Recommended next-month sequence

1. **Ship the Round 116 preflight guard if it is not already load-bearing.**
   Shared checkout must become visibly read-mostly / sync-only before Btrfs is
   treated as decisive.

2. **Prototype a Nix-packaged wrapper around upstream `dmux`.**
   That wrapper should:
   - create disposable worktrees by default
   - optionally create one Btrfs subvolume per worktree when the filesystem
     supports it
   - and clean up / archive those workspaces explicitly on merge/close

3. **Use real sessions for a short evidence window.**
   Run actual local agent work through the wrapper for a few weeks and watch:
   - whether cleanup debt drops
   - whether rollback/snapshot value is used in practice
   - and whether `dmux` hooks/lifecycle are sufficient or awkward

4. **Read `maw` as a reference implementation, not as the default switch yet.**
   Its replay model is useful evidence, but the current local console gravity is
   still around `dmux`.

5. **Fork `dmux` only if the prototype proves the seam is too weak.**
   That is the point where the Nix packaging burden becomes justified by actual
   operator value rather than architectural enthusiasm.

### Satisfaction marker

[satisfied]

This round is satisfied if the maintainer’s next local experiment is:

- not “own a fork because Btrfs sounds cleaner”
- but “prove whether Btrfs-backed worktrees materially reduce cleanup debt when
  combined with guarded worktree-by-default mutation”

Verdict: Start with a Nix-packaged wrapper around upstream `dmux` that enforces worktree-by-default mutation and optionally backs each worktree with its own Btrfs subvolume; fork `dmux` only if real use shows the hook/wrapper seam is insufficient.

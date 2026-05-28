## Round 135 — Greenfield Worktree+Btrfs Tool vs the `dmux` Efficient Frontier

**Tags:** tooling, worktrees, btrfs, dmux, leases, cleanup, pragmatism  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis

### Round question

The maintainer wanted a sharper strategic round on the **resource-constrained**
tradeoff around local workspace tooling.

This was not just another round on:

- whether Btrfs is useful
- whether to fork `dmux` now
- or whether VFS should replace the current path

The actual question was:

- how much more could realistically be achieved by treating worktree +
  Btrfs-subvolume integration as a greenfield tool/product
- versus continuing to build on upstream `dmux`
- while taking seriously the actual environment:
  one maintainer, modest engineering time, and modest inference subscriptions from
  only a few providers

The real concern was whether the project is leaving major value on the table by
remaining wrapper-first, or whether that is already close to the best frontier
available under current means.

### Grounding used in this round

Relevant prior local context carried in:

- **Round 116** — the recurring local bug is bad writable defaults; shared
  checkout should become read-mostly / sync-only and preflight guardrails matter
  more than more reminders
- **Round 129** — shared-checkout collisions are fundamentally a
  workspace-isolation problem, not a local harness/frontend problem
- **Round 131** — Btrfs subvolumes are a secondary upgrade; the primary fix is
  default isolated mutation workspaces, starting with a wrapper around upstream
  `dmux`
- **Round 134** — VFS / virtual-working-copy ideas are mostly orthogonal to the
  current failure mode; keep focus on isolation and coordination rather than
  materialization tech

Current local posture carried into the round:

- likely only modest engineering time
- modest model/inference subscriptions from a few providers, not a heavily funded
  tooling team
- desire for something that materially reduces cleanup debt and collisions soon,
  not only a cleaner long-term architecture

Important scope boundary carried into the round:

- the question was **not** “what would the ideal workspace product look like with
  a real team and runway?”
- it was “what is the best frontier under the resources actually available now?”

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** substantive
- **DeepSeek API:** substantive via direct HTTP API and local decrypted key
- **Copilot:** substantive

This round therefore had a **full five-seat substantive roster**.

### Voice summaries

#### Codex CLI

- Strongest on separating:
  - what greenfield could improve **in principle**
  - from what is the best frontier **under current means**
- Treated the real greenfield gains as:
  - stronger invariants
  - a cleaner state model
  - more explicit lifecycle / cleanup / rollback semantics
- But argued the project is not currently losing because it lacks a bespoke
  workspace product.
- Most explicit that the main loss is that the wrapper path has not yet become
  strict enough to carry the discipline the design already knows it needs.
- Recommended wrapper-first with a **small sidecar only where hooks are too weak**.

#### Gemini CLI

- Strongest on the phrase that a **wrapper + sidecar hybrid** is the real
  efficient frontier.
- Treated a full greenfield tool as likely to become a maintenance-heavy
  duplicate of surrounding tooling rather than the shortest path to relief.
- Most favorable to a focused sidecar that handles:
  - Btrfs snapshot/subvolume management
  - rollback-oriented helpers
  - and narrow lifecycle assistance beneath a `dmux` wrapper
- Rejected a full replacement while still insisting the wrapper should become
  genuinely load-bearing.

#### Claude CLI

- Strongest on the claim that the project has already asked the right
  architecture question for several rounds and keeps getting the same answer.
- Most direct that the next month should be **building, not deliberating**.
- Treated the current bottleneck as underexploitation of the wrapper path, not a
  wrong substrate choice.
- Recommended:
  - ship the wrapper this week
  - run real work through it
  - and only escalate to a sidecar or deeper change if measured evidence shows
    the `dmux` seam cannot carry the model

#### DeepSeek API

- Strongest on the distinction between:
  - what `dmux` can already carry with wrapper logic
  - and the one thing that may deserve a narrow extra layer:
    simple lease / lock state
- Most explicit that rich greenfield ambition now would be a
  resource-constrained vanity project.
- Favored a hybrid sequence:
  wrapper now, small lease sidecar next if needed, and greenfield only after
  sustained evidence of structural insufficiency.
- Also pushed the most concrete near-term operator surface:
  Btrfs snapshot on create, cleanup commands, and a simple stale-breakable lease
  path.

#### Copilot

- I agreed with the panel that greenfield could produce a cleaner lifecycle model
  in principle, but not quickly enough to beat a wrapper-first path under current
  means.
- My strongest synthesis point was that the most interesting escalation is not a
  full replacement but a **tiny workspace-lifecycle / lease sidecar** that owns
  only the part `dmux` may be weak at, while leaving pane/session management
  intact.
- I also agreed that the project should stop treating this as an unresolved
  substrate debate and instead force the wrapper path through real usage.

### First-pass convergence

The substantive voices converged on the following points.

1. **A greenfield tool could be cleaner in principle.**
   The real possible gains named across the roster were:
   - stronger invariants
   - first-class lifecycle state
   - better cleanup / rollback modeling
   - and cleaner lease/ownership semantics

2. **Those gains are not large enough, under current means, to justify a full
   replacement project now.**
   The roster repeatedly treated the current resource constraint as decisive:
   one maintainer and modest model budgets do not support a long greenfield
   detour well.

3. **The current bottleneck is underexploiting the wrapper path.**
   Across the voices, the main line was that the design already knows the needed
   discipline:
   isolated mutation by default, read-mostly shared checkout, preflight guard,
   cleanup, and optional Btrfs backing.
   What is missing is making that path load-bearing in real daily use.

4. **A small sidecar is the interesting hybrid escalation.**
   The round consistently separated:
   - full greenfield replacement: too much
   - wrapper only forever: maybe enough, but unproven
   - tiny lifecycle / lease / snapshot helper beside `dmux`: plausible if hooks
     prove too weak

5. **The next month should be implementation and measurement, not more substrate
   debate.**
   Every substantive voice pushed some version of:
   build the wrapper, use it for real work, and collect evidence before deciding
   whether a sidecar or fork is justified.

### Real disagreements that remained

The main disagreement was about how much of the “sidecar” should be treated as
part of the near-term plan.

- **Gemini**, **DeepSeek**, and **Copilot** were more open to naming a tiny sidecar
  early as the likely efficient compromise
- **Codex** and especially **Claude** were more disciplined about not promoting
  that layer too quickly before the wrapper has actually failed in practice

There was also a softer difference in emphasis:

- **Codex** spent more energy on the “ideal in principle vs best frontier under
  means” distinction
- **Claude** spent the most energy on the repeated local pattern of asking the
  right question but not yet shipping the answer
- **DeepSeek** was the most concrete about simple lease/lock mechanics

These were disagreements about timing and framing, not about the main direction.

### Final synthesis

The strongest maintained answer from this round is:

- yes, a greenfield workspace+Btrfs tool could be cleaner in principle
- but under current means the project is not mainly blocked by the absence of
  that tool
- it is blocked by not yet making the wrapper path load-bearing enough
- so the best current frontier is still:
  - wrapper-first on upstream `dmux`
  - optional Btrfs-backed workspace creation
  - explicit cleanup / rollback helpers
  - preflight / claim / lease discipline
- and only then, if real use shows the `dmux` seam is too weak, promote a tiny
  sidecar or deeper ownership of the lifecycle layer

The panel rejected two bad extremes:

- **bad extreme A:** “a full greenfield replacement is the bold move, therefore it
  must be the right move”
- **bad extreme B:** “the wrapper path can never need any extra narrow authority
  beneath it”

The maintained line is:

- do not start a full greenfield replacement project now
- stop treating the wrapper path as provisional theory and make it the real
  mutating default
- if needed, add only the narrowest possible lifecycle / lease / snapshot sidecar
  beside `dmux`
- and let measured evidence, not architectural restlessness, decide whether the
  sidecar grows

### Recommended next-month sequence

1. **Ship the wrapper now and make it mandatory for mutating work.**
   Shared-checkout writes should become visibly abnormal, not the default easy
   path.

2. **Default to isolated workspaces and add optional Btrfs backing where
   available.**
   The wrapper should create isolated worktrees, support Btrfs-backed creation,
   and expose cleanup/prune behavior explicitly.

3. **Add only the smallest extra state layer that is actually needed.**
   A simple state file or narrow lease helper is acceptable if it materially
   improves coordination and stale-workspace handling.

4. **Use it for real work and measure the pain.**
   Track collisions, dirty-checkout recoveries, cleanup debt, rollback usage,
   workspace creation latency, and disk growth.

5. **Escalate only if evidence shows a hard seam.**
   If the `dmux` hook/lifecycle seam repeatedly blocks cleanup, rollback, or lease
   enforcement, then design the minimal sidecar more explicitly and only later
   revisit fork/greenfield questions.

### Verdict

Stay wrapper-first on upstream `dmux`; under current means the project is underexploiting that path more than it is constrained by the substrate, and the only plausible greenfield escalation is a tiny lifecycle/lease sidecar if real wrapper use proves the `dmux` seam has hard limits.

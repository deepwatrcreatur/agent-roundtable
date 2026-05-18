# Round 88 — Agent Resource Contention, Live Hosts, and Single-Writer Boundaries

**Status:** Closed  
**Tags:** tooling, structural, safety, protocol  
**Voices used:** Copilot synthesis, local repo grounding, operator incident report  
**Additional note:** this round was triggered by a real collision pattern where
two agents tried to manage the same VM while also doing testing and doc work

### Round question

The maintainer wanted a round on how to avoid contention between agents working
on the same resource, especially after observing two agents trying to manage the
same VM while testing code.

The maintainer also wanted a review of a proposed wording change:

- the `vaglio` lock should apply only to live deploy actions, not branch work in
  general
- parallel branch work should remain encouraged
- unrelated efforts, including work like DBus changes, may proceed concurrently
- only rebuilds, restarts, cache-warming, and similar mutating actions on the
  same live host should require single-writer discipline

### Relevant prior context

This round built directly on:

- **Round 57** — the agent task queue should structure ownership rather than rely
  on informal chat coordination
- **Round 70** — the board / local-daemon model should make leases and runtime
  claims explicit
- **Round 75** — workflow definitions should express execution constraints and
  runtime requirements as data
- **Round 85** — `jj` enables safe parallel branch work when change lineage is
  explicit
- recent live-host work around `vaglio`, where branch work and deploy work were
  interleaving

### Local grounding

The current docs already imply parts of the answer:

- work items are claimable and should not be started if another agent already has
  them `in-progress`
- the board model already has lease-based work claims
- the local daemon contract already distinguishes runtime identity, capability
  labels, and lease renewal

But the repo did **not** yet centralize a clear distinction between:

- safe concurrent branch work
- safe read-only inspection
- unsafe concurrent mutation of the same live resource

### First-pass convergence

The round converged on the following points.

1. **The proposed wording is directionally correct.**
   A host-wide "lock" that blocks all branch work is too blunt. It would destroy
   one of the main benefits of `jj` and over-serialize work that is not actually
   colliding.

2. **Single-writer discipline should be resource-scoped, not repo-scoped.**
   The real danger is not that two agents edit related code in parallel. The real
   danger is that two agents mutate the same live thing at the same time:
   - a running VM
   - a live host
   - a shared deploy target
   - a database migration target
   - a cache or warmup path whose effects are global

3. **Parallel branch work should remain the default.**
   If agents are working on separate branches, separate changes, or read-only
   investigation, concurrency is generally desirable and should stay encouraged.

4. **Live mutation needs explicit exclusivity.**
   Actions like rebuild, restart, deploy, migration, failover exercise,
   cache-warming, or service reconfiguration on the same live target should
   require a single current owner with a bounded lease.

5. **Resource contention belongs in runtime semantics, not just in prose docs.**
   Queue wording is helpful, but not sufficient. The board/daemon layer should
   eventually model resource claims directly so the system can block or defer
   unsafe work automatically.

6. **The important taxonomy is action class plus resource class.**
   A branch is not inherently exclusive. A host is not inherently exclusive
   either. What matters is the combination:
   - read-only action on a host: often concurrent-safe
   - branch-local code change: concurrent-safe
   - restart on the same host: exclusive
   - DB migration against shared state: exclusive
   - dry-run evaluation in isolation: often concurrent-safe

### Resource classes the round wants made explicit

The round recommended at least the following classes:

1. **Branch-local workspace**
   - examples: `jj` branch work, local patching, isolated testing
   - default: concurrent-safe

2. **Read-only shared resource**
   - examples: log inspection, status checks, config reads
   - default: concurrent-safe unless rate-limited or otherwise fragile

3. **Append-only shared state**
   - examples: event logs, attempt lineage, append-only board records
   - default: concurrent-safe if the underlying model is append-only and does not
     require destructive mutation

4. **Mutable live service host / VM**
   - examples: `nixos-rebuild switch`, restart, runtime override changes
   - default: exclusive for mutating actions

5. **Shared service data plane**
   - examples: migrations, schema changes, cache invalidation, warmup jobs
   - default: exclusive or tightly serialized

6. **Risky control-plane operation**
   - examples: failover drills, network identity promotion, VM power actions
   - default: explicit operator-visible ownership plus stronger gatekeeping

### Review of the proposed `vaglio` lock wording

The round approved the spirit of the proposal with one refinement:

> The `vaglio` lock should be described not as a general host lock, but as a
> **live-resource mutation lock**.

That means:

- yes: parallel branch work should continue
- yes: unrelated code efforts can proceed concurrently
- yes: read-only inspection of the same host may still be allowed
- but: only one agent at a time should perform live mutating actions against the
  same target resource

This is more precise than "lock the host" and easier to implement in the future
board/daemon model.

### Where this policy belongs

The round concluded it belongs in three layers:

1. **Queue docs / work-item docs**
   so human operators and agents see the rule immediately

2. **Board execution model**
   so future work items can express resource-affinity or exclusive-resource
   requirements as data

3. **Local daemon / runtime contract**
   so runners can respect exclusive claims on live targets rather than blindly
   executing whatever matches the repo/branch alone

### Concrete recommendation now

1. Update queue/work-item docs to say:
   - branch work is concurrent by default
   - read-only work is concurrent by default
   - exclusive ownership applies only to mutating actions on the same live
     resource
2. Introduce a resource-class table with examples of concurrent-safe versus
   exclusive actions.
3. Add a follow-up implementation item for resource-level leases or resource
   affinity constraints in the board/daemon model.
4. Avoid vague language like "host lock" when the actual concern is a narrower
   live mutation boundary.

### One-sentence verdict

The project should preserve parallel branch work and read-only concurrency, while
enforcing single-writer discipline only for mutating actions against the same
live resource — and it should move that rule from ad hoc wording into explicit
queue, board, and daemon semantics.

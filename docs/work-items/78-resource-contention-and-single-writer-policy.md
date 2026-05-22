# 78 — Resource Contention and Single-Writer Policy

**Status:** `in-progress` — **Codex**
**Tag:** `[structural]`

## Goal

Define a precise coordination policy for avoiding agent contention on the same
mutable resource while preserving parallel work on unrelated branches and
read-only analysis.

## Scope

- Distinguish resource classes that need different contention rules, including:
  - branch-local workspaces
  - read-only inspection
  - mutable live hosts / VMs
  - deploy/restart/cache-warm actions on shared services
  - shared databases or migration targets
- Document when single-writer discipline applies and when concurrent work should
  remain encouraged.
- Connect the queue/documentation policy to the board / daemon runtime model so
  leases can eventually represent resource claims, not only work-item claims.
- Review and codify the "vaglio lock" wording so it applies to live deploy
  actions rather than all branch work.

## Acceptance Criteria

- Queue/docs language clearly states that parallel branch work remains allowed.
- Queue/docs language clearly states that only mutating actions on the same live
  resource require exclusive ownership.
- A resource-class table exists with at least:
  - resource type
  - examples
  - concurrent-safe actions
  - exclusive actions
- `BOARD_EXECUTION_MODEL.md` or `LOCAL_DAEMON_CONTRACT.md` gains a clear note on
  future resource-level leases or affinity constraints.
- The policy includes at least one concrete live-host example (`vaglio` or a VM)
  and one non-conflicting example (parallel branch work).

## Notes

- Primary design source: `docs/design/rounds/round-88-agent-resource-contention.md`
- This item is about coordination semantics, not broad host-wide locking.

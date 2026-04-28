# 14 — Coordinator Failover

**Status:** `blocked` (needs items 11, 12, 13)
**Owner:** unassigned
**Branch:** `feat/coordinator-failover`

## Goal

Make coordinator/IC failure a first-class orchestrator concern. If the active
coordinator stalls because of provider overload, timeout, or process failure,
the system should enter a degraded state, preserve continuity, and either
resume via standby takeover or surface a structured human-review path.

## Why

Q20 handoff exposed a real failure mode:
- prompt was already drafted
- primary coordinator became unavailable due to provider overload
- continuity depended on a human noticing and asking another agent to step in

That is not robust enough for an autonomous system.

## Scope

Implement the coordinator-failover layer on top of `Roundtable.RoundRun`,
phase-state-machine work, and OTEL spans.

### Required data model additions

Extend `Roundtable.RoundRun` with:

```elixir
coordinator: atom() | nil
coordinator_lease_expires_at: DateTime.t() | nil
last_progress_at: DateTime.t() | nil
suspended_phase: atom() | nil
takeover_count: non_neg_integer()
```

### Required phase-machine additions

Add:

```elixir
:coordinator_unavailable
```

Transitions:

- active coordinator misses lease or exceeds retry budget
  → `:coordinator_unavailable`
- standby coordinator successfully claims lease
  → resume `suspended_phase`
- human operator acknowledges degraded state without takeover
  → `:needs_human_input`
- repeated failed takeovers
  → `:needs_human_review`

### Lease / heartbeat policy

- coordinator claims a lease when beginning synthesis/round coordination
- heartbeat updated on:
  - prompt posted
  - agent response recorded
  - synthesis started
  - synthesis posted
- lease expiry is configurable
- lease claim must be compare-and-set safe against concurrent takeover attempts

### Side effects / UI

- automatic continuity note when takeover occurs
- LiveView banner showing degraded state and current coordinator
- telemetry spans/events:
  - `roundtable.coordinator.lease.claim`
  - `roundtable.coordinator.heartbeat`
  - `roundtable.coordinator.timeout`
  - `roundtable.coordinator.takeover`

## Acceptance Criteria

- round can be resumed after simulated coordinator timeout without rereading the
  full discussion manually
- degraded-state transition is persisted in `RoundRun`
- continuity note is written automatically on takeover
- standby takeover and human-review fallback both have test coverage
- dashboard exposes coordinator identity and degraded-state banner

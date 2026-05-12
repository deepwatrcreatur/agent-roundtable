# 74 — Local Daemon Lease, Heartbeat, and Event Contract

**Status:** `done` — **GitHub Copilot**
**Tag:** `[tools]`

## Goal
Implement the runner-side contract described in
`docs/design/LOCAL_DAEMON_CONTRACT.md` so local CLI environments can execute
board work durably.

## Scope
- Add runtime registration and heartbeat handling.
- Implement lease-based work claiming and lease renewal.
- Support structured attempt events:
  - start
  - progress
  - warning
  - needs-human-gate
  - completed
  - failed
- Classify failures into retry-usable categories rather than only freeform text.
- Preserve the local-subscription model: the daemon launches the real local CLI
  and the board observes results.

## Acceptance Criteria
- A local daemon can register itself and advertise runtime / agent capabilities.
- Claimed work expires safely if the daemon stops renewing its lease.
- A running attempt can emit progress and terminal events without requiring
  server-side CLI execution.
- A daemon can request a structured human gate instead of silently stalling.
- Failure classes are machine-usable by retry policy.

## Outcome
- Added `Roundtable.LocalDaemon`, a runner-side contract module on top of
  `Roundtable.Board` that implements:
  - runtime registration
  - heartbeats
  - polling and claiming work
  - attempt start / completion / failure / release
  - lease renewal
  - stale-lease expiry handling
  - human-gate requests
  - machine-usable failure classification
- Extended `Roundtable.Board` with:
  - `get_work_item/3`
  - `get_attempt/3`
  - append-only `work_attempt_events`
  - `append_attempt_event/3`
  - `list_attempt_events/3`
- Added Dolt migration
  `roundtable/priv/dolt/migrations/20260512_add_board_attempt_event_log.sql`
  for the event log table.
- Added focused tests covering the daemon contract and the append-only event log.

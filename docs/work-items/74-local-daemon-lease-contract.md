# 74 — Local Daemon Lease, Heartbeat, and Event Contract

**Status:** `ready`
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

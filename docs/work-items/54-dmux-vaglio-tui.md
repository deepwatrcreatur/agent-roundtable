# 54 — Vaglio TUI (dmux Integration)

**Status:** `blocked`
**Tag:** `[tools]`

## Goal
Integrate Vaglio round management into a terminal user interface for maintainer velocity.

## Scope
- Extend `dmux` to support a "Vaglio Round" pane.
- Implement UI for prompt injection and summary reading.
- Connect `dmux` to the direct Roundtable control socket and live event stream (items 66-67).
- Display round status (Robustness/Stress) directly in the tmux status line.

## Acceptance Criteria
- Maintainer can start a "Vaglio Round" on their workstation with a single keystroke.
- High-fidelity feedback loop using the real local agent harnesses through Roundtable.

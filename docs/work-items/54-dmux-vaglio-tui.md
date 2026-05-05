# 54 — Vaglio TUI (dmux Integration)

**Status:** `ready`
**Tag:** `[tools]`

## Goal
Integrate Vaglio round management into a terminal user interface for maintainer velocity.

## Scope
- Extend `dmux` to support a "Vaglio Round" pane.
- Implement UI for prompt injection and summary reading.
- Connect `dmux` to the local OpenCode Vaglio Proxy (Item 53).
- Display round status (Robustness/Stress) directly in the tmux status line.

## Acceptance Criteria
- Maintainer can start a "Vaglio Round" on their workstation with a single keystroke.
- High-fidelity feedback loop using local agent harnesses.

# 54 — Vaglio TUI (dmux Integration)

**Status:** `done` — **Owner:** `Codex`
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

## Notes

- Primary design sources:
  - `docs/design/LOCAL_HARNESS_RPC_CONTRACT.md`
  - `docs/design/LOCAL_DAEMON_CONTRACT.md`
  - `docs/design/rounds/round-83-opentui-cli-surface.md`
  - `docs/design/rounds/round-135-greenfield-worktree-btrfs-vs-dmux-efficient-frontier.md`
- Closely related work:
  - `53-opencode-fork-rpc.md`
  - `57-agent-task-queue.md`
  - `97-browseable-board-surface.md`
  - `99-btrfs-workspace-backend-and-dmux-wiring.md`

## Outcome

- Added
  [docs/design/DMUX_VAGLIO_TUI_CONTRACT.md](../design/DMUX_VAGLIO_TUI_CONTRACT.md)
  as the maintained local TUI contract note.
- Closed the old "extend `dmux`" framing in favor of a wrapper-first operator
  surface over existing board and daemon contracts.
- Kept the useful part of the original idea:
  - one-keystroke local round/work launch
  - pane-based local operator visibility
  - compact status-line projection
- Kept the TUI explicitly optional and non-canonical so it does not become a
  second orchestration truth layer.

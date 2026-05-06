# 68 — dmux Direct Round Supervisor

**Status:** `ready`
**Tag:** `[tools]`

## Goal
Build the first maintainer TUI against Roundtable's direct local control surface, using dmux as the shell.

## Scope
- Add a dmux-driven "Vaglio Round" supervisor pane that connects to items 66 and 67.
- Show active round status, per-agent output, satisfaction markers, and failure states.
- Support human-in-the-loop actions such as retry, prompt override, and close/cancel from the TUI.
- Avoid any dependency on an OpenCode proxy for the real discussion path.

## Acceptance Criteria
- A maintainer can start and monitor a real round from dmux with one command or keybinding.
- The TUI shows live output from the actual Roundtable agent harnesses.
- Human intervention actions go back through the Roundtable control socket rather than shelling out ad hoc.

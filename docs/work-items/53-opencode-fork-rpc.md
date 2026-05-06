# 53 — Optional OpenCode UX Proxy

**Status:** `blocked`
**Tag:** `[structural]`

## Goal
Optionally fork or wrap `opencode` later as a UX accelerator, without making it the core discussion transport.

## Scope
- Evaluate OpenCode only as an optional client/server shell around the direct Roundtable path.
- Do not let OpenCode replace `Roundtable.Actions.RunCliAgent` for real turns.
- Revisit only after items 66-68 prove the direct local TUI path.

## Acceptance Criteria
- Any OpenCode integration is strictly optional and layered above Roundtable.
- Removing OpenCode must not break the real discussion path.

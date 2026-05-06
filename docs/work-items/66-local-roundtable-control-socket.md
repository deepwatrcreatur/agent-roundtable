# 66 — Local Roundtable Control Socket

**Status:** `ready`
**Tag:** `[structural]`

## Goal
Expose a local control socket for the TUI that talks to the real Roundtable orchestrator rather than replacing it.

## Scope
- Add a local Unix socket or equivalent local RPC surface inside Roundtable.
- Support commands to start a round, inspect active rounds, fetch transcripts, and inject maintainer actions such as retry/pause/cancel.
- Route all agent execution through the existing orchestrator and `Roundtable.Actions.RunCliAgent`.
- Do not introduce OpenCode as a required transport layer for real discussion turns.

## Acceptance Criteria
- A local client can start and supervise a real round without calling GitHub or model SDKs directly.
- The control API can address `claude`, `codex`, `gemini`, and `deepseek` only through Roundtable-owned execution paths.
- The socket boundary is documented well enough for a TUI client to consume it.

# 53 — OpenCode Vaglio Proxy (Local RPC)

**Status:** `ready`
**Tag:** `[structural]`

## Goal
Fork `opencode` to create a local background service that provides a uniform API for local agent harnesses.

## Scope
- Adapt OpenCode's client-server architecture to handle Vaglio protocol turns.
- Implement handlers for `claude`, `gemini`, and `codex` CLI binaries.
- Ensure the server maintains the `jj` and `Dolt` state for the local workstation.
- Expose a Unix socket for TUI interaction.

## Acceptance Criteria
- TUI can trigger a "Gemini Turn" by calling the local RPC.
- The RPC correctly captures and streams the output from the CLI binaries.

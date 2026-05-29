# 53 — OpenCode Vaglio Proxy (Local RPC)

**Status:** `done` — **Owner:** `Codex`
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

## Notes

- Primary design sources:
  - `docs/design/LOCAL_DAEMON_CONTRACT.md`
  - `docs/design/LOCAL_SUBSCRIPTION_HARNESS_CONTRACT.md`
  - `docs/design/CONTROLLED_EXECUTOR_CONTRACT.md`
- Closely related work:
  - `03-cli-agent-action.md`
  - `54-dmux-vaglio-tui.md`
  - `55-local-subscription-harness.md`
  - `95-buildkite-compatible-controlled-executor.md`

## Outcome

- Added
  [docs/design/LOCAL_HARNESS_RPC_CONTRACT.md](../design/LOCAL_HARNESS_RPC_CONTRACT.md)
  as the maintained local RPC boundary note.
- Closed the old "fork OpenCode" framing in favor of a harness-neutral local
  RPC layer.
- Kept the useful part of the original idea:
  - Unix-socket-first local transport
  - streaming output to local clients
  - uniform invocation surface for local harnesses
- Made OpenCode an optional backend bridge behind that contract rather than the
  canonical architecture center.

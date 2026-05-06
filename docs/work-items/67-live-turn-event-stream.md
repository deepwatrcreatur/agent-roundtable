# 67 — Live Turn Event Stream

**Status:** `ready`
**Tag:** `[tools]`

## Goal
Provide a stream of live turn output and orchestration events for local supervision UIs.

## Scope
- Emit agent-turn lifecycle events, stdout chunks, satisfaction markers, and orchestrator phase transitions from real runs.
- Expose the stream over the local control surface introduced in item 66.
- Normalize failure events such as rate limits, missing credentials, quota exhaustion, and command exits.
- Keep the stream append-only and observational; it must not become the orchestration source of truth.

## Acceptance Criteria
- A local client can render live agent output without polling GitHub Issues.
- `deepseek`, `claude`, `codex`, and `gemini` failures are surfaced as structured events.
- The event schema is stable enough to support a dmux/TUI client and later WebUI reuse.

# Local Harness RPC Contract

**Status:** Maintained

## Purpose

Define the narrow local RPC boundary between:

- maintainer-facing local clients such as a future TUI
- the runtime-local daemon that owns harness execution
- local subscription-backed or routed harnesses such as `codex`, `gemini`,
  `claude`, `copilot`, or `opencode`

This note closes the old "fork OpenCode" framing by defining the actual
architectural requirement: a harness-neutral local RPC layer with streaming,
lease-aware execution semantics.

## Maintained line

The system should not make an OpenCode fork the center of local orchestration.

It should expose a small local RPC contract that:

- is transport-light
- is harness-neutral
- can wrap vendor CLIs directly
- can also bridge to `opencode serve` or a future similar local multiplexer
- preserves board, claim, and lease semantics above the RPC layer

In short: local RPC is the required boundary; OpenCode compatibility is an
optional backend path beneath it.

## Boundary

### What this layer owns

- local request admission
- runtime-local harness selection
- bounded prompt / input dispatch
- incremental output streaming
- cancellation and timeout handling
- structured execution metadata return

### What this layer does not own

- claim or lease authority
- durable board truth
- promotion or publish decisions
- hidden provider substitution for distinct voices
- the only canonical storage of logs or evidence

This keeps the RPC layer operational rather than turning it into a shadow
control plane.

## Why this exists

The nearby contracts already define:

- local daemon registration and lease/event semantics
- local harness health and fallback rules
- executor boundaries for non-local workers

What they do not yet define is the thin invocation boundary a local UI or
operator tool should talk to.

That is the gap this note fills.

## Core objects

### `RpcSession`

Represents one bounded local execution interaction.

Minimum fields:

| Field | Meaning |
|---|---|
| `session_id` | Runtime-local session ID |
| `runtime_ref` | Runtime / daemon handling the request |
| `attempt_ref` | Optional canonical attempt ID if board-backed |
| `claim_ref` | Optional logical work claim |
| `requested_profile_id` | Requested local harness profile |
| `effective_profile_id` | Actual profile used after policy checks |
| `stream_mode` | `buffered`, `line_stream`, or `event_stream` |
| `created_at` | Start time |

### `HarnessInvocationRequest`

Minimum fields:

| Field | Meaning |
|---|---|
| `requested_profile_id` | Harness profile the client wants |
| `prompt_payload` | Prompt or structured input bundle |
| `workspace_ref` | Optional repo/workspace target |
| `timeout_ms` | Execution timeout |
| `voice_policy` | `distinct_required`, `fallback_allowed`, or similar |
| `stream_mode` | Buffered vs streaming preference |
| `metadata` | Extra task metadata |

### `HarnessInvocationResult`

Minimum fields:

| Field | Meaning |
|---|---|
| `session_id` | Parent session |
| `state` | `completed`, `failed`, `cancelled`, `timed_out` |
| `output_text` | Final assistant text when available |
| `structured_events` | Progress/warning/output event summary |
| `effective_provider_ref` | Provider/model or bridge actually used |
| `fallback_reason` | Why substitution happened, if it did |
| `artifact_refs` | Optional log or transcript refs |

## Required operations

The transport can vary. The semantic operations should stay stable.

| Operation | Purpose |
|---|---|
| `open_session` | Create a local RPC session |
| `invoke_harness` | Start one bounded harness execution |
| `stream_session_events` | Subscribe to incremental output/progress |
| `cancel_session` | Request stop/cancellation |
| `get_session_result` | Return terminal result summary |
| `list_profiles` | Return locally available harness profiles and health |
| `get_profile_health` | Return structured health for one profile |

For board-backed work, the daemon may additionally map these calls into:

- `start_attempt`
- `append_attempt_event`
- `renew_lease`
- `complete_attempt`
- `fail_attempt`

But those remain higher-order semantics above the local RPC interface.

## Transport guidance

The original item asked for a Unix socket. That is still the right default.

Preferred local transport order:

1. Unix socket RPC for same-host TUI/editor/operator clients
2. loopback HTTP for debugging or bridge compatibility
3. optional SSE or similar event stream for incremental output

The system should not require a heavyweight network service just to connect a
local TUI to local harnesses.

## Streaming model

The contract should support incremental output instead of forcing only terminal
responses.

Minimum event classes:

- `session_opened`
- `stdout_chunk`
- `stderr_chunk`
- `progress`
- `warning`
- `final_output`
- `failed`
- `cancelled`

This is the practical answer to the item’s desire that a TUI be able to trigger
and observe a live "Gemini Turn" or similar local seat invocation.

## Harness neutrality

The key architectural rule is that the RPC layer should not encode one provider
or one wrapper as the product.

It should work with:

- direct vendor CLI invocation
- a local `opencode serve` bridge
- future routed local harness multiplexers

That means the request/response model should preserve:

- requested voice identity
- effective execution path
- fallback or bridge reason
- structured health and degraded-state reporting

## OpenCode-specific conclusion

The old item was right to notice that OpenCode’s client-server shape is useful.

But the current repo line is narrower:

- do not fork OpenCode just to get a local RPC boundary
- define the boundary directly
- allow OpenCode to sit behind that boundary as one harness backend when it is
  actually the right tool

This matches the earlier decision to keep vendor CLIs as the v1 default while
leaving an `OpenCodeHarness` path available later.

## Relationship to nearby notes

This note narrows and connects:

- `docs/design/LOCAL_DAEMON_CONTRACT.md`
- `docs/design/LOCAL_SUBSCRIPTION_HARNESS_CONTRACT.md`
- `docs/design/CONTROLLED_EXECUTOR_CONTRACT.md`
- `docs/work-items/03-cli-agent-action.md`

It is also the prerequisite contract for:

- `54-dmux-vaglio-tui.md`

## Practical verdict

The maintained deliverable for this item is not "fork OpenCode."

It is:

- a local Unix-socket-first RPC contract
- with streaming and cancellation semantics
- preserving harness identity and fallback provenance
- and leaving OpenCode as an optional backend bridge rather than the canonical
  center of local orchestration

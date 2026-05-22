# Local Daemon Contract

**Status:** Drafted from Round 70  
**Purpose:** Define the runner contract between the bulletin board and local
subscription-backed CLI environments.

---

## 1. Why this exists

The execution board needs durable dispatch and status visibility, but many of
the most valuable agents here are local CLIs tied to human subscriptions:

- `codex`
- `gemini`
- `copilot`
- `claude`
- `opencode`

Those should run in the operator's local or managed runtime environment, not as
opaque server-side jobs pretending all providers are equal APIs.

This contract makes that local-execution model explicit.

---

## 2. Terms

### Runtime

A machine or environment capable of running agent processes.

Examples:

- a developer workstation
- a NixOS execution VM
- a future managed runner host

### Daemon

A local background service attached to a runtime that:

- advertises capabilities
- claims work
- launches CLI processes
- streams status back
- renews leases
- reports completion / failure

### Agent profile

A named runnable configuration on a runtime.

Examples:

- `codex-gpt54`
- `gemini-pro`
- `copilot-cli`
- `opencode-big-pickle`

Profiles are runtime-local execution choices. Long-term identity and capability
registry belong in Vaglio.

---

## 3. Contract principles

1. **Local execution first**
   The daemon launches the real CLI locally.

2. **Transport-agnostic**
   The contract can be implemented over HTTP, Unix socket RPC, or another local
   transport. The semantic operations matter more than the wire format.

3. **Lease-based claims**
   A daemon claims work for a bounded time and must renew that claim while the
   attempt is active.

4. **Append-only attempt history**
   The daemon reports events; the board preserves lineage.

5. **Structured failures**
   A daemon must report failure class, not only freeform text.

6. **Explicit human gates**
   If human input is needed, the daemon requests a gate instead of silently
   stalling.

---

## 4. Capability advertisement

On registration or heartbeat, the daemon should report:

- runtime ID
- host label
- available agent profiles
- supported transports / execution modes
- repo or workspace access labels
- tool capabilities
- software versions

Example shape:

```json
{
  "runtime_id": "rtk-strix-01",
  "host_label": "pve-strix runner",
  "status": "idle",
  "profiles": [
    {
      "id": "codex-gpt54",
      "provider": "codex",
      "model": "gpt-5.4",
      "supports_streaming": true,
      "supports_patch_output": true
    },
    {
      "id": "gemini-cli",
      "provider": "gemini",
      "model": "default",
      "supports_streaming": true,
      "supports_patch_output": false
    }
  ],
  "tools": ["git", "jj", "dolt", "nix", "python", "imagemagick"],
  "labels": ["linux", "nixos", "local-subscription"]
}
```

---

## 5. Required operations

These operations define the contract. Exact endpoint names can vary.

| Operation | Purpose |
|---|---|
| `register_runtime` | Create or refresh daemon identity |
| `heartbeat` | Update liveness, status, and advertised capabilities |
| `poll_work` | Request the next compatible work item |
| `claim_work` | Take a lease on a selected work item |
| `start_attempt` | Tell the board execution has begun |
| `append_attempt_event` | Emit progress, summary, partial output, or warnings |
| `renew_lease` | Extend active claim while the attempt is healthy |
| `request_human_gate` | Open a structured HITL pause |
| `complete_attempt` | Report successful completion |
| `fail_attempt` | Report structured failure |
| `release_claim` | Give work back if the daemon cannot continue |

---

## 6. Lease semantics

The board should not assume that a claimed item is healthy forever.

### Claim rules

- A claim has a `lease_expires_at`.
- The daemon must renew it periodically while active.
- If lease renewal stops, the board may mark the attempt stale and requeue or
  escalate according to policy.

### Why

This prevents “ghost ownership” when:

- the workstation sleeps
- a CLI hangs forever
- the daemon crashes
- network connectivity is lost

### Future resource-level lease note

Work-item leases are not the full contention model. The daemon and board should
eventually understand whether a claim is:

- branch-local and safe to run in parallel
- read-only against a shared target
- mutating a live resource that requires exclusivity

The expected future inputs are resource-oriented rather than repo-oriented:

- `contention_class`
- `resource_scope`
- `exclusive_lease_required`

That distinction matters because two agents can safely work on unrelated
branches of the same repo while still being unsafe to run `nixos-rebuild
switch`, `systemctl restart`, or cache-warming jobs against the same host at
the same time.

---

## 7. Attempt event model

Daemons should emit structured events rather than only one terminal payload.

Minimum event types:

- `claimed`
- `started`
- `progress`
- `warning`
- `needs_human_gate`
- `completed`
- `failed`
- `cancelled`

Example:

```json
{
  "attempt_id": "att_17",
  "event_type": "progress",
  "summary": "Running test suite after patch application",
  "metadata": {
    "phase": "validation",
    "percent": 70
  },
  "timestamp": "2026-05-11T23:40:00Z"
}
```

The board may store a compact summary view while retaining a link to full logs.

---

## 8. Human-gate request semantics

When a daemon cannot safely continue, it should request a structured gate.

Common reasons:

- clarification needed
- policy boundary exceeded
- conflicting instructions
- risky promotion / merge step
- ambiguous test or validation outcome

Example:

```json
{
  "attempt_id": "att_17",
  "gate_type": "clarify",
  "prompt": "The issue requests a fix but current branch contains unrelated user changes. Continue on a fresh branch?",
  "options": ["continue-fresh-branch", "continue-current-branch", "cancel"]
}
```

The daemon should transition to a paused state and stop consuming work until the
gate is resolved or the attempt is released.

---

## 9. Failure classes

The board needs failure categories that are machine-usable.

Minimum set:

| Failure class | Meaning |
|---|---|
| `input_error` | Task definition invalid or missing required context |
| `tool_error` | CLI or subprocess failed |
| `runtime_disconnect` | Daemon or host disappeared |
| `timeout` | Policy timeout exceeded |
| `policy_denied` | Requested action violates runtime or board policy |
| `human_rejected` | Human gate ended in rejection |
| `unknown_error` | Failure could not be classified cleanly |

This classification should feed retry policy.

---

## 10. Security and trust assumptions

### v1 assumptions

- the daemon is trusted by the operator who installed it
- board auth may be a runtime token or local socket ACL
- local CLI credentials remain local to the runtime

### Explicit rules

- the board must never require raw subscription credentials
- the daemon should not upload full secret-bearing environment snapshots
- logs sent back to the board should be trimmed / summarized where necessary

---

## 11. Transport notes

The contract deliberately does not require WebSockets.

Valid implementations include:

- HTTP polling
- Unix socket RPC
- long polling with incremental status posts

For v1, polling is acceptable if it is simple and observable.

---

## 12. Relationship to future components

### OpenCode proxy / RPC layer

This contract is the natural bridge to the existing `opencode`-proxy direction.

### Execution VM

The generic NixOS execution VM can host one or more daemons implementing this
contract.

### Vaglio

Vaglio can later enrich runtime / agent selection using persistent capability
and provenance data, but the daemon contract itself should stay narrow and
operational.

---

## 13. Explicit non-goals

This contract is **not**:

- a replacement for the roundtable protocol
- a promise of a single unified agent API across all providers
- a global capability / trust registry
- a full remote observability or SLA platform

It is a practical runner contract for getting real CLI work done durably.

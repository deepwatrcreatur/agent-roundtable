# Local Subscription Harness Contract

**Status:** Drafted from Rounds 55, 64, and 70
**Purpose:** Define the harness contract for local subscription-backed CLI seats
so high-signal work can preferentially use real local subscriptions while
degrading safely and transparently when those seats are unavailable.

---

## 1. Boundary

This note answers a narrow question:

> How should the system treat local subscription-backed CLI harnesses such as
> `codex`, `gemini`, `claude`, or similar seats, and what should happen when
> those harnesses are degraded?

The harness layer may own:

- local binary invocation
- local credential/session use
- provider-specific health checking
- runtime advertisement of harness capability
- structured degraded-state reporting

It must **not** silently decide:

- promotion or release authority
- claim/lease ownership semantics
- hidden provider substitution where voice identity matters
- durable evidence truth above the host

This keeps the harness as an execution seat, not a hidden control plane.

---

## 2. Why this exists

The project depends heavily on local CLI seats tied to human subscriptions.

That is valuable because it can provide:

- lower marginal cost for high-signal turns
- access to provider-native CLI behaviors
- continuity with operator-local workflows
- avoidance of unnecessary routed API spend

But it also creates real failure modes:

- expired subscription/session
- rate limits
- broken headless login state
- CLI drift or environment mismatch

So the harness layer needs an explicit contract instead of ad hoc operator
knowledge.

---

## 3. Core objects

### 3.1 `HarnessProfile`

Minimum shape:

| Field | Meaning |
|---|---|
| `profile_id` | Stable harness profile ID |
| `provider_class` | `codex`, `gemini`, `claude`, `copilot`, `opencode`, etc. |
| `binary_ref` | Binary or command family used |
| `auth_mode` | `local_session`, `api_key`, `mixed`, `unknown` |
| `voice_class` | `distinct_provider`, `commodity_ok`, or `policy_bound` |
| `runtime_ref` | Runtime advertising the harness |
| `capability_labels` | Streaming, patch output, long-context, file access, etc. |

### 3.2 `HarnessHealth`

Minimum shape:

| Field | Meaning |
|---|---|
| `profile_id` | Parent harness profile |
| `state` | `healthy`, `degraded`, `auth_expired`, `rate_limited`, `misconfigured`, `offline` |
| `checked_at` | Last check time |
| `reason_codes` | Structured reason list |
| `fallback_allowed` | Whether policy allows routed fallback |
| `observed_limits` | Known quota/rate/context constraints |

### 3.3 `HarnessExecutionDecision`

Minimum shape:

| Field | Meaning |
|---|---|
| `attempt_ref` | Attempt or request lineage anchor |
| `requested_profile_id` | Requested local harness |
| `decision_type` | `run_local`, `fallback_routed`, `fail_closed`, `require_human_override` |
| `voice_equivalence` | Whether the fallback preserves required voice semantics |
| `reason_codes` | Why the decision was taken |
| `recorded_at` | Decision time |

These are execution records, not governance truth.

---

## 4. Harness classes

### 4.1 Distinct local seats

Some harnesses should be treated as distinct voices whose identity matters:

- named provider CLI seats for review/vouch/synthesis
- seats whose provider-specific behavior is part of the intended evidence

Rules:

- do not silently replace them with a routed provider if the task requires that
  exact voice class
- fallback, if allowed, should be explicit and provenance-visible

### 4.2 Commodity-capable local seats

Some local harnesses may be suitable for cost-saving but not identity-critical
work:

- cheap local summarization paths
- non-critical extraction or formatting tasks

These can degrade more freely, subject to routing policy.

---

## 5. Required health states

The harness layer should classify failures rather than emitting vague breakage.

Minimum states:

| State | Meaning |
|---|---|
| `healthy` | local harness can run normally |
| `degraded` | usable with caveats or reduced capability |
| `auth_expired` | login/session/subscription must be refreshed |
| `rate_limited` | temporary provider throttle or quota exhaustion |
| `misconfigured` | binary, env, or local state is broken |
| `offline` | runtime or harness is unavailable |

This is the operational answer to the item’s original "Subscription Expired" or
"Rate Limited" concern.

---

## 6. Fallback rules

Fallback to routed/API provider paths is acceptable only under bounded policy.

### 6.1 Allowed fallback cases

Fallback may be allowed when:

- the task is commodity/cacheable rather than distinct-voice
- the requested harness is `rate_limited` or `auth_expired`
- routing policy has an approved substitute provider class
- provenance can record that fallback occurred

### 6.2 Disallowed silent fallback

Fallback should **not** happen silently when:

- the task explicitly requires a distinct local/provider voice
- the result will be treated as vouch-bearing or attribution-sensitive
- the user/operator asked for a specific seat

In those cases, the system should either:

- fail closed
- or require explicit human override

### 6.3 OpenRouter/routed-provider role

Routed providers are therefore:

- a bounded fallback layer
- and sometimes a cheaper commodity path

They are not a universal replacement for local subscription seats.

---

## 7. Capability advertisement

Local daemon/runtime registration should advertise harness-specific capability
and health, not only generic runtime existence.

At minimum, the runtime should be able to say:

- which harness profiles exist locally
- whether each one is healthy
- what output modes they support
- whether fallback is policy-allowed

This turns harness availability into schedulable queue information rather than
operator folklore.

---

## 8. Headless compatibility

The original item correctly emphasized "headless" compatibility.

The maintained rule is:

- local harnesses must be runnable without interactive editor/login surprises in
  the steady state
- if re-authentication is required, that must surface as explicit degraded
  state, not as a hanging attempt

This complements the broader queue goal of avoiding "stuck in bash" failures.

---

## 9. Provenance return

Every completed attempt or turn should preserve enough metadata to answer:

- which harness profile was requested
- whether it actually ran locally
- whether a fallback route was used
- which provider ultimately produced the result

Minimum fields:

| Field | Meaning |
|---|---|
| `requested_harness_profile` | Local profile originally requested |
| `effective_execution_class` | `local_harness`, `routed_provider`, `direct_api` |
| `effective_provider_ref` | Provider/model actually used |
| `fallback_reason` | Why fallback happened, if it did |

This avoids false assumptions that "local high-signal seat" was used when it
wasn’t.

---

## 10. Relationship to other contracts

This harness contract sits beneath and alongside:

- `LOCAL_DAEMON_CONTRACT.md`
  - runtime/daemon claiming and event semantics
- `AGENT_PROXY_AND_CACHE_CONTRACT.md`
  - routed-provider fallback and cache policy
- `CONTROLLED_EXECUTOR_CONTRACT.md`
  - executor/provider boundary for non-local execution paths

The distinction is:

- the harness contract defines **local seat behavior and degradation**
- the proxy contract defines **routed fallback/caching behavior**
- the daemon/executor contracts define **how those seats are scheduled and
  observed**

---

## 11. Recommended implementation sequence

1. define harness profiles and health states explicitly
2. advertise them through runtime capability/heartbeat payloads
3. classify tasks by whether fallback is allowed
4. record fallback/provenance in attempt events
5. only then automate more aggressive local-vs-routed scheduling

---

## 12. Final synthesis

The right posture for local subscription harnesses is:

- prefer them for high-signal work when healthy
- make their degraded states explicit and machine-usable
- allow routed fallback only under clear policy
- preserve provenance about whether the local seat actually produced the result

That is the minimum contract required to benefit from human subscription seats
without turning them into opaque or brittle hidden dependencies.

# Agent Proxy and Cache Contract

**Status:** Drafted from Rounds 55, 98, and 101
**Purpose:** Define the narrow proxy/cache layer that can reduce token spend and
smooth provider integration without becoming the canonical owner of agent
identity, authority, evidence, or promotion meaning.

---

## 1. Boundary

This note answers a narrow question:

> What should an agent-facing proxy/cache layer be allowed to do, and what must
> remain in the host control plane?

The proxy/cache layer may own:

- provider credential indirection
- request normalization across multiple model providers
- budget-aware routing decisions within host policy
- cache lookup and cache write policy enforcement
- rate-limit smoothing and retry coordination

The proxy/cache layer must **not** become the canonical owner of:

- claim or lease authority
- attempt lineage
- review / promotion decisions
- durable evidence truth
- agent identity semantics beyond scoped routing/runtime labels

This keeps the proxy useful without turning it into a hidden second control
plane.

---

## 2. Why this layer exists

The original motivation remains valid:

- lower token cost on redundant work
- preserve distinct model/provider voices where that distinction matters
- centralize provider integration and retry/cost policy

But later work added two stronger constraints:

1. cache isolation must be safe by default
2. provider or proxy infrastructure must not quietly redefine governance truth

So the modern form of this item is not "route everything through OpenRouter or
LiteLLM." It is:

- define the proxy as a replaceable **cost/control convenience layer**
- keep trust, authority, and durable evidence above it

---

## 3. Core proxy objects

### 3.1 `AgentProxyRequest`

Minimum shape:

| Field | Meaning |
|---|---|
| `request_id` | Stable proxy request ID |
| `attempt_ref` | Canonical attempt lineage anchor when present |
| `agent_profile_ref` | Requested agent/profile identity |
| `task_class` | `summarization`, `classification`, `synthesis`, `vouch`, `review_draft`, `analysis` |
| `voice_requirement` | `distinct_provider`, `stable_profile`, `cacheable`, or `commodity_ok` |
| `budget_policy_ref` | Applicable routing/budget policy |
| `cache_policy_ref` | Applicable cache isolation policy |
| `provider_constraints` | Allowed/excluded providers, models, or latency bounds |
| `input_hash` | Canonical request content hash for cache comparison |

### 3.2 `ProxyCacheEntry`

Minimum shape:

| Field | Meaning |
|---|---|
| `cache_key` | Canonical cache lookup key |
| `repo_ref` | Repo scope |
| `branch_ref` | Branch/ref scope when applicable |
| `trust_tier` | Trust tier of the producing execution path |
| `task_class` | Cached task class |
| `provider_class` | Which provider/model family generated the response |
| `written_by_attempt_ref` | Attempt that produced the entry |
| `content_hash` | Hash of cached contents |
| `created_at` | Cache write time |
| `expires_at` | TTL boundary |

### 3.3 `RoutingDecision`

Minimum shape:

| Field | Meaning |
|---|---|
| `request_id` | Parent request |
| `decision_type` | `cache_hit`, `cache_miss`, `proxy_route`, `direct_provider_bypass`, `policy_deny` |
| `selected_provider_ref` | Chosen provider/model route when applicable |
| `reason_codes` | Why this route was chosen |
| `estimated_cost_class` | `low`, `medium`, `high` |
| `recorded_at` | Decision timestamp |

These objects are operational records, not canonical governance truth.

---

## 4. Distinct voice vs commodity work

The proxy must distinguish between work where **voice/provider identity is part
of the meaning** and work where it is not.

### 4.1 Distinct-voice classes

Examples:

- vouch-bearing turns
- review or objection drafting tied to a named agent profile
- calibration-sensitive comparative turns
- evidence-bearing or attribution-sensitive synthesis

Rules:

- no cross-provider cache replay by default
- route according to explicit profile/provider policy
- return enough provenance to show which voice actually answered

### 4.2 Commodity / cacheable classes

Examples:

- summarization
- extraction
- cheap classification
- formatting / transformation
- duplicate report rendering

Rules:

- cache reuse is allowed within cache trust boundaries
- lower-cost provider classes are acceptable when policy allows
- provenance still matters, but exact "voice identity" is not treated as the
  primary product value

This is the core distinction behind the original "preserve distinct voices while
caching redundant turns" goal.

---

## 5. Routing policy

The proxy may route requests, but only inside host-owned policy.

### 5.1 Allowed routing inputs

- task class
- explicit voice requirement
- budget policy
- trust tier
- provider health / rate limit state
- latency and cost hints

### 5.2 Disallowed routing inputs

- hidden reputation of the agent asking
- opaque provider favoritism without policy basis
- cache availability alone when the task requires distinct voice
- publish/promotion authority

### 5.3 Budget-aware routing rule

Budget-aware routing is acceptable when:

- the task class is marked commodity or cacheable
- the chosen provider satisfies minimum policy/quality constraints
- provenance remains visible

Budget-aware routing is **not** a license to silently replace a named voice turn
with a cheaper provider when that identity difference matters.

---

## 6. Cache isolation

The proxy/cache layer must inherit the cache-trust model already defined
elsewhere rather than inventing its own looser rules.

At minimum, cache entries are scoped by:

- repository
- branch/ref
- trust tier
- workflow/task class
- provider class when voice identity matters

Default rule:

- a cache hit is valid only when the cache policy says this request may read the
  producing namespace

This means:

- no fork-to-main cache bleed
- no lower-trust poisoning of higher-trust cached outputs
- no "cheap cached answer" replayed into a distinct-voice or protected task
  class by accident

---

## 7. Direct-provider bypass

The host must be able to bypass the proxy/cache path.

Reasons include:

- provider-specific verification needs
- credential/path isolation requirements
- distinct-voice execution
- debugging policy mismatches
- proving the proxy is not a hidden semantic dependency

The proxy is therefore an **optimization and indirection layer**, not a
mandatory semantic dependency.

---

## 8. Provenance return

Every proxied or cached response should return enough metadata for the host to
reason about what happened.

Minimum fields:

| Field | Meaning |
|---|---|
| `provider_ref` | Actual provider/model used |
| `route_class` | `direct`, `proxied`, `cached` |
| `cache_status` | `hit`, `miss`, `write`, `bypass`, `denied` |
| `voice_requirement` | Effective voice policy used |
| `budget_policy_ref` | Budget policy in force |
| `response_hash` | Content hash for replay/audit |

This is not full deliberative provenance, but it is enough to keep the proxy
inspectable.

---

## 9. Security and authority boundaries

The proxy must not broaden authority just because it centralizes credentials.

Rules:

- proxy-issued credentials are scoped to provider access, not repo promotion
- cache write authority respects trust-tier rules
- a proxied response does not imply review or promotion approval
- provider credentials remain revocable independently of board/attempt authority

This keeps "provider access" separate from "governance authority."

---

## 10. Recommended initial deployment shape

An initial homelab deployment may reasonably use:

- OpenRouter-style multi-provider routing
- LiteLLM-style proxying/caching
- direct provider bypass for distinct-voice or verification-sensitive turns

But the product contract should name the **capabilities**, not the vendor names:

- provider multiplexing
- budget-aware routing
- cache isolation
- provenance return
- bypass path

That prevents the design from being trapped by a specific proxy product.

---

## 11. Recommended implementation sequence

1. classify task classes into distinct-voice vs commodity/cacheable
2. define host-owned routing and budget policies
3. enforce cache isolation using the existing trust-boundary model
4. add proxy provenance return fields to attempt/event records
5. only then optimize for provider multiplexing and cost

---

## 12. Final synthesis

The right proxy/cache layer is:

- cheap enough to reduce redundant spend
- strict enough not to blur voice identity
- isolated enough not to poison higher-trust paths
- narrow enough not to become hidden governance truth

That is the maintained contract for agent proxying and cache reuse in the
current architecture.

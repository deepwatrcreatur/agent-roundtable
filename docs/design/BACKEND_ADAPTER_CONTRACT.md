# Backend Adapter Contract

**Status:** Drafted from Rounds 60 and 120  
**Purpose:** Define the backend adapter contract that lets the governance
control plane run on ordinary Git-compatible hosts while treating API-first
backends as optional performance tiers rather than correctness dependencies.

---

## 1. Boundary

The governance product should own:

- canonical governance objects
- review/promotion semantics
- decision and supersession memory
- resource-claim semantics

The backend provider should own:

- repository persistence
- ref/object storage
- transport and sync mechanics
- durability/availability
- provider-native acceleration primitives

This contract exists so the control plane can remain correct on ordinary
Git-compatible hosting while still benefiting from faster backend classes where
available.

---

## 2. Three contract layers

The adapter contract should distinguish:

1. **Baseline portability contract**
   - required everywhere
2. **Optional optimization contract**
   - used when higher-performance backends exist
3. **Backend-specific extensions**
   - useful, but never canonical truth

That separation keeps portability honest.

---

## 3. Baseline portability contract

This is the minimum backend contract required for the governance/control plane
to function on an ordinary Git-compatible host.

### 3.1 Required capabilities

| Capability | Why it is required |
|---|---|
| Fetch repository refs and commits | anchor governance objects to real repo history |
| Push or update refs through ordinary Git-compatible semantics | move reviewed changes through the baseline path |
| Read repository tree structure by revision | discover durable repo-local artifacts and scoped paths |
| Read repository file/blob contents by revision | inspect durable repo-local artifacts, not just enumerate them |
| Observe baseline repository state changes | notice merges, branch updates, or equivalent |
| Resolve canonical repo identity | keep governance objects anchored to a stable repo |

### 3.2 Minimum contract shape

The baseline backend adapter should expose at least:

- `resolve_repo/1`
- `read_ref/2`
- `read_commit/2`
- `list_refs/1`
- `read_tree/3`
- `read_blob/3`
- `push_ref_update/4`
- `observe_repo_events/1`

The names are illustrative rather than mandatory. The important point is that
these operations can be satisfied by ordinary Git-compatible hosting without
special provider APIs. `read_tree/3` and `read_blob/3` are intentionally
separate because indexing or inspection work often needs both path discovery
and direct content reads for repo-local durable artifacts.

### 3.3 What baseline correctness must support

The governance product must still be able to:

- attach `Claim`, `Attempt`, and `DecisionRecord` objects to repository history
- gate promotion and merge through canonical control-plane objects
- index repo-local durable artifacts
- recover meaningfully after backend outages or degraded performance

If the product cannot do those things without an API-first backend, then the
baseline contract is not real.

---

## 4. Optional optimization contract

Some backends can accelerate the system materially without becoming mandatory.

Examples:

- lower-latency ref writes
- richer event delivery
- high-write agent traffic support
- API-native change submission
- future `jj`-forward backend primitives

### 4.1 Optimization-tier capabilities

| Capability | Example value |
|---|---|
| low-latency multi-ref or multi-file update | reduce orchestration overhead at high agent write volume |
| richer event delivery | reduce polling and improve freshness |
| higher write concurrency | support many ephemeral agent attempts |
| hosted change/intake APIs | avoid shelling out or local clone bottlenecks |
| `jj`-forward primitives | preserve change-centric semantics without collapsing to branch ritual |

### 4.2 Rule for optimization tiers

Optimization tiers may improve:

- throughput
- latency
- concurrency
- ergonomics

They must **not** become the sole authoritative place where governance truth
lives.

That means:

- `ReviewState` cannot exist only as a provider-native PR status
- `Lease` cannot exist only as a backend-native lock primitive
- `Attempt` cannot exist only as a backend-native workflow run

Optimization APIs are accelerators, not the canonical model.

---

## 5. Backend-specific extensions

Backend-specific extensions are allowed, but they must be explicitly fenced.

Examples:

- provider-native branch protection details
- high-rate event streams
- hosted workspace/session hints
- change-graph primitives unavailable on ordinary Git hosts

These extensions may be:

- consumed by adapters
- surfaced as optional capabilities
- used to improve operator experience

They must not silently redefine the canonical governance object model.

---

## 6. Graceful degradation

When higher-tier features are unavailable, the control plane should degrade to
the baseline portability contract rather than fail semantically.

### 6.1 Required degradation behavior

| Missing optimization | Required fallback |
|---|---|
| rich event stream | poll baseline repo/ref state |
| API-native write batching | use ordinary Git-compatible push/update path |
| hosted high-write traffic support | reduce throughput expectations, not correctness |
| `jj`-forward remote primitive | translate through baseline Git-compatible edge |

### 6.2 What must not degrade

The following must remain correct:

- claim/lease/review semantics
- promotion gates
- canonical governance history
- relationship to repo-local durable memory

What may degrade is:

- latency
- concurrency ceiling
- operator convenience
- write-path efficiency

---

## 7. Example backend classes

### 7.1 Conventional Git-host example

Example class:

- GitHub / Forgejo / any ordinary Git-compatible host

Expected contract:

- baseline portability contract only
- optional provider-specific extras if present

Operational consequence:

- correctness preserved
- higher polling and write overhead tolerated
- governance control plane still functions

### 7.2 API-first / higher-velocity backend example

Example class:

- `code.storage`-style API-first Git infrastructure

Expected contract:

- baseline portability contract
- plus optimization-tier APIs for:
  - lower-latency change/ref operations
  - richer event delivery
  - higher write concurrency

Operational consequence:

- same governance semantics
- better throughput and lower coordination overhead
- no new canonical truth trapped inside the provider

---

## 8. Relationship to governance objects

The backend contract exists to preserve the canonical governance object model
across backend classes.

The adapter must therefore preserve stable anchors for objects such as:

- `Claim`
- `Lease`
- `Attempt`
- `Supersession`
- `ReviewState`
- `PromotionGate`
- `AuthorityScope`
- `DecisionRecord`

The backend may supply:

- repo identifiers
- ref names
- commit IDs
- event hooks

It must not become the only place where those governance objects are
understandable or reconstructible.

---

## 9. Migration consequence

This contract is a prerequisite for later migration/export work.

If the baseline contract and optimization tiers are not separated clearly, then
customers cannot change backend providers without losing governance meaning or
being forced into provider-specific replay logic.

So this document is intentionally upstream of:

- governance export
- backend migration
- multi-backend product posture

For the portable migration package itself, see
`docs/design/GOVERNANCE_STATE_EXPORT_AND_MIGRATION.md`.

---

## 10. Non-goals

This contract does not attempt to:

- standardize all backend APIs
- eliminate all provider-specific advantages
- define the full migration/export package
- choose one winning backend

Its job is narrower:

- define the minimum portable backend contract
- define optional acceleration tiers
- keep canonical governance truth above the backend

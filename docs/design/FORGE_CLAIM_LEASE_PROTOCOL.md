# Forge Claim and Lease Protocol

**Status:** Drafted from Round 117  
**Purpose:** Define the smallest forge-native coordination protocol that makes
 multi-agent ownership explicit without turning the host into a full workflow
 engine.

---

## 1. Boundary

This protocol exists to solve a narrow class of problems that Git/`jj` alone do
not solve well:

- duplicate work on the same logical task
- conflicting mutation of the same shared live resource
- publish or promotion collisions
- unclear operator visibility into who currently owns the work

This protocol is **not** a general workflow engine.

It should remain:

- forge-native
- narrow
- enforceable
- compatible with both Git-backed and `jj`-backed local mutation flows

---

## 2. Canonical host objects

The minimum forge-native coordination layer should standardize four objects.

### 2.1 `Claim`

A `Claim` is ownership of a **logical work unit**.

Examples:

- implement a bug fix
- prepare a benchmark
- write a review
- investigate a failing deployment

A claim answers:

- who is currently responsible for the work item
- whether another worker should begin duplicate work
- which attempt lineage is current

Claims are about **intent ownership**, not resource authority by themselves.

### 2.2 `Lease`

A `Lease` is bounded authority to mutate a **shared resource scope**.

Examples:

- `host:vaglio`
- `cache:public-repo-demo`
- `publish:forgejo-shell`
- `db:board-main`

Leases are about **mutation authority**:

- they have TTL
- they must be renewed
- they can expire
- they can be taken over
- they can be overridden by an operator

### 2.3 `Attempt`

An `Attempt` is one concrete execution run under a claim, optionally using one
or more leases.

It records:

- runtime identity
- agent/profile identity
- start and finish times
- result class
- artifacts and summary
- whether it superseded a prior attempt

Attempts are append-only lineage.

### 2.4 `ReviewState`

A `ReviewState` is the forge-visible human checkpoint around promotion.

It answers:

- whether the current attempt is still exploratory
- whether it is awaiting human approval
- whether it is approved for promotion
- whether it was rejected or superseded

`ReviewState` keeps human promotion authority explicit instead of burying it in
ad hoc comments or external workflow state.

---

## 3. Distinction: claim vs lease

The key protocol distinction is:

- `Claim` protects against duplicate logical work
- `Lease` protects against conflicting shared-resource mutation

This matters because the same claim may or may not need a lease.

Examples:

- writing code on a private branch:
  - claim required
  - no shared-resource lease necessarily required
- deploying to `host:vaglio`:
  - claim required
  - lease required on `host:vaglio`
- preparing a release candidate:
  - claim required
  - lease may be required on `publish:*` or another promotion boundary

So a forge must not collapse all coordination into only one concept.

---

## 4. Core fields

### 4.1 `Claim`

Minimum shape:

| Field | Meaning |
|---|---|
| `id` | Stable claim ID |
| `work_item_ref` | Logical task anchor |
| `repo_ref` | Repo or project anchor |
| `branch_ref` | Optional branch / change context |
| `owner_type` | `agent`, `runtime`, or `human` |
| `owner_ref` | Current owner identifier |
| `status` | `open`, `active`, `blocked`, `superseded`, `closed`, `abandoned` |
| `current_attempt_ref` | Latest active attempt |
| `created_at` | Claim creation time |
| `updated_at` | Last mutation |

### 4.2 `Lease`

Minimum shape:

| Field | Meaning |
|---|---|
| `id` | Stable lease ID |
| `claim_ref` | Parent claim |
| `resource_scope` | Resource identifier such as `host:vaglio` |
| `contention_class` | Resource class such as `mutable_live_host` |
| `holder_ref` | Current holder |
| `lease_state` | `active`, `expiring`, `expired`, `released`, `taken_over`, `overridden` |
| `exclusive` | Whether single-writer mutation is required |
| `ttl_s` | Lease TTL in seconds |
| `lease_expires_at` | Expiry timestamp |
| `last_renewed_at` | Last successful heartbeat/renewal |
| `takeover_count` | Number of takeovers |
| `created_at` | Creation time |

### 4.3 `Attempt`

Minimum shape:

| Field | Meaning |
|---|---|
| `id` | Attempt ID |
| `claim_ref` | Parent claim |
| `lease_refs` | Resource leases held during the run |
| `runtime_ref` | Runtime executing the attempt |
| `agent_profile_ref` | Agent/profile used |
| `status` | `claimed`, `running`, `awaiting_review`, `failed`, `succeeded`, `cancelled`, `superseded` |
| `supersedes_attempt_ref` | Prior attempt replaced by this one |
| `started_at` | Start time |
| `finished_at` | End time |
| `summary` | Human-readable result |
| `artifact_refs` | Logs, patch, transcript, report bundles |

### 4.4 `ReviewState`

Minimum shape:

| Field | Meaning |
|---|---|
| `id` | Review state ID |
| `claim_ref` | Related claim |
| `attempt_ref` | Attempt under review |
| `state` | `draft`, `awaiting_human`, `approved`, `rejected`, `merged`, `superseded` |
| `reviewer_ref` | Human reviewer when present |
| `decision_summary` | Compact approval/rejection note |
| `promotion_gate_ref` | Optional promotion gate link |
| `updated_at` | Last transition time |

---

## 5. Lease lifecycle semantics

### 5.1 Acquire

An attempt may request a lease before mutating a protected resource.

Acquisition should fail or queue when:

- another active exclusive lease already holds the same `resource_scope`
- the holder is still renewing within TTL

### 5.2 Renew / heartbeat

While the attempt is healthy, the holder renews the lease periodically.

The forge should treat renewal as the authoritative signal that:

- the holder is still alive
- the mutation authority should remain in place

### 5.3 Expiry

If renewal stops and TTL elapses:

- the lease becomes `expired`
- the forge may surface takeover or requeue options
- historical lineage remains visible; expiry does not erase prior ownership

### 5.4 Takeover

Takeover is explicit transfer after expiry or under policy-defined degraded
conditions.

Takeover should record:

- who took over
- from whom
- when
- why takeover was permitted

This should be visible in attempt and lease lineage, not hidden as a mutable
overwrite.

### 5.5 Operator override

Some situations need explicit human override:

- a stuck holder is still nominally alive
- a production incident requires immediate mutation
- automation policy is too conservative for the current risk context

Operator override should be first-class and auditable, not an implicit
"somebody retried it and it worked."

---

## 6. Collision classes the protocol must distinguish

### 6.1 Duplicate task work

Two agents begin the same logical task without shared ownership context.

Primary control:

- `Claim`

### 6.2 Conflicting shared-resource mutation

Two agents mutate the same host, cache, database, or promotion boundary.

Primary control:

- `Lease`

### 6.3 Publish / promotion collision

Two attempts try to cross the same publish or promotion boundary.

Primary control:

- `ReviewState`
- promotion/publish gate
- optional publish-scoped lease

These are related failures, but they are not the same failure.

---

## 7. Recommended state transitions

### 7.1 Claim

```text
open -> active -> blocked -> active -> closed
open -> active -> superseded
open -> active -> abandoned
```

### 7.2 Lease

```text
active -> active (renewed)
active -> expiring -> expired
expired -> taken_over
active -> released
active -> overridden
```

### 7.3 Attempt

```text
claimed -> running -> awaiting_review -> succeeded
claimed -> running -> failed
claimed -> running -> cancelled
claimed -> running -> superseded
```

### 7.4 ReviewState

```text
draft -> awaiting_human -> approved -> merged
draft -> awaiting_human -> rejected
draft -> awaiting_human -> superseded
```

---

## 8. Backend and workflow compatibility

This protocol should remain compatible with:

- Git-backed local branches
- `jj` change-based local mutation
- thin local CLI adapters
- host-managed runners

That means the forge-native layer should avoid depending on:

- worktree path semantics
- provider-specific branch naming tricks
- one orchestration runtime

The shared truth should be claims, leases, attempts, and review states, not
local filesystem details.

---

## 9. Explicit non-goals

This protocol should not become:

- a DAG workflow engine
- a full compute scheduler
- a replacement for repo-local knowledge/memory artifacts
- a monopoly on local editing/runtime mechanics

Its job is narrower:

- make ownership explicit
- make mutation authority explicit
- preserve attempt lineage
- preserve human promotion authority

---

## 10. Relationship to existing project layers

- markdown rounds:
  - canonical policy and rationale
- repo-local memory / task graphs:
  - portable project knowledge
- forge claim/lease protocol:
  - host-native coordination truth
- local runtime:
  - transient execution details

That split preserves portability without giving up enforceable coordination.

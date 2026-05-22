# Governance Object Model

**Status:** Drafted from Rounds 117 and 120  
**Purpose:** Define the startup-owned canonical object model for the
governance/control plane so canonical truth remains above provider-native VCS or
workflow artifacts.

---

## 1. Boundary

The governance/control plane should own the canonical meaning of:

- who owns work
- who may mutate contested resources
- what execution attempts happened
- what superseded what
- what authority each actor holds
- what promotion boundary was crossed
- what human decision actually approved or rejected the change

This layer must not collapse into:

- provider-native branches
- webhook logs
- CI job state
- worktree paths
- repo host–specific event formats

Those may remain useful transport or optimization surfaces, but they are not
the authoritative governance model.

---

## 2. Authority split

The object model should distinguish three storage/authority classes.

### 2.1 Host-side live coordination state

Authoritative for:

- active ownership
- active mutation authority
- attempt lineage
- promotion/review state
- authority scopes

These objects are time-bounded, mutable, and enforceable.

### 2.2 Repo-local durable artifacts

Authoritative for:

- rationale worth versioning with the project
- durable policy and constraints
- project-specific memory
- portable decision context that should survive backend changes

These artifacts travel with the repo rather than remaining trapped in the
hosted control plane.

### 2.3 Derived or indexed views

Useful for:

- search
- dashboards
- lineage browsing
- joins across canonical objects

Derived views are not the source of truth.

---

## 3. Canonical objects

The minimum canonical governance/control-plane objects are:

- `Claim`
- `Lease`
- `Attempt`
- `Supersession`
- `ReviewState`
- `PromotionGate`
- `AuthorityScope`
- `DecisionRecord`

### 3.1 `Claim`

Canonical class:

- host-side live coordination state

Purpose:

- ownership of a logical work unit
- duplicate-work prevention
- top-level anchor for attempt lineage

Minimum fields:

| Field | Meaning |
|---|---|
| `id` | Stable claim ID |
| `work_item_ref` | Logical work anchor |
| `repo_ref` | Repository or project anchor |
| `branch_ref` | Optional branch / change context |
| `owner_ref` | Current actor or runtime owner |
| `status` | `open`, `active`, `blocked`, `superseded`, `closed`, `abandoned` |
| `current_attempt_ref` | Latest active attempt |
| `created_at` | Creation time |
| `updated_at` | Last mutation |

### 3.2 `Lease`

Canonical class:

- host-side live coordination state

Purpose:

- bounded shared-resource mutation authority
- protection against live collision on a contested scope

Minimum fields:

| Field | Meaning |
|---|---|
| `id` | Stable lease ID |
| `claim_ref` | Parent claim |
| `resource_scope` | Scope such as `host:vaglio` or `publish:forgejo-shell` |
| `contention_class` | Resource class such as `mutable_live_host` |
| `holder_ref` | Current holder |
| `lease_state` | `active`, `expiring`, `expired`, `released`, `taken_over`, `overridden` |
| `ttl_s` | Lease TTL |
| `lease_expires_at` | Expiry timestamp |
| `last_renewed_at` | Last heartbeat |
| `exclusive` | Whether single-writer mutation is required |

### 3.3 `Attempt`

Canonical class:

- host-side live coordination state

Purpose:

- append-only execution lineage
- runtime/accountability record
- concrete execution result under a claim

Minimum fields:

| Field | Meaning |
|---|---|
| `id` | Attempt ID |
| `claim_ref` | Parent claim |
| `runtime_ref` | Executing runtime |
| `agent_profile_ref` | Actor/profile used |
| `lease_refs` | Resource leases held during the run |
| `status` | `claimed`, `running`, `awaiting_review`, `failed`, `succeeded`, `cancelled`, `superseded` |
| `supersedes_attempt_ref` | Prior attempt replaced by this one |
| `started_at` | Start time |
| `finished_at` | End time |
| `artifact_refs` | Logs, patches, reports, transcripts |
| `summary` | Short human-readable outcome |

### 3.4 `Supersession`

Canonical class:

- host-side live coordination state
- may also be mirrored into repo-local memory where long-horizon rationale
  matters

Purpose:

- explicit statement that one object replaced another
- supports durable “what replaced what, and why” browsing

Minimum fields:

| Field | Meaning |
|---|---|
| `id` | Stable supersession ID |
| `source_type` | Object type being replaced |
| `source_ref` | Replaced object |
| `replacement_type` | Object type that superseded it |
| `replacement_ref` | Replacing object |
| `reason` | Compact rationale |
| `created_at` | When supersession was recorded |

### 3.5 `ReviewState`

Canonical class:

- host-side live coordination state

Purpose:

- human-visible checkpoint around review, objection, and approval

Minimum fields:

| Field | Meaning |
|---|---|
| `id` | Review state ID |
| `claim_ref` | Related claim |
| `attempt_ref` | Attempt under review |
| `state` | `draft`, `awaiting_human`, `approved`, `rejected`, `merged`, `superseded` |
| `reviewer_ref` | Human reviewer when present |
| `decision_summary` | Compact review note |
| `updated_at` | Last transition time |

### 3.6 `PromotionGate`

Canonical class:

- host-side live coordination state

Purpose:

- explicit control over merge/publish/promotion boundaries
- keeps human authority visible at the point where change becomes canonical

Minimum fields:

| Field | Meaning |
|---|---|
| `id` | Stable promotion gate ID |
| `target_type` | `merge`, `publish`, `deploy`, `release`, or similar |
| `target_ref` | Concrete branch, package, deploy surface, or artifact |
| `required_authority_scope_ref` | Required authority to pass the gate |
| `state` | `open`, `awaiting_human`, `approved`, `rejected`, `expired`, `consumed` |
| `decision_ref` | Decision or review event that resolved it |
| `created_at` | Creation time |
| `updated_at` | Last transition time |

### 3.7 `AuthorityScope`

Canonical class:

- host-side live coordination state

Purpose:

- bounded statement of what an actor is allowed to do
- prevents capability drift into implicit trust

Minimum fields:

| Field | Meaning |
|---|---|
| `id` | Stable scope ID |
| `subject_ref` | Agent, runtime, maintainer, or service identity |
| `subject_type` | Actor class |
| `allowed_actions` | Structured action set |
| `repo_scopes` | Repo or org boundaries |
| `resource_scopes` | Allowed contested-resource scopes |
| `promotion_rights` | Whether promotion/merge/publish is allowed |
| `expires_at` | Optional scope expiry |
| `created_at` | Creation time |

### 3.8 `DecisionRecord`

Canonical class:

- repo-local durable artifact
- host-indexed for search/query

Purpose:

- durable rationale that should survive backend migration
- link between governance action and the reasoning/evidence behind it

Minimum fields:

| Field | Meaning |
|---|---|
| `id` | Stable decision ID |
| `repo_ref` | Project anchor |
| `title` | Short decision title |
| `status` | `proposed`, `accepted`, `rejected`, `superseded` |
| `rationale_ref` | Markdown or durable artifact anchor |
| `evidence_refs` | Evidence used |
| `related_claim_refs` | Related claim lineage |
| `related_attempt_refs` | Related attempts |
| `created_at` | Creation time |
| `updated_at` | Last mutation |

---

## 4. Relationship map

The canonical relationships should look like:

- `Claim`
  - has many `Attempt`
  - may require many `Lease`
  - has one current `ReviewState`
- `Attempt`
  - may hold many `Lease`
  - may supersede another `Attempt`
  - may be constrained by a `PromotionGate`
- `Lease`
  - protects one `resource_scope`
  - is tied to one active `Claim` at a time
- `PromotionGate`
  - requires an `AuthorityScope`
  - resolves through a `ReviewState` or `DecisionRecord`
- `DecisionRecord`
  - links governance reasoning to `Claim`, `Attempt`, `PromotionGate`, or
    `Supersession`

---

## 5. Backend portability rule

The object model should be usable across:

- ordinary Git hosting
- API-first Git backends
- future `jj`-forward backends

That means these objects must not require provider-native concepts as their only
identity or persistence shape.

Acceptable backend-specific links:

- branch names
- commit SHAs
- PR/MR IDs
- webhook event IDs

Unacceptable collapse:

- “the PR state is the only review state”
- “the CI job is the only attempt record”
- “the backend branch lock is the only lease”

For the adapter contract that preserves this boundary, see
`docs/design/BACKEND_ADAPTER_CONTRACT.md`.

Provider-native objects may be mirrors or transport hooks, not the sole
authority.

---

## 6. Export and migration consequence

Because the governance layer is canonical, it must later support:

- export
- restore
- backend migration

This is why object boundaries must be explicit now. A future migration item can
only work if these objects are clearly separable from provider-native hosting
artifacts.

---

## 7. Recommended operational split

### Host-side live state

- `Claim`
- `Lease`
- `Attempt`
- `ReviewState`
- `PromotionGate`
- `AuthorityScope`

### Repo-local durable memory

- `DecisionRecord`
- selected `Supersession` records where rationale should travel with the repo

### Derived/indexed surfaces

- dashboards
- board read models
- round metadata indices
- cross-object search views
- backend-export bundles

---

## 8. Non-goals

This object model does not require:

- a single storage engine
- a single backend provider
- a full orchestration workflow engine
- hiding repo-local artifacts inside the hosted control plane

Its job is to define the canonical governance truth, not to dictate every
runtime or UI detail.

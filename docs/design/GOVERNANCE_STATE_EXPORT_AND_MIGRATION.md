# Governance State Export and Backend Migration

**Status:** Drafted from Round 120  
**Purpose:** Define the portable export package and migration semantics that let
the governance/control plane change backend providers without losing decision
lineage, promotion history, or the relationship between live coordination state
and repo-local memory.

---

## 1. Boundary

Migration/export must preserve the governance layer, not merely copy Git refs.

The portable package should capture enough canonical state to answer:

- what work claims existed
- which attempts happened and in what order
- what superseded what
- which human decisions approved, rejected, or promoted change
- which repo-local durable artifacts those decisions depended on

The package should not attempt to preserve every provider-native runtime detail.

---

## 2. Migration objective

Backend migration should preserve:

- auditability
- human promotion history
- continuity of maintainer understanding
- stable linkage to repo-local durable memory

It should avoid making customers replay provider-native webhook logs, CI runs,
or PR metadata just to reconstruct governance meaning.

---

## 3. Export classes

The migration package should distinguish three classes of material.

### 3.1 Lossless canonical export

Must migrate losslessly because it carries canonical governance meaning.

### 3.2 Re-derivable views

May be omitted from the canonical package if they can be rebuilt deterministically
from canonical objects plus repo history.

### 3.3 Backend-local operational residue

May be dropped because it is transport/runtime residue rather than portable
governance truth.

---

## 4. Lossless canonical export set

The minimum portable package should include the following canonical objects.

### 4.1 Host-side governance objects

These must migrate losslessly:

- `Claim`
- `Lease`
- `Attempt`
- `Supersession`
- `ReviewState`
- `PromotionGate`
- `AuthorityScope`
- `DecisionRecord`

For each object, the package must preserve:

- stable ID
- object type
- full canonical fields
- timestamps
- relationship refs to other governance objects
- anchors to repo/ref/commit identity where relevant

### 4.2 Repo-linked durable artifacts

The package must also preserve the mapping to repo-local durable memory such as:

- decision notes worth versioning with the project
- policy or constraint files used by governance decisions
- durable rationale linked from `DecisionRecord`
- project memory that maintainers expect to survive backend changes

The export does not need to inline repo contents when those artifacts already
live durably in repository history, but it must preserve enough anchors to
recover them:

- repo identity
- revision / commit anchor
- path anchor
- expected artifact type

### 4.3 Identity and authority references

The package must preserve portable identity references for:

- human maintainers
- service/runtime identities
- agent profiles
- authority scopes referenced by promotion or review decisions

Migration should avoid reducing these to provider-specific usernames where a
stable project-local or product-local identity can be preserved.

### 4.4 Attempt and supersession lineage

The package must preserve the execution story, not only the final state:

- which attempts happened
- which attempt superseded another
- which attempt was reviewed
- which attempt passed or failed a promotion gate
- which decision resolved the gate

This is necessary to keep the system auditable after backend change.

---

## 5. Re-derivable views

The following may be rebuilt after import rather than exported losslessly:

- search indexes
- kanban/read-model projections
- round metadata indexes
- dashboard aggregates
- graph/materialized lineage views
- cache entries or warmed demo snapshots

These are useful, but they are not the canonical truth.

If a view is expensive to rebuild, it may be exported as an optimization
artifact, but it must remain explicitly optional.

---

## 6. Backend-local residue that may be dropped

The following should be treated as backend-local operational residue unless
explicitly promoted into canonical governance objects:

- webhook delivery IDs
- provider-native PR review decorations
- CI job IDs and transient run metadata
- backend-native lock primitives
- transient cache keys
- local clone paths
- provider-specific event cursor state

This data may help operators during cutover, but it is not required for
portable governance continuity.

---

## 7. Portable package shape

The migration package should have a small number of explicit top-level
components.

### 7.1 Canonical manifest

Describes:

- export format version
- exporting product version
- exported repo set
- export timestamp
- source backend class
- destination backend assumptions if any

### 7.2 Canonical object stream

Contains the lossless governance objects in an append-friendly format such as:

- JSONL
- Dolt-exportable rows
- other line-oriented stable records

The exact storage format may vary, but the logical shape must stay portable.

### 7.3 Repo anchor map

Maps canonical governance objects to:

- repo identity
- ref names where relevant
- commit IDs
- path anchors for durable artifacts

### 7.4 Optional derived bundle

May contain:

- indexes
- caches
- rendered reports
- search/materialized projections

Importers must be allowed to ignore this bundle and regenerate it.

---

## 8. Import semantics

Import should proceed in layers.

### 8.1 Restore canonical objects first

The destination control plane must restore:

- canonical IDs
- relationships
- timestamps
- authority/promotion state

before rebuilding any derived views.

### 8.2 Rebind backend anchors second

After canonical object restore, the destination may rebind:

- repo host identifiers
- event subscriptions
- webhook wiring
- provider-native acceleration hooks

This rebinding must not change canonical governance meaning.

### 8.3 Rebuild derived views last

Only after canonical import succeeds should the system rebuild:

- indexes
- dashboards
- search views
- read models

---

## 9. Auditability rules

Migration/export must preserve enough information that an auditor can still
answer:

- who held authority
- who approved promotion
- what was rejected or superseded
- what project-local memory informed that decision
- which repo state the decision was about

If those questions cannot be answered after migration without consulting the
old backend provider, the export package is insufficient.

---

## 10. Relationship to backend classes

This export contract sits above the backend adapter contract.

- baseline Git-compatible hosts must still be sufficient to reconstruct the
  package
- API-first backends may accelerate export/import and provide richer residue
  capture
- provider-native optimizations must not become the only source of migration
  truth

This is the portability guarantee that turns backend choice into an operational
decision rather than a lock-in boundary.

---

## 11. Recommended portability rule

The system should behave as though backend loss is survivable if the following
remain available:

- canonical governance export
- repository history containing durable project memory
- documented identity mapping rules

Everything else should be considered rebuildable, optional, or operational
residue.

---

## 12. Non-goals

This document does not attempt to:

- define a one-click cutover tool
- preserve every provider-native cosmetic detail
- standardize all backend event formats
- require one storage engine for canonical exports

Its job is narrower:

- define the portable governance migration package
- separate lossless truth from rebuildable views
- keep decision lineage and promotion history portable across backend changes

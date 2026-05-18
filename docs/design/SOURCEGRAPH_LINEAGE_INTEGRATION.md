# Sourcegraph + Lineage-Aware Decision Memory Integration

**Status:** Drafted from Round 90 and work item 80  
**Purpose:** Define a thin integration layer where Sourcegraph supplies discovery
and code understanding while the local system supplies decision memory, local
constraints, and outcome-linked lineage around code change.

---

## 1. Why this exists

Round 90 concluded that the project should **not** compete with Sourcegraph on
generic semantic code search or broad whole-codebase understanding.

The useful complement is narrower:

- Sourcegraph is the **discovery plane**
- the local system is the **decision-memory plane**

The goal is to help agents and engineers answer not only:

- where is the code
- how does it work
- what changed nearby

but also:

- what replaced this
- what was rejected here before
- which constraints are still active
- what incidents or fixes shaped the current state
- which earlier predictions later held up

This document turns that complementarity into a concrete design.

---

## 2. Non-goals

This integration should **not** begin by trying to:

- replicate all Sourcegraph state into a new local search index
- replace Sourcegraph search UX
- require Sourcegraph to adopt `jj`
- claim that graph/lineage alone beats semantic search
- create portable person-level trust or reputation scores from query history

The first useful version is a thin linking layer, not a new search engine.

---

## 3. Boundary of responsibility

### Sourcegraph owns

- semantic and keyword retrieval
- file and repository exploration
- code navigation
- commit and diff search
- Deep Search conversations and sources

### The local system owns

- active constraints and invariants near code
- supersession and replacement chains
- incident and known-fix memory
- proposal / rejection / outcome records
- prediction-to-outcome linkage
- agent brief generation before edits

### Integration contract

The integration should pass compact, inspectable evidence from Sourcegraph into
local records and then join that evidence with local deliberation artifacts.

---

## 4. Thin adapter surface

The first adapter should be a small layer over Sourcegraph MCP and documented
APIs.

### 4.1 Required capabilities

| Capability | Sourcegraph surface | Why it matters |
|---|---|---|
| Semantic search | `nls_search` / equivalent | Find conceptually related code |
| Keyword search | `keyword_search` / equivalent | Precise patterns and scoped lookup |
| File read | `read_file` | Ground answers in exact code |
| File listing | `list_files` | Scope subtree briefs |
| Commit search | `commit_search` | Recover nearby historical changes |
| Diff search | `diff_search` | Find similar prior edits |
| Deep Search access | Deep Search endpoint / conversation URL | Preserve useful search sessions as evidence |

### 4.2 Adapter principles

1. **Pass through Sourcegraph references**
   Keep repository names, revisions, paths, and conversation URLs intact.

2. **Normalize only what local records need**
   Convert retrieved context into a small canonical evidence shape.

3. **Do not hide provenance**
   If a subtree brief cites Sourcegraph results, it must preserve:
   - query used
   - repositories searched
   - files read
   - revision or conversation reference

4. **Stay revision-aware**
   The adapter should accept explicit revision context whenever possible so briefs
   do not silently drift.

---

## 5. Canonical local evidence record

Each imported Sourcegraph context should normalize into a local evidence record.

### 5.1 Record shape

```json
{
  "id": "sgctx_2026_05_15_001",
  "source_type": "sourcegraph_search_context",
  "provider": "sourcegraph",
  "retrieval_mode": "nls_search",
  "repo": "acme/auth-service",
  "revision": "refs/heads/main",
  "path_scope": "src/auth",
  "sourcegraph_query": "how is token refresh handled",
  "sourcegraph_conversation_url": null,
  "files_read": [
    "src/auth/refresh.ts",
    "src/auth/token_store.ts"
  ],
  "commits_examined": [
    "abc123",
    "def456"
  ],
  "diffs_examined": [],
  "created_at": "2026-05-15T02:00:00Z",
  "created_by_attempt": "att_42",
  "summary": "Refresh flow uses rotating token store and invalidates sessions on reuse."
}
```

### 5.2 Minimum fields

| Field | Meaning |
|---|---|
| `id` | Stable local evidence ID |
| `source_type` | `sourcegraph_search_context` or `sourcegraph_deep_search` |
| `provider` | `sourcegraph` |
| `retrieval_mode` | Search type or Deep Search |
| `repo` | Repository anchor |
| `revision` | Branch / tag / commit anchor |
| `path_scope` | File, directory, or subtree scope |
| `sourcegraph_query` | User or agent query |
| `sourcegraph_conversation_url` | Deep Search conversation link if present |
| `files_read` | Exact files inspected |
| `commits_examined` | Commits used as evidence |
| `diffs_examined` | Diffs used as evidence |
| `created_by_attempt` | Board attempt that created the record |
| `summary` | Compact local digest |

### 5.3 Link targets

Every record should be linkable to one or more local objects:

- `work_item_id`
- `decision_id`
- `prediction_id`
- `incident_id`
- `fix_id`

This can be modeled either as:

- a generic `evidence_links` table, or
- typed link arrays in each owning record

The important property is explicit linkage, not a specific storage engine yet.

---

## 6. Subtree brief format

The most valuable near-term output is a compact pre-change brief for a bounded
surface.

### 6.1 Brief key

A subtree brief is keyed by:

- `repo`
- `revision`
- `path_scope`

Example key:

```text
repo: acme/auth-service
revision: refs/heads/main
path_scope: src/auth
```

### 6.2 Brief contents

A first version should include the following sections:

1. **Code surface summary**
   - compact Sourcegraph-backed explanation of what the subtree does

2. **Active constraints**
   - local decisions, invariants, or incidents still in force

3. **Recent supersession**
   - what recently replaced older patterns here

4. **Rejected precedents**
   - similar ideas previously rejected, with reasons if available

5. **Prediction / outcome notes**
   - prior expectations that later succeeded, failed, or remain unresolved

6. **Operator guidance**
   - what an agent should check before proposing a change

### 6.3 Example brief shape

```yaml
brief_id: brief_src_auth_main_001
repo: acme/auth-service
revision: refs/heads/main
path_scope: src/auth
sourcegraph_context:
  query: "token refresh and invalidation flow"
  files_read:
    - src/auth/refresh.ts
    - src/auth/token_store.ts
local_context:
  active_constraints:
    - "Refresh tokens must rotate on every successful refresh."
    - "Reuse detection must invalidate the entire session family."
  superseded_patterns:
    - old: "stateless refresh token acceptance"
      replaced_by: "reuse-detecting rotating token store"
  rejected_precedents:
    - "Do not move refresh validation into middleware; prior attempt obscured reuse detection."
  outcome_notes:
    - "Earlier proposal to allow idempotent refresh was reverted after session fixation incident."
operator_guidance:
  - "Check incident links before changing rotation semantics."
  - "Search for prior rejection reasons before proposing middleware centralization."
```

---

## 7. Pre-change flow

This is the highest-value first workflow.

### 7.1 Flow

1. A work item targets a repo + path or subtree.
2. The agent or board asks Sourcegraph for bounded discovery:
   - semantic search
   - targeted file reads
   - nearby commit/diff search
3. The adapter creates a local Sourcegraph evidence record.
4. The local system joins that evidence with:
   - active decisions
   - incidents
   - fixes
   - supersession chains
   - predictions and outcomes
5. A subtree brief is generated and attached to the attempt.
6. The agent uses that brief before proposing or editing code.

### 7.2 Result

The agent should enter the edit phase with both:

- code understanding from Sourcegraph
- local memory of what not to repeat and what constraints already exist

---

## 8. Post-change flow

The second critical workflow is linking retrieval to real outcomes.

### 8.1 Flow

1. A change proposal is produced.
2. The proposal record links to the Sourcegraph evidence record(s) that informed
   it.
3. The proposal later resolves to an outcome such as:
   - merged
   - superseded
   - reverted
   - abandoned
   - caused follow-up churn
4. That outcome is linked back to:
   - the proposal
   - the local prediction record if one exists
   - the Sourcegraph evidence context used
5. Later agents can inspect not only what was searched, but whether the resulting
   judgment held up.

### 8.2 Why this matters

Without post-change linkage, search sessions are merely ephemeral research.
With linkage, they become part of the organization's learnable decision corpus.

---

## 9. Suggested record additions

This does not require a full schema implementation yet, but the design needs a
clear target.

### 9.1 `external_evidence_records`

| Field | Meaning |
|---|---|
| `id` | Evidence record ID |
| `provider` | `sourcegraph` |
| `source_type` | `search_context`, `deep_search_conversation` |
| `repo_ref` | Repository |
| `revision_ref` | Revision |
| `path_scope` | File or subtree anchor |
| `query_text` | Query or prompt |
| `conversation_url` | Deep Search link if present |
| `summary` | Compact digest |
| `metadata_json` | Files, commits, diffs, sources |
| `created_by_attempt` | Board attempt reference |
| `created_at` | Timestamp |

### 9.2 `external_evidence_links`

| Field | Meaning |
|---|---|
| `id` | Link ID |
| `evidence_id` | External evidence record |
| `target_type` | `work_item`, `decision`, `prediction`, `incident`, `fix`, `change` |
| `target_id` | Target record ID |
| `link_role` | `informed`, `briefed`, `justified`, `evaluated_against` |
| `created_at` | Timestamp |

### 9.3 `subtree_briefs`

| Field | Meaning |
|---|---|
| `id` | Brief ID |
| `repo_ref` | Repository |
| `revision_ref` | Revision |
| `path_scope` | Subtree anchor |
| `source_evidence_ids_json` | Linked Sourcegraph evidence |
| `local_context_refs_json` | Decisions / incidents / fixes / predictions used |
| `brief_body` | Rendered brief |
| `generated_by_attempt` | Origin attempt |
| `created_at` | Timestamp |

These can remain derived or lightly persisted; they do not need to become a
second canonical knowledge base.

---

## 10. Board and daemon touchpoints

The integration sits naturally in the board/daemon model.

### Board-side

Work items that want enriched preparation should be able to declare:

- `context_requirements.sourcegraph = true`
- `context_requirements.path_scope = "src/auth"`
- `context_requirements.generate_subtree_brief = true`

### Daemon-side

A runtime that has Sourcegraph access can:

- gather MCP/API context
- create local evidence records
- request or generate the subtree brief
- attach the brief to attempt artifacts

This keeps Sourcegraph access capability-scoped and explicit.

---

## 11. Security and policy notes

1. **Respect existing repository permissions**
   The integration should never widen code access beyond what Sourcegraph and the
   local runtime already permit.

2. **Treat shared Deep Search links cautiously**
   If Sourcegraph conversation-sharing semantics are looser than repository
   permissions, the local system should store links with visibility warnings or
   avoid broad re-sharing by default.

3. **Do not infer person-level ranking from query behavior**
   The stored unit is evidence used for an object or change, not a user
   surveillance profile.

4. **Prefer bounded scope**
   Briefs should stay subtree-scoped rather than devolving into vague whole-repo
   essays.

---

## 12. Recommended implementation order

### Phase 1 — Thin retrieval adapter

- support Sourcegraph MCP/API calls for search, file reads, and history lookup
- normalize retrieved context into local evidence records

### Phase 2 — Subtree brief generation

- join Sourcegraph context with local decisions/incidents/fixes/predictions
- render a compact brief artifact for agents

### Phase 3 — Outcome linkage

- connect evidence records to proposals, changes, and later outcomes
- allow agents to inspect what prior search-informed moves held up

### Phase 4 — Optional UI / board surfacing

- show "brief available" on work items
- link search sessions and Deep Search conversations from attempt history

---

## 13. One-sentence summary

The integration should let Sourcegraph keep doing discovery while the local
system attaches durable, bounded, outcome-linked memory about what a team has
already learned around the code that was found.

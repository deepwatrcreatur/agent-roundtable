# 81 — Sourcegraph Thin Adapter Implementation

**Status:** `ready`
**Tag:** `[tools]`

## Goal

Implement the first thin Sourcegraph integration slice described in
`docs/design/SOURCEGRAPH_LINEAGE_INTEGRATION.md`: retrieve bounded Sourcegraph
context, normalize it into local evidence records, and make that context
available as an input to subtree-brief generation.

## Scope

- Implement a small Sourcegraph client layer using MCP and/or documented
  Sourcegraph APIs for:
  - semantic / natural-language search
  - keyword search
  - file reads
  - file listing
  - commit / diff history lookup
- Define and implement the first local record shape for imported Sourcegraph
  evidence, including:
  - repository
  - revision
  - path scope
  - query text
  - files read
  - conversation URL when Deep Search is used
- Support one bounded retrieval flow keyed by:
  - `repo`
  - `revision`
  - `path_scope`
- Make normalized Sourcegraph evidence available to the subtree-brief layer
  without trying to implement the full brief synthesis in the same item.
- Keep provenance visible so downstream consumers can inspect which searches,
  files, and revisions produced the context.

## Acceptance Criteria

- A concrete Sourcegraph client or adapter module exists in the implementation
  tree.
- The adapter can retrieve at least:
  - one search result set
  - one file body
  - one history-oriented result set (commit or diff search)
- A normalized local evidence structure exists matching the integration design
  note closely enough to preserve:
  - provider
  - retrieval mode
  - repo
  - revision
  - path scope
  - query
  - files read
- At least one documented or tested flow exists for:
  - request bounded Sourcegraph context
  - store or return normalized evidence
  - hand that evidence to a subtree-brief caller
- The implementation explicitly avoids:
  - shadow-indexing all Sourcegraph state
  - replacing Sourcegraph-native search UX

## Notes

- Primary design source: `docs/design/SOURCEGRAPH_LINEAGE_INTEGRATION.md`
- Prior round source: `docs/design/rounds/round-90-sourcegraph-deep-search-and-jj-lineage.md`
- This item is the first implementation slice only; richer brief synthesis and
  outcome linkage can follow separately.

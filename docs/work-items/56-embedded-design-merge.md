# 56 — Design History Integration (Embedded Model)

**Status:** `done` — **Owner:** `Codex`
**Tag:** `[structural]`

## Goal

Merge the design history from `agent-roundtable-design` into the main `agent-roundtable` repository to create a self-documenting product.

## Scope

- Import all content from `agent-roundtable-design` into `agent-roundtable/docs/design/`.
- Preserve the history of rounds and decisions.
- Update `BRIEF.md` and `ACTIVE_DISCUSSION.md` pointers to reflect the new paths.
- Remove the standalone `agent-roundtable-design` repository after the merge is verified.

## Acceptance Criteria

- Full design history is accessible within the `agent-roundtable` repo.
- No loss of information or satisfaction markers during the move.

## Notes

- Primary design sources:
  - `docs/design/rounds/round-63-embedded-design-memory.md`
  - `docs/design/ROUND_METADATA_INDEX.md`
- Closely related work:
  - `57-agent-task-queue.md`
  - `63-embedded-design-memory` round conclusions
  - `79-derived-round-index-and-resource-claims.md`

## Outcome

- Added
  [docs/design/EMBEDDED_DESIGN_HISTORY_MODEL.md](../design/EMBEDDED_DESIGN_HISTORY_MODEL.md)
  as the closure note for the embedded design-history model.
- Recorded that the repo already contains the embedded design corpus under
  `docs/design/` and that item 56 is no longer about a pending import.
- Clarified the mature split between:
  - canonical markdown archives
  - derived query/index layers
  - bounded near-code memory projections
  - board/task linkage
- Closed the item as a repo-structuring shift that has already been realized,
  with future work focused on retrieval, supersession, and browse surfaces
  rather than on a still-pending repository merge.

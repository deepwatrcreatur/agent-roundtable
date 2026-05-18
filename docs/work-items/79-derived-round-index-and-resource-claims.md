# 79 — Derived Round Index and Resource Claim Fields

**Status:** `ready`
**Tag:** `[structural]`

## Goal

Implement the next hybrid-storage step after Round 89: keep markdown rounds
canonical, but derive structured round metadata for query/search and extend the
board model with explicit resource-claim fields for contention control.

## Scope

- Define a structured extracted index for round metadata such as:
  - round number
  - title
  - tags
  - status
  - related rounds
- Keep markdown as the source of truth for round content.
- Add a design/schema update for board-side resource claim fields such as:
  - `contention_class`
  - `resource_scope`
  - `exclusive_lease_required`
- Ensure the derived index and board claim fields remain visibly subordinate to
  the markdown/archive layer rather than replacing it.

## Acceptance Criteria

- A documented extraction format exists for round metadata.
- Round tags can be queried without raw full-text scanning of every file.
- `BOARD_EXECUTION_MODEL.md` or related schema docs specify resource claim
  fields for live contention control.
- The design explicitly keeps:
  - markdown as canonical design memory
  - structured indices as derived query surfaces
  - board tables as operational enforcement state

## Notes

- Primary design source: `docs/design/rounds/round-89-markdown-canonical-derived-structure.md`
- Closely related rounds:
  - `round-73-deliberation-graph-index.md`
  - `round-74-natural-repo-knowledge-base.md`
  - `round-88-agent-resource-contention.md`


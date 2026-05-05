# 47 — Tag-Based Context Pruning

**Status:** `ready`

## Goal
Improve token efficiency by pruning agent context windows based on subject tag overlap.

## Scope
- Update `Roundtable.Prompt` to identify the subject tags of the current question.
- Implement a retrieval filter that prioritises prior turns with overlapping tags.
- Add "Global Invariant" tags (e.g., `#license`, `#architecture`) that are never pruned.
- Log context window efficiency (tokens saved vs. full history).

## Acceptance Criteria
- Agents receive a "Surgical History" relevant to the current topic.
- Drastic reduction in token usage for mature projects.
- "No Loss of Signal": ensure that cross-cutting concerns (Invariants) are always preserved.

# 38 — Revset Context Pruning

## Status: `blocked`
Depends on: #34 (JJ Integration), #05 (Prompt logic)

## Objective
Implement surgical context retrieval by using `jj`'s Revset query language to prune the context window to only relevant logical changes.

## Rationale
"Over-reading" is a major source of token waste. Instead of agents reading the entire design repository, the orchestrator should fetch only those logical fragments that intersect with the current intent. Revsets provide the precision needed for this optimization.

## Requirements
- [ ] Add `jj` Revset query support to `Roundtable.Vcs.Jujutsu`.
- [ ] Implement `Roundtable.Prompt.Pruner` which executes queries like `description("X") & ~conflicted` to find relevant logic fragments.
- [ ] Integrate Revset-based pruning into the `EvolutionAssembler`.
- [ ] Support metadata queries: prune context based on author, timestamp, or protocol markers.

## Verification
- [ ] Verify that context assembly only includes files and changes relevant to the specified Revset query.
- [ ] Assert that the orchestrator can correctly resolve complex Revset queries across a multi-fork graph.

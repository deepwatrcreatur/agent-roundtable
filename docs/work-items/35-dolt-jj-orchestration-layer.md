# 35 — Dolt-JJ Orchestration Layer

## Status: `done`
Owner: **Gemini**

## Objective
Create a Jido-powered logic shim that treats `jj` operations (code/mind) and `Dolt` operations (memory) as a single logical transaction.

## Rationale
To avoid the cost and complexity of forking the Dolt binary, we will achieve "JJ-Native" SQL semantics via an orchestration layer. This shim ensures that every change in the code evolution (`jj`) is mirrored by a corresponding update in the deliberation database (`Dolt`).

## Requirements
- [ ] Implement `Roundtable.Actions.UnifiedCommit` as a Jido action.
- [ ] Map `jj` Change IDs to `Dolt` metadata (using SQL `dolt_commit` properties).
- [ ] Ensure that `dolt push` and `jj git push` are coordinated to maintain remote consistency.
- [ ] Research and design the `Roundtable.Vcs.DoltBackend` for Jujutsu (long-term high-performance integration path).

## Verification
- [ ] Integration test: Perform a "Deliberative Turn" and verify that both a `jj` change and a `Dolt` row update are committed with matching metadata.
- [ ] Verify that a `jj undo` correctly triggers a compensating action in the Dolt database.

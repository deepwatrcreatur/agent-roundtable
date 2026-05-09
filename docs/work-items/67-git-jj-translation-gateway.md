# 67 — Git ↔ jj Translation Gateway

**Status:** `done`
**Tag:** `[structural]`

## Goal
Design the translation layer that lets a Forgejo/Git-shaped frontend coexist with a `jj`-native internal model.

## Scope
- Define how Git concepts map onto `jj` concepts:
  - refs / branches
  - pull requests / review state
  - commits / changesets
  - merge events / bookmark movement
- Make translation boundaries explicit so Vaglio internals can stay `jj`-first.
- Record provenance for translated operations so the system can explain what was native versus adapted from Git semantics.
- Identify lossy or dangerous edge cases early instead of hiding them behind compatibility glue.

## Acceptance Criteria
- Core repository operations have a documented, deterministic Git ↔ `jj` mapping.
- Failure modes and lossy cases are surfaced explicitly.
- The translation layer supports an evolutionary path away from Git-shaped internals instead of locking the product into them.

## Outcome
- Added `Roundtable.Translation.GitToJj` as the explicit Git-edge translation boundary.
- Shipped deterministic mappings for:
  - branch refs ↔ namespaced `jj` bookmarks
  - tag refs as read-only projections
  - commit SHAs → `jj` revset selectors
  - pull requests → change proposal envelopes
  - merge events → bookmark moves with surfaced lossy cases for squash/rebase
- Added focused translation tests and validated them plus the broader `test/roundtable` suite.

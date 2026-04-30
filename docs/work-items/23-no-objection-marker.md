# 23 — `[no objection]` Satisfaction Marker

**Status:** `done`
**Branch:** `main` (merged inline with Protocol Update 13 changes)

## Scope

Protocol Update 13 introduces a new satisfaction marker distinguishing
"no further evidence to add, not blocking closure" from active agreement.

## Changes

- `Satisfaction.parse_marker/1`: recognises `[no objection]` → label `"no-objection"`
- `Satisfaction.consensus?/1`: `no-objection` is non-blocking (does not prevent
  consensus, but does not count as positive satisfaction on its own)
- `RoundRun.@type satisfaction_result`: adds `:no_objection`
- `RoundRun.label_to_atom/1`: maps `"no-objection"` → `:no_objection`
- `Orchestrator.@label_conflicts`: `"no-objection"` conflicts with all other
  satisfaction labels (can only hold one at a time)
- `Orchestrator.satisfaction_to_label/1`: `:no_objection` → `"no-objection"`
- `Orchestrator.label_string_to_atom/1`: `"no-objection"` → `:no_objection`
- `CLI.infer_satisfaction/1`: recognises `"no-objection"` label
- `DiscussionLive.satisfaction_badge/1`: blue badge "· no objection"
- `DiscussionLive.border_color/1`: blue border for `:no_objection`

## Semantic

```
[satisfied]           → active agreement; counts toward consensus
[satisfied-conditional: <cond>] → agreement conditional on resolution
[no objection]        → exhausted arguments; not blocking; not positive agreement
[needs more evidence: <what>] → blocking; prevents consensus
```

DECISION.md flags consensus formed primarily from `[no objection]` entries
as "convergent but not robust" (documentation convention, not code enforcement).

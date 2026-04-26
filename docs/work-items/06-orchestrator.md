# 06 — Roundtable.Orchestrator

**Status:** `blocked` (needs 01–05)
**Assigned:** unassigned
**Branch:** `feat/orchestrator`

## Scope

The Jido Agent that runs the roundtable loop for a single question (GitHub
Issue). This is the `cmd/2` core of the system.

## State machine

```
:waiting → :round_in_progress → :ic_review → :satisfied | :needs_more_evidence
                                           → :ic_triage  → (retry or escalate)
                                           → :max_rounds → :needs_human_review
```

## cmd/2 contract

```elixir
# State in: %{issue: n, round: k, agents_pending: [...], responses: [...]}
# Returns:  {updated_state, [directives]}
#
# Directives emitted:
#   %PostIssueComment{...}
#   %SetIssueLabels{...}
#   %CloseIssue{...}
#   %ScheduleNextTurn{agent: :gemini, delay_ms: 0}
```

## Agent order per round

```
[:codex, :gemini, :claude_ic]
```

IC runs last to synthesise. If IC determines `[satisfied]`, emit `CloseIssue`.
If IC determines `[needs more evidence]`, emit `ScheduleNextTurn` for round + 1.

## Note

This module should be implemented by whoever is available after items 01–05
are merged. It is the integration point and should not be started until the
foundational pieces are stable.

# 12 — Explicit Phase State Machine in Roundtable.Orchestrator

**Status:** `done`
**Assigned:** GitHub Copilot
**Branch:** `feat/phase-machine`

## Scope

Refactor `Roundtable.Orchestrator` to replace the recursive `do_rounds/7` loop
with an explicit phase state machine. Each phase is a pure function that takes a
`RoundRun` and returns `{next_run, [effect]}`. Effects (gh calls, CLI
invocations) are applied separately, making phases testable and replay-safe.

## Why

The current recursive loop has implicit state (round number, satisfaction from
last fetch). It cannot be resumed from a persisted `RoundRun`, it does not
expose current phase to the LiveView dashboard, and it mixes side effects with
transition logic, making it hard to test.

## Phase Diagram

```
:awaiting_turns
  all expected speakers done → :triage_missing_markers
  max_rounds exceeded        → :needs_human_review (emit gh comment + label)

:triage_missing_markers
  all markers present        → :consensus_check
  IC triage resolves gap     → :consensus_check

:consensus_check
  all satisfied/conditional  → :closed (emit gh close)
  any needs-more-evidence    → :awaiting_turns (next round)
  max_rounds                 → :needs_human_review

:needs_human_input           (HITL interrupt — new)
  operator approve/dismiss   → resumes from suspended phase

:closed                      (terminal)
:needs_human_review          (terminal)
```

## Effect Types

```elixir
@type effect ::
  {:gh_comment, issue_number :: pos_integer(), body :: String.t()}
  | {:gh_label, issue_number :: pos_integer(), add :: [String.t()], remove :: [String.t()]}
  | {:gh_close, issue_number :: pos_integer(), comment :: String.t()}
  | {:run_agent, agent :: atom(), issue_number :: pos_integer()}
  | {:notify, event :: term()}
```

## Implementation Pattern

```elixir
defmodule Roundtable.Orchestrator do
  # Pure: computes next phase + effects from current state
  @spec step(RoundRun.t(), map(), keyword()) :: {RoundRun.t(), [effect()]}
  def step(run, issue, opts)

  # Impure: applies effects (gh calls, CLI invocations)
  @spec apply_effects([effect()], map()) :: :ok
  def apply_effects(effects, gh_config)

  # Entry point: load or create RoundRun, then loop
  @spec run_question(question(), String.t(), [atom()], pos_integer(), map(), keyword()) :: result()
  def run_question(question, brief, agents, max_rounds, gh_config, opts)
end
```

## Done When

- `step/3` is pure and fully unit-testable with no mocks (just fixture data)
- All current orchestrator behaviours are preserved (satisfaction detection,
  IC triage fallback, max rounds, label management)
- `RoundRun.phase` is updated on every transition and persisted via item 11
- LiveView dashboard can read `phase` from `RoundRun` (via `get_discussion_state`)
- Existing tests pass; new tests cover each phase transition with pure inputs

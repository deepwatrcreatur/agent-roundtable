# 11 — Roundtable.RoundRun (Persisted Round State)

**Status:** `done`
**Assigned:** GitHub Copilot
**Branch:** `feat/round-run`

## Scope

Implement `Roundtable.RoundRun` — the persisted state struct that tracks each
question's progress through the orchestrator. This is the durability layer that
Symphony/Temporal patterns identified as missing from v1.

## Why

The current orchestrator loses all in-progress state on crash. On restart, it
has no way to know which agents have already posted, which markers have been
parsed, or how many retries have occurred. `RoundRun` makes restart/recovery
tractable by keeping authoritative state that can be reconciled from GitHub on
boot.

## Data Model

```elixir
defmodule Roundtable.RoundRun do
  @type phase ::
    :awaiting_turns
    | :triage_missing_markers
    | :consensus_check
    | :needs_human_input
    | :closed
    | :needs_human_review

  @type t :: %__MODULE__{
    issue_number:       pos_integer(),
    phase:              phase(),
    expected_speakers:  [atom()],
    completed_speakers: [atom()],
    last_comment_ids:   [String.t()],
    satisfaction_map:   %{atom() => :satisfied | :satisfied_conditional | :needs_more_evidence},
    retry_count:        non_neg_integer(),
    updated_at:         DateTime.t()
  }

  defstruct [
    :issue_number, :phase, :expected_speakers, :completed_speakers,
    :last_comment_ids, :satisfaction_map, :retry_count, :updated_at
  ]
end
```

## Persistence

- **Hot:** ETS table `:roundtable_round_runs`, keyed by `issue_number`.
- **Durable:** Flush to `state/round_run_<issue_number>.json` in the repo root
  on every phase transition. This file is git-tracked so it survives process
  restarts.
- **Reconciliation on boot:** `RoundRun.reconcile_from_github/2` — calls
  `Gh.view_issue/3` with `[:comments, :labels, :state]`, rebuilds
  `completed_speakers` from comment authorship, re-parses satisfaction markers,
  sets phase from current label state. Returns `{:ok, t()} | {:error, reason}`.

## Interface

```elixir
defmodule Roundtable.RoundRun do
  @spec new(pos_integer(), [atom()]) :: t()
  @spec reconcile_from_github(pos_integer(), map()) :: {:ok, t()} | {:error, term()}
  @spec put_phase(t(), phase()) :: t()
  @spec mark_speaker_done(t(), atom(), atom()) :: t()
  @spec persist(t()) :: :ok | {:error, term()}
  @spec load(pos_integer()) :: {:ok, t()} | {:error, :not_found}
end
```

## Done When

- Struct defined with all fields
- ETS-backed hot store with `persist/1` and `load/1`
- `reconcile_from_github/2` rebuilds correct state from live GitHub data
- JSON flush to `state/` directory works; files are parseable on next boot
- Unit tests cover: new, persist+load round-trip, reconcile from fixture data,
  phase transitions

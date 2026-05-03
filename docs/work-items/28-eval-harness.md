# 28 — Eval Harness: `Vaglio.Eval` + `Vaglio.Eval.Run`

**Status:** `done` (Gemini)
**Source:** Q37 (Round 22)

## Scope

Core eval infrastructure: the `Vaglio.Eval` module and `Vaglio.Eval.Run` struct
that run the same question through vaglio mode (full multi-agent protocol) and
single-model baselines, capturing all intermediate state.

## Implementation

### `Vaglio.Eval.Run` struct

```elixir
defmodule Vaglio.Eval.Run do
  defstruct [
    :id,            # unique eval run ID
    :question,      # the question text
    :brief_context, # BRIEF.md excerpt or full context provided
    :mode,          # :vaglio | :single_naive | :single_structured | :single_debate
    :model,         # primary model used (for single modes)
    :turns,         # list of maps — each agent turn's raw output
    :final_output,  # the synthesised final output text
    :metrics,       # map of computed metrics (populated by Vaglio.Eval.Metrics)
    :tokens_used,   # total tokens consumed (input + output)
    :cost_usd,      # estimated cost in USD
    :started_at,
    :completed_at
  ]
end
```

### `Vaglio.Eval` module

```elixir
defmodule Vaglio.Eval do
  @doc "Run a question through the full vaglio protocol. Returns Eval.Run."
  def run_vaglio(question, brief_context, opts \\ [])

  @doc "Run through a single model. mode: :naive | :structured | :debate"
  def run_single(question, brief_context, mode, opts \\ [])

  @doc "Persist an Eval.Run to state/eval/ as JSON."
  def persist(run)

  @doc "Load a persisted Eval.Run by ID."
  def load(id)

  @doc "List all persisted eval runs."
  def list()
end
```

### Single-model prompts

- **Naive:** `"Answer the following question:\n\n#{question}\n\nContext:\n#{brief_context}"`
- **Structured:** Same question + full vaglio prompt instructions (satisfaction
  markers, typed provenance `[observed]`/`[inferred]`/`[testimony]`, premise
  challenge, warrant requirements, unique contribution appendix)
- **Self-debate:** `"Generate three distinct perspectives on the following
  question, then synthesize them into a single recommendation with satisfaction
  markers.\n\n#{question}\n\nContext:\n#{brief_context}"`

### Vaglio mode

Use the existing `Orchestrator` infrastructure to run a full round. Capture
each agent turn and IC synthesis as entries in `turns`. The `final_output` is
the IC synthesis text.

### Persistence

Store as JSON in `state/eval/run_<id>.json`. Same pattern as `RoundRun`
persistence.

## Dependencies

- `RunCliAgent` (existing)
- `Orchestrator` (existing, for vaglio mode)
- `Jason` (existing dep)

## Acceptance criteria

- `Vaglio.Eval.run_vaglio/3` runs a full round and returns a populated `Run`
- `Vaglio.Eval.run_single/4` runs each of the three baseline modes
- All runs are persisted and loadable
- Token counts and cost estimates are captured

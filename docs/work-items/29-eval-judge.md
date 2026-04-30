# 29 — LLM-as-Judge: `Vaglio.Eval.Judge` + `Vaglio.Eval.Metrics`

**Status:** `ready`
**Assigned:** Gemini
**Source:** Q37 (Round 22)

## Scope

Automated metrics extraction using an LLM judge. The judge model extracts
structured data from eval run outputs for comparison.

## Implementation

### `Vaglio.Eval.Judge`

```elixir
defmodule Vaglio.Eval.Judge do
  @doc """
  Extract unique considerations from output text.
  Returns a list of %{claim: String.t(), provenance: atom(), agent: atom() | nil}
  """
  def extract_considerations(text, opts \\ [])

  @doc """
  Check for internal contradictions.
  Returns %{consistent: boolean(), contradictions: [String.t()]}
  """
  def check_consistency(text, opts \\ [])

  @doc """
  Count explicit disagreements or counter-considerations.
  Returns %{dissent_count: non_neg_integer(), examples: [String.t()]}
  """
  def count_dissent(text, opts \\ [])
end
```

### Judge model selection

Use Claude via `RunCliAgent` with `:claude` in a separate context. The judge
prompt must not reveal whether the text is from vaglio or single-model mode.

Judge prompts should be deterministic: same text → same extraction. Include
structured output format instructions (JSON) in the judge prompt.

### `Vaglio.Eval.Metrics`

```elixir
defmodule Vaglio.Eval.Metrics do
  @doc """
  Compute all metrics for an eval run, populating run.metrics.

  Metrics map:
  %{
    consideration_count: integer(),
    unique_considerations: integer(),
    self_consistent: boolean(),
    contradiction_count: integer(),
    dissent_count: integer(),
    diversity_ratio: float(),  # unique-to-one-agent / total (vaglio only)
    tokens_used: integer(),
    cost_usd: float(),
    cost_ratio: float()  # relative to baseline (computed across runs)
  }
  """
  def compute(run)

  @doc "Compare metrics across a list of runs for the same question."
  def compare(runs)
end
```

### Diversity ratio (vaglio mode only)

For vaglio runs where `turns` contains per-agent data: tag each consideration
by which agent raised it. `diversity_ratio` = considerations raised by exactly
one agent / total considerations. High ratio = agents are contributing unique
perspectives.

## Dependencies

- `RunCliAgent` (for judge model calls)
- Item 28 (`Vaglio.Eval.Run` struct)

## Acceptance criteria

- `extract_considerations/2` returns structured list from arbitrary text
- `check_consistency/2` detects contradictions in test inputs
- `count_dissent/2` counts counter-arguments in multi-agent output
- `Metrics.compute/1` populates all metrics fields on a Run
- `Metrics.compare/1` produces a comparison table across modes

# 31 — Blind Comparison Interface

**Status:** `done`
**Assigned:** Codex
**Source:** Q37 (Round 22)

## Scope

A mechanism for presenting vaglio vs. single-model outputs side-by-side to the
owner without revealing which is which. This is the gold metric (blind
preference).

## Options

### Option A: File-based (minimal)

`Vaglio.Eval.blind_compare/1` writes two files to a temp directory:

```
state/eval/blind/<task_id>/
  output_a.md
  output_b.md
  manifest.json  # maps A/B to mode; owner reads only after judging
```

Assignment is randomised (coin flip for which output is A vs B). The owner
reads both files, records preference ("A" or "B"), then checks `manifest.json`
to see which was vaglio.

Pros: zero UI work, works today.
Cons: manual, no structured recording of judgments.

### Option B: LiveView page (richer)

Add a `/eval/compare/:task_id` route to the existing LiveView dashboard:

- Two columns showing output A and output B (randomised assignment)
- "Prefer A" / "Prefer B" / "No preference" buttons
- Optional text field for qualitative notes
- On submit: records preference to `state/eval/judgments/`
- Reveal button after submission shows which was vaglio

Pros: structured data collection, better UX, reusable.
Cons: requires LiveView work (item 10 extension).

## Recommendation

Start with Option A (file-based). Add Option B as a LiveView extension only
if the owner plans to run evals regularly.

## Implementation (Option A)

```elixir
defmodule Vaglio.Eval do
  @doc """
  Write blind comparison files for a pair of runs on the same question.
  Returns the output directory path.
  """
  def blind_compare(vaglio_run, single_run) do
    # Randomise assignment
    {a, b} = if :rand.uniform() > 0.5,
      do: {vaglio_run, single_run},
      else: {single_run, vaglio_run}

    dir = Path.join(state_dir(), "blind/#{vaglio_run.id}")
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "output_a.md"), a.final_output)
    File.write!(Path.join(dir, "output_b.md"), b.final_output)
    File.write!(Path.join(dir, "manifest.json"),
      Jason.encode!(%{a: a.mode, b: b.mode}, pretty: true))

    {:ok, dir}
  end
end
```

## Acceptance criteria

- Blind comparison files generated with randomised assignment
- Manifest reveals mode only after owner has read outputs
- Works with any pair of `Eval.Run` structs for the same question

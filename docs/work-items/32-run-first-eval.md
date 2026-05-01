# 32 — Run First Eval Batch + Report

**Status:** `in-progress` (Gemini)
**Assigned:** Gemini
**Source:** Q37 (Round 22)

## Scope

Execute the first evaluation batch: 6 tasks × vaglio vs. protocol-structured
single. Produce a report with metrics and blind preference results.

## Phased execution

### Phase 1: First 6 tasks (vaglio vs. structured single)

1. Select 6 tasks from the 12-task set (item 30): 3 replayed + 2 synthetic + 1
   code review
2. For each task, run:
   - `Vaglio.Eval.run_vaglio(question, context)`
   - `Vaglio.Eval.run_single(question, context, :structured)`
3. Compute metrics via `Vaglio.Eval.Metrics.compute/1`
4. Generate blind comparison files via `Vaglio.Eval.blind_compare/2`
5. Owner reads blind comparisons and records preferences

### Phase 2: Decision point

After 6 tasks:
- If 5/6 or 6/6 concordant preference for vaglio: **strong signal**. Optionally
  expand to full 12 tasks and add naive + self-debate baselines.
- If 4/6 or weaker: **expand** to remaining 6 tasks for full 12-task set.
- If 3/3 or worse for single-model: **significant finding**. Report and
  reconsider multi-agent architecture.

### Phase 3 (conditional): Full baselines

If warranted by Phase 2, run all 12 tasks × all 4 modes (vaglio, naive,
structured, self-debate). Produces 48 total runs. Friedman test across
conditions.

## Report format

```markdown
# Vaglio Eval Report — Batch 1

## Summary
- Tasks: N
- Modes compared: vaglio vs. [baseline]
- Blind preference: X/N vaglio, Y/N single, Z/N no preference

## Metrics comparison

| Metric | Vaglio (mean) | Single (mean) | Ratio |
|---|---|---|---|
| Considerations | ... | ... | ... |
| Dissent count | ... | ... | ... |
| Self-consistent | ... | ... | ... |
| Cost (USD) | ... | ... | ... |
| Diversity ratio | ... | n/a | ... |

## Per-task results
[table of per-task metrics and preference]

## Hypothesis assessment
- H1 (coverage 1.5-3x): [confirmed/falsified]
- H2 (≥40% unique): [confirmed/falsified]
- H3 (preference ≥7/12): [confirmed/falsified/insufficient data]
- H-null: [confirmed/falsified]

## Recommendation
[Continue with vaglio / Ship structured prompt / Revise roster / ...]
```

## Budget

- 6 tasks × vaglio (~$0.50 each) = $3.00
- 6 tasks × structured single (~$0.12 each) = $0.72
- Judge calls (~$0.05 each × 12 runs × 3 metrics) = $1.80
- **Total Phase 1: ~$5.50**

## Acceptance criteria

- All 6 tasks run in both modes
- Metrics computed and persisted
- Blind comparison files generated
- Owner preferences recorded
- Report generated with hypothesis assessment

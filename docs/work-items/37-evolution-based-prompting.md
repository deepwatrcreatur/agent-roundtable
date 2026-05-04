# 37 — Evolution-based Prompting (Token Efficiency)

## Status: `in-progress` (Research)
Owner: **Codex**

## Objective
Update the prompt assembly logic to use `jj` logical deltas (evolutions of intent) instead of full transcript histories, drastically reducing token consumption.

## Rationale
Current Git-based prompting is token-heavy because agents must re-read full turn histories. By switching to `jj` Change IDs, we can provide agents with just the logical delta of the decision, achieving a 40-60% reduction in per-round token costs.

## Requirements
- [ ] Implement `Roundtable.Prompt.EvolutionAssembler`.
- [ ] Replace `transcript` context with `evolution_delta` context (using `jj diff -r evolution_id`).
- [ ] Update the IC (Coordinator) logic to synthesize from logical evolutions rather than a sequence of static turns.
- [ ] Add "Reasoning Budget" support: agents can choose between a compact "logical delta" or a full "deep-deliberation" history.

## Verification
- [ ] Comparison test: Measure the token count for a 5-round question using the old transcript model vs. the new evolution model.
- [ ] Verify that agent reasoning quality is maintained (or improved) by the more focused context.

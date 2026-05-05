# 59 — Isolated Testing Sandbox

**Status:** `ready`
**Tag:** `[tools]`

## Goal
Implement a testing strategy using an isolated repository to prevent product state contamination.

## Scope
- Initialize a `vaglio-test-sandbox` repository.
- Configure the Orchestrator to run "Toy Design" jobs against this repo.
- Use low-cost OpenRouter models (DeepSeek-V3) for validation.
- Automate "Round-Trip" tests: Prompt -> Deliberation -> Consensus -> Merge.

## Acceptance Criteria
- Full protocol verification without affecting the main `vaglio` repo history.
- Cost-per-test-run is minimized to < $0.05.

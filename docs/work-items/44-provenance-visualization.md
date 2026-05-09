# 44 — Claim Basis & Provenance Badging

**Status:** `done` — **GitHub Copilot**

## Goal
Surface the "Appraisal Value" of findings by grounding them in observed reality vs. pure inference.

## Scope
- Parse `[observed]`, `[testimony]`, and `[inferred]` tags from agent responses.
- Implement UI badges for these types next to factual claims.
- Create an "Evidence Map" that links `[observed]` claims to the specific command output or file read that produced them.
- Visualise the "Epistemic Chain": Inferred Claim -> Testimony -> Observed Fact.

## Acceptance Criteria
- Claims in the WebUI are color-coded or badged by provenance.
- Clicking a Badge reveals the raw "Observation" data.

## Outcome
- Added `Roundtable.ProvenanceMap` to parse `[observed: ...]`, `[testimony: ...]`, and `[inferred: ...]` tags from transcript turns into claims, an evidence map, and an epistemic chain.
- Extended `DiscussionLive` so transcript turns show provenance badges whose disclosure panels reveal the raw supporting source text.
- Added question-level provenance counts plus per-question `Evidence Map` and `Epistemic Chain` views, and updated prompts so future turns can emit the provenance tags consistently.

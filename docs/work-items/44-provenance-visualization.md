# 44 — Claim Basis & Provenance Badging

**Status:** `in-progress` — **GitHub Copilot** — `/tmp/agent-roundtable-item44-147790`

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

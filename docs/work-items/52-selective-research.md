# 52 — Selective Web Research (Browserbase)

**Status:** `ready`
**Tag:** `[tools]`

## Goal
Enable agents to perform high-fidelity web research without triggering anti-bot flags.

## Scope
- Integrate Browserbase API for "Research Turns" (e.g., extracting social metadata from the web).
- Implement a "Cloud vs. Local" selector: Use local Curl for APIs; Browserbase for SPAs.
- Store research "Snapshots" in the Vaglio transcript for provenance audit.

## Acceptance Criteria
- Agents can successfully navigate JS-heavy sites (LinkedIn/X) to perform SNA.
- Research costs are bounded by the free tier usage limits.

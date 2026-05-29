# 52 — Selective Web Research (Browserbase)

**Status:** `done` — **Owner:** `Codex`
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

## Notes

- Primary design sources:
  - `docs/design/rounds/round-115-exa-search-fit-and-guide-integration.md`
  - `docs/design/rounds/historical-synthesis.md`
- Closely related work:
  - `51-proxy-and-cache.md`
  - `80-sourcegraph-lineage-integration-briefs.md`
  - `81-sourcegraph-thin-adapter-implementation.md`

## Outcome

- Added
  [docs/design/SELECTIVE_RESEARCH_CONTRACT.md](../design/SELECTIVE_RESEARCH_CONTRACT.md)
  as the layered research/retrieval contract note.
- Defined the maintained research cascade:
  - repo-local / code-host-native retrieval first
  - direct known-URL fetch second
  - premium open-web discovery third
  - browser automation last
- Reframed Browserbase-like tooling as the JS-heavy / interaction-dependent
  escalation tier rather than the default answer to web research.
- Defined `ResearchSnapshot` as the provenance anchor so selective research
  returns inspectable sources rather than only provider synthesis.
- Connected research-tier choice to budget discipline and reason-coded
  escalation instead of ambient search-provider use.

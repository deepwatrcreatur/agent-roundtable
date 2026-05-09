# 68 — Public Repo Import & Investor Demo

**Status:** `ready`
**Tag:** `[market]`

## Goal
Build the minimum investor-facing prototype flow: import large public repositories, run Vaglio analysis, and present dashboards that make the product legible in a short demo.

## Scope
- Select a small set of large public repositories that demonstrate different maintenance patterns.
- Ingest those repositories into the prototype without requiring bespoke one-off steps.
- Generate high-signal dashboards or reports such as:
  - maintainer concentration
  - contributor expertise signals
  - subsystem hotspots
  - provenance / deliberation overlays
- Optimize the flow enough that the prototype feels like a product demo, not a manual consulting exercise.

## Acceptance Criteria
- At least two substantial public repositories can be imported end-to-end.
- The resulting dashboards are coherent enough for an investor demo.
- The demo path reinforces Vaglio's product narrative rather than looking like generic repo analytics.

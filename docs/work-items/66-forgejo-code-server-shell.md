# 66 — Forgejo-Based Code Server Shell

**Status:** `ready`
**Tag:** `[product]`

## Goal
Stand up a Vaglio "code server" prototype that reuses Forgejo where it genuinely helps, while preserving a clean boundary for Vaglio-native analysis and deliberation surfaces.

## Scope
- Identify which Forgejo capabilities can be reused directly for the prototype:
  - repository browsing
  - user/session management
  - web UI chrome
  - webhook/event entry points
- Define the extension seam where Vaglio-specific dashboards and deliberation views attach.
- Avoid a hard fork of Forgejo core logic where an adapter or sidecar boundary is sufficient.
- Produce a deployable prototype slice that can import a public repository and expose at least one Vaglio-native analysis surface from the same host.

## Acceptance Criteria
- A clear prototype architecture exists with explicit "reuse vs replace" boundaries.
- The prototype can present a public repo through a Forgejo-based surface and link into Vaglio analysis views.
- The chosen boundary does not assume Git must remain the long-term internal source of truth.

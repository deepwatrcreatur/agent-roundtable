# 87 — Safe-by-Default Cache Trust Boundaries

**Status:** `done` — **Claude Code**
**Tag:** `[security]`

## Goal

Design the cache-isolation model for a successor forge so untrusted contribution
paths cannot poison caches later consumed by higher-trust branches, environments,
or release workflows.

## Scope

- Define cache trust boundaries across at least:
  - repository
  - branch / ref
  - trust tier
  - workflow / environment class
- Define which cache-sharing paths are allowed by default and which require
  explicit opt-in.
- Ensure the default model is safe against cross-branch poisoning in
  Mini-Shai-Hulud-style attack chains.
- Preserve explicit escape hatches for teams that intentionally want broader
  sharing, but make those settings visible and auditable.

## Acceptance Criteria

- A concrete design note exists for cache trust-boundary policy.
- The default design prevents untrusted or lower-trust branches from silently
  poisoning higher-trust cache consumers.
- The design includes explicit, auditable opt-in paths for broader cache sharing.
- The design ties cache scope to trust-tier concepts, not only raw repository
  identity.

## Notes

- Primary design source:
  `docs/design/rounds/round-101-depot-blacksmith-vs-github-and-others.md`
- Closely related work:
  - `86-untrusted-contribution-trust-tiers.md`
  - `84-release-event-and-publish-authority-separation.md`

# 91 — Maintainer Activity and Promotion Surface

**Status:** `ready`
**Tag:** `[product]`

## Goal

Design the smallest maintainer-facing UX that makes cooperative agent work
legible and governable without requiring operators to become orchestration
experts.

## Scope

- Define a single repo-level surface showing:
  - active claims
  - active leases
  - current attempts
  - blocked/conflicting work
  - items awaiting review/promotion
- Define the maintainer interaction model for:
  - approving or rejecting promotion
  - seeing who currently owns a task/resource
  - noticing stale or conflicting claims
  - understanding supersession lineage
- Keep the UX aligned with familiar forge concepts such as issues, PRs, branch
  protection, and activity feeds rather than inventing a separate orchestration
  console.
- Use progressive disclosure so advanced coordination details remain available
  without dominating the default path.

## Acceptance Criteria

- A concrete design note exists for a calm maintainer activity/promotion surface.
- The design shows how ordinary maintainers can benefit without learning lease
  internals first.
- The UI model clearly distinguishes:
  - draft/attempt work
  - proposed work
  - reviewed work
  - promoted/publishable work
- The design keeps human merge/promotion authority explicit.

## Notes

- Primary design source:
  `docs/design/rounds/round-117-forge-native-agent-coordination-boundary.md`
- Closely related work:
  - `10-web-dashboard.md`
  - `79-derived-round-index-and-resource-claims.md`
  - `88-zero-config-trusted-publishing-ux.md`

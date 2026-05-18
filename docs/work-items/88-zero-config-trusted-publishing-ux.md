# 88 — Zero-Config Trusted Publishing UX

**Status:** `ready`
**Tag:** `[product]`

## Goal

Design the smallest possible user-facing trusted-publishing workflow for a
successor forge so ordinary maintainers get the benefits of release-authority
separation without having to learn a large new security surface.

## Scope

- Define the default publishing UX for:
  - solo maintainers
  - small teams
  - larger teams that later need more policy depth
- Ensure the first-publish and ordinary-release path minimizes:
  - token management
  - policy writing
  - identity plumbing
  - ceremony around trust tiers
- Define what the host manages automatically versus what users must explicitly
  configure.
- Preserve a migration path from current GitHub/npm-style workflows without
  requiring an immediate re-architecture.

## Acceptance Criteria

- A concrete design note exists for low-friction trusted publishing UX.
- The design shows how release-authority separation can be mostly invisible for
  simple projects.
- The design includes progressive disclosure: more policy depth only when teams
  actually need it.
- The design explicitly avoids reproducing npm's recent retrofit pain as a new
  onboarding tax.

## Notes

- Primary design source:
  `docs/design/rounds/round-102-security-dx-tradeoffs-clean-break-forge.md`
- Closely related work:
  - `83-hosted-analysis-release-gate.md`
  - `84-release-event-and-publish-authority-separation.md`
  - `86-untrusted-contribution-trust-tiers.md`

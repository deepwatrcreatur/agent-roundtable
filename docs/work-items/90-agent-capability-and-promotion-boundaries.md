# 90 — Agent Capability and Promotion Boundaries

**Status:** `done`
**Tag:** `[security]`

## Goal

Design the host-native authority model for coding agents so agent identities are
scoped, auditable, and unable to casually cross from ordinary code work into
publish-capable or high-sensitivity operations.

## Scope

- Define forge-side agent identity and capability profile fields such as:
  - agent identity
  - owning user/org
  - allowed repo/path/resource scopes
  - allowed action classes
  - promotion authority level
- Define how agent identity binds to:
  - claims
  - leases
  - attempts
  - review / promotion actions
- Define how ordinary coding attempts are prevented from implicitly gaining
  publish or protected-resource authority.
- Connect the design to earlier release-authority and trust-tier work without
  duplicating their whole scope.

## Acceptance Criteria

- A concrete design note exists for scoped agent identities and capability
  boundaries.
- The design clearly separates:
  - code mutation authority
  - review/propose authority
  - promotion/publish authority
- The design includes revocation / expiry expectations for agent credentials or
  sessions.
- The design explicitly improves blast-radius control relative to broad
  workstation or token authority.

## Notes

- Primary design source:
  `docs/design/rounds/round-117-forge-native-agent-coordination-boundary.md`
- Closely related work:
  - `84-release-event-and-publish-authority-separation.md`
  - `86-untrusted-contribution-trust-tiers.md`
  - `88-zero-config-trusted-publishing-ux.md`

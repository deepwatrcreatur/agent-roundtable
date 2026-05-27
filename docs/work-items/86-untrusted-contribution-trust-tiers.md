# 86 — Untrusted Contribution Trust Tiers

**Status:** `done` — **Claude Code**
**Tag:** `[security]`

## Goal

Design the trust-tier model for untrusted contributions so forked PRs and other
low-trust execution paths cannot casually cross into protected caches, secrets,
trusted runners, or publish-capable release contexts.

## Scope

- Define host-native trust tiers for execution contexts such as:
  - untrusted external contribution
  - reviewed but not release-capable CI
  - protected release preparation
  - trusted publish/promotion
- Define what each tier can and cannot access:
  - secrets
  - OIDC or workload identity
  - caches
  - runners
  - protected environments
  - registries
- Define the allowed promotion paths between tiers and the approvals/checks
  required at each transition.
- Keep the model compatible with earlier work on release-authority separation.

## Acceptance Criteria

- A concrete design note exists for CI trust tiers and transition rules.
- The design includes explicit prohibitions on untrusted access to:
  - parent/project secrets
  - protected caches
  - publish-capable identity
  - trusted long-lived runners
- The design specifies how a higher-trust release context is entered and audited.
- The design clearly distinguishes untrusted CI success from release eligibility.

## Notes

- Primary design source:
  `docs/design/rounds/round-100-alternative-ci-provider-security-models.md`
- Closely related work:
  - `84-release-event-and-publish-authority-separation.md`
  - `83-hosted-analysis-release-gate.md`

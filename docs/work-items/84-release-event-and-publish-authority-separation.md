# 84 — Release Event and Publish Authority Separation

**Status:** `ready`
**Tag:** `[integrity]`

## Goal

Design a host-native release primitive that separates:

- build execution
- publish authority
- final release promotion

so a compromised CI job cannot implicitly publish as the trusted project identity
just because it ran inside the right workflow context.

## Scope

- Define a first-class host release event distinct from generic CI success.
- Define how release intent binds to:
  - reviewed change identities
  - explicit publish manifests
  - approval chains
  - target registries / packages
- Define how publish authority is brokered separately from ordinary build
  execution.
- Define how provenance records approval and promotion context in addition to
  build identity.
- Consider how immutable `jj` lineage can strengthen release binding and replay.

## Acceptance Criteria

- A concrete design note exists for separating build, publish, and promotion.
- The design includes a host-brokered publish authority model.
- The design explains how compromised CI execution is prevented from directly
  implying trusted release.
- The design includes a provenance shape that records approval/promotion context.

## Notes

- Primary design source:
  `docs/design/rounds/round-99-mini-shai-hulud-jj-hosting-vs-ecosystem.md`
- Closely related work:
  - `83-hosted-analysis-release-gate.md`
  - `61-slsa-attestation-hooks.md`

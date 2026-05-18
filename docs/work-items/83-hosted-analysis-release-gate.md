# 83 — Hosted Analysis Release Gate

**Status:** `ready`
**Tag:** `[integrity]`

## Goal

Design the host-owned release-gate and exception model for dangerous-code
analysis so outside providers can contribute findings without becoming the final
authority over merge/release decisions.

## Scope

- Define the host-enforced policy layer for analysis-driven merge/release gates:
  - required checks
  - severity thresholds
  - waiver / exception flow
  - suppressions
  - re-run / revalidation triggers
- Define how the gate consumes normalized findings from:
  - first-party hosted analyzers
  - self-hosted analyzers
  - third-party providers
- Define the canonical audit trail for:
  - who waived what
  - why
  - against which evidence
  - at which revision
- Define how gate state links to later incidents, regressions, or vindicated
  exceptions.

## Acceptance Criteria

- A concrete design note exists for host-owned dangerous-code release gating.
- The design makes clear that outside analyzers contribute evidence, not final
  authority.
- The design includes an exception / waiver model with durable provenance.
- The design links gate decisions to later outcomes so provider and policy
  quality can be evaluated over time.

## Notes

- Primary design source:
  `docs/design/rounds/round-98-hosted-analysis-agents-vs-skills-marketplace.md`
- Closely related work:
  - `82-hosted-analysis-provider-contract.md`
  - `77-jj-prediction-calibration-protocol.md`
  - `80-sourcegraph-lineage-integration-briefs.md`

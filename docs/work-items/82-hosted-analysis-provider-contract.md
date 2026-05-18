# 82 — Hosted Analysis Provider Contract

**Status:** `ready`
**Tag:** `[product]`

## Goal

Define the host-owned contract by which first-party, self-hosted, and third-party
analysis engines can submit dangerous-code findings, experiments, and verdicts
into the successor forge's canonical memory and review surface.

## Scope

- Define the normalized artifact schema for external or pluggable analysis
  providers, including records for:
  - findings
  - severity / confidence
  - taxonomy / classifier output
  - experiment / reproducer metadata
  - tool/runtime configuration
  - remediation proposals
  - verification outcomes
- Define provider identity, provenance, attestation, and replay requirements.
- Define how provider results attach to:
  - repo
  - revision / branch / PR
  - path scope
  - prior findings
  - waivers / suppressions
  - later outcomes
- Keep the contract broad enough for:
  - unsafe-code classification engines
  - UB-hunting engines
  - other future specialist analyzers

## Acceptance Criteria

- A concrete design note exists for a host-owned provider contract.
- The design includes a normalized evidence shape suitable for ingesting external
  analysis results into lineage-aware project memory.
- The design specifies minimum provenance / replay / attestation expectations.
- The design distinguishes:
  - provider execution
  - host-owned canonical storage and review state

## Notes

- Primary design source:
  `docs/design/rounds/round-98-hosted-analysis-agents-vs-skills-marketplace.md`
- This item is about the provider/evidence interface, not the final release gate.

# 85 — Package Quarantine and Revocation Graph

**Status:** `done` — **Claude Code**
**Tag:** `[security]`

## Goal

Design the host-and-ecosystem coordination layer for rapidly quarantining,
revoking, and tracing malicious package releases once a trusted pipeline or
publisher has been compromised.

## Scope

- Define a machine-readable quarantine / revocation graph linking:
  - compromised releases
  - affected repos
  - registries
  - downstream packages
  - waivers / overrides
  - later clean replacement releases
- Define host-native views and APIs for:
  - suspicious release surfacing
  - blast-radius mapping
  - downstream notification
  - rollback guidance
- Define what data the host can provide to registries/package managers for
  faster containment.
- Preserve lineage and forensic value rather than only allowing hard deletion.

## Acceptance Criteria

- A concrete design note exists for quarantine/revocation graph handling.
- The design links host-side lineage and release data to ecosystem-side package
  containment.
- The design includes downstream notification and blast-radius mapping concepts.
- The design preserves durable incident/forensic records even when packages are
  quarantined or revoked.

## Notes

- Primary design source:
  `docs/design/rounds/round-99-mini-shai-hulud-jj-hosting-vs-ecosystem.md`
- This item is intentionally cross-boundary: host and package ecosystem both have
  responsibilities here.

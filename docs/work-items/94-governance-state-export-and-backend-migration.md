# 94 — Governance State Export and Backend Migration

**Status:** `ready`
**Tag:** `[integrity]`

## Goal

Define export and migration semantics for governance/control-plane state so a
customer can change backend providers without losing the authoritative history
of decisions, supersession, review state, and promotion outcomes.

## Scope

- Define which governance objects must be exportable and restorable across
  backend changes.
- Specify the minimum portable package for migration, including:
  - host-side coordination state snapshots
  - repo-linked durable artifacts
  - identity / authority references
  - attempt / supersession / decision history
- Distinguish:
  - what must migrate losslessly
  - what may be recomputed or re-indexed
  - what is backend-local operational residue and can be dropped
- Define how migration preserves:
  - auditability
  - human promotion history
  - relationship to repo-local memory
  - continuity of maintainer understanding
- Keep the design compatible with multi-backend support rather than a one-time
  “exit plan” from a single provider.

## Acceptance Criteria

- A concrete migration/export design exists for the governance layer.
- The design identifies the canonical portable artifacts that prevent provider
  lock-in.
- The migration story clearly preserves decision lineage and promotion history.
- The design distinguishes lossless migration requirements from rederived views
  and backend-local residue.

## Notes

- Primary design source:
  `docs/design/rounds/round-120-backend-substrate-vs-governance-startup-boundary.md`
- Closely related work:
  - `79-derived-round-index-and-resource-claims.md`
  - `84-release-event-and-publish-authority-separation.md`
  - `92-canonical-governance-object-model.md`

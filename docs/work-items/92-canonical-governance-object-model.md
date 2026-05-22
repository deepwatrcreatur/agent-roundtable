# 92 — Canonical Governance Object Model

**Status:** `done` — **Codex**
**Tag:** `[structural]`

## Goal

Define the startup-owned canonical object model for the governance/control plane
so the product's core truth does not collapse into provider-native branches,
events, or workflow artifacts.

## Scope

- Define the canonical fields and relationships for:
  - `Claim`
  - `Lease`
  - `Attempt`
  - `Supersession`
  - `ReviewState`
  - `PromotionGate`
  - `AuthorityScope`
  - `DecisionRecord`
- Distinguish which objects are:
  - host-side live coordination state
  - repo-local durable artifacts
  - derived or indexed views
- Define how these objects relate to:
  - repository refs / changes
  - local worktrees / workspaces
  - maintainer actions
  - promotion outcomes
- Keep the model compatible with both Git-backed and `jj`-backed local mutation
  flows.

## Acceptance Criteria

- A concrete design note exists for the canonical governance objects, their core
  fields, and their relationships.
- The design makes it clear which objects are authoritative host-side state and
  which belong in repo-portable memory.
- The model avoids requiring provider-native concepts as the sole source of
  truth.
- The design is explicitly usable across more than one backend class.

## Notes

- Primary design sources:
  - `docs/design/rounds/round-120-backend-substrate-vs-governance-startup-boundary.md`
  - `docs/design/rounds/round-117-forge-native-agent-coordination-boundary.md`
- Closely related work:
  - `89-forge-claim-and-lease-protocol.md`
  - `90-agent-capability-and-promotion-boundaries.md`
  - `91-maintainer-activity-and-promotion-surface.md`

## Outcome

- Added [docs/design/GOVERNANCE_OBJECT_MODEL.md](../design/GOVERNANCE_OBJECT_MODEL.md)
  as the canonical governance/control-plane object-model note.
- Defined canonical fields and relationships for:
  - `Claim`
  - `Lease`
  - `Attempt`
  - `Supersession`
  - `ReviewState`
  - `PromotionGate`
  - `AuthorityScope`
  - `DecisionRecord`
- Explicitly classified which objects are:
  - host-side live coordination state
  - repo-local durable artifacts
  - derived or indexed views
- Added a governance-boundary note to `BOARD_EXECUTION_MODEL.md` so the board
  remains an implementation-facing projection over the broader canonical object
  model.

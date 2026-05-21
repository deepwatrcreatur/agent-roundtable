# 89 — Forge Claim and Lease Protocol

**Status:** `ready`
**Tag:** `[structural]`

## Goal

Define the smallest forge-native coordination protocol that makes multi-agent
ownership explicit before collisions happen, centered on claims and leases rather
than on a full workflow engine.

## Scope

- Define canonical host objects for:
  - `Claim`
  - `Lease`
  - `Attempt`
  - `ReviewState`
- Define lease lifecycle semantics:
  - acquire
  - renew / heartbeat
  - expiry
  - takeover
  - operator override
- Distinguish logical work claims from mutable-resource leases.
- Keep the design compatible with both Git-backed and `jj`-backed local mutation
  workflows.
- Make the protocol suitable for thin adapters from local CLIs rather than only
  host-managed runtimes.

## Acceptance Criteria

- A concrete design note exists for claim and lease objects, fields, and state
  transitions.
- The design explicitly distinguishes:
  - duplicate task work
  - conflicting shared-resource mutation
  - publish/promotion collisions
- The protocol includes TTL / renewal behavior and a clear takeover path.
- The design is clearly narrower than a general workflow engine.

## Notes

- Primary design source:
  `docs/design/rounds/round-117-forge-native-agent-coordination-boundary.md`
- Closely related work:
  - `74-local-daemon-lease-contract.md`
  - `78-resource-contention-and-single-writer-policy.md`
  - `79-derived-round-index-and-resource-claims.md`

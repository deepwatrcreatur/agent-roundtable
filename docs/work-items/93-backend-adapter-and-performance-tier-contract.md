# 93 — Backend Adapter and Performance-Tier Contract

**Status:** `done` — **Codex**
**Tag:** `[hosting]`

## Goal

Design the backend adapter contract that lets the governance product run against
ordinary Git-compatible hosts while treating API-first backends such as
`code.storage` as optional performance tiers rather than as hard architectural
dependencies.

## Scope

- Define the minimum backend contract required for the control plane to function
  on an ordinary Git-compatible host.
- Define which capabilities may exist as optional higher-performance tiers, such
  as:
  - lower-latency change/ref operations
  - richer event delivery
  - high-write agent traffic support
  - future `jj`-forward backend primitives
- Distinguish:
  - baseline portability contract
  - optional optimization contract
  - backend-specific extensions that must not become canonical truth
- Specify how the control plane degrades gracefully when higher-tier backend
  features are unavailable.
- Keep the design compatible with the project's existing Git-compatibility
  posture.

## Acceptance Criteria

- A concrete adapter contract exists for plain Git-compatible hosting.
- The design explicitly separates required baseline backend behavior from
  optional optimization tiers.
- The design shows how API-first providers can accelerate the product without
  becoming mandatory for correctness.
- The design includes at least one conventional Git-host example and one
  API-first / higher-velocity backend example.

## Notes

- Primary design sources:
  - `docs/design/rounds/round-120-backend-substrate-vs-governance-startup-boundary.md`
  - `docs/design/rounds/round-60-q60.md`
- Closely related work:
  - `67-git-jj-translation-gateway.md`
  - `69-jj-vs-git-infra-benchmark.md`
  - `82-hosted-analysis-provider-contract.md`

## Outcome

- Added [docs/design/BACKEND_ADAPTER_CONTRACT.md](../design/BACKEND_ADAPTER_CONTRACT.md)
  as the backend adapter and performance-tier design note.
- Defined three explicit layers:
  - baseline portability contract
  - optional optimization contract
  - backend-specific extensions
- Specified how the control plane degrades gracefully when higher-tier backend
  features are unavailable.
- Included one conventional Git-host example and one API-first backend example.
- Linked the adapter contract back to the canonical governance object model so
  backend features do not become canonical governance truth.

# 95 — Buildkite-Compatible Controlled Executor

**Status:** `ready`
**Tag:** `[tools]`

## Goal

Develop the first CI runner/executor slice for the control-plane direction:
a local-first controlled executor that can run board-issued work durably while
staying compatible with a Buildkite-like job model rather than collapsing back
into GitHub Actions semantics.

## Scope

- Define the narrow executor contract between:
  - board work items / attempts
  - the local daemon/runtime layer
  - an external CI-facing or Buildkite-like job envelope
- Keep the control plane authoritative for:
  - claims
  - leases
  - attempt lineage
  - scoped credentials
  - promotion meaning
- Keep the executor responsible for:
  - job launch
  - heartbeat / liveness
  - log streaming
  - artifact upload
  - attestation return
- Start with the homelab/local-runner path first, but keep the API shape usable
  for later external executor providers.
- Make the compatibility target "Buildkite-like controlled executor" rather than
  "reimplement a generic workflow engine."

## Acceptance Criteria

- A concrete executor/job contract exists that maps board work items onto
  runnable jobs without losing lease or attempt semantics.
- A local runner can execute a claimed job, renew its lease, stream status, and
  return terminal result data.
- The design keeps publish/release authority outside the runner.
- The contract is narrow enough that a future Buildkite adapter or compatible
  ingress is plausible without changing the control-plane truth model.

## Notes

- Primary design sources:
  - `docs/design/rounds/round-121-control-plane-orchestration-vs-execution-providers.md`
  - `docs/design/BOARD_EXECUTION_MODEL.md`
  - `docs/design/LOCAL_DAEMON_CONTRACT.md`
- Closely related work:
  - `74-local-daemon-lease-contract.md`
  - `75-lightweight-workflow-definitions.md`
  - `89-forge-claim-and-lease-protocol.md`
  - `93-backend-adapter-and-performance-tier-contract.md`

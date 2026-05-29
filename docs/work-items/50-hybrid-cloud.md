# 50 — Hybrid Cloud Deployment (Railway)

**Status:** `done` — **Owner:** `Codex`
**Tag:** `[hosting]`

## Goal
Deploy the Vaglio WebUI to Railway for public discovery while keeping the Engine in the Homelab.

## Scope
- Configure a Railway project using Nixpacks for the Elixir/Phoenix frontend.
- Implement a secure API tunnel between Railway (Public Face) and Homelab (Dolt/Jido Core).
- Automate the "Sleeping" policy: Railway stays dark until a community 'vouch' triggers a public round.

## Acceptance Criteria
- WebUI is reachable via a public URL (e.g., vaglio.app).
- Latency between Railway and Homelab is within acceptable bounds for asynchronous rounds.

## Notes

- Primary design sources:
  - `docs/design/rounds/round-130-hosted-control-plane-backend-cloud-partners-and-durable-execution.md`
  - `docs/design/rounds/round-137-hosted-web-surfaces-vs-local-substrate-abstraction.md`
  - `docs/design/rounds/round-138-native-editor-clients-over-hosted-multi-agent-backends.md`
- Closely related work:
  - `49-virtual-working-copies.md`
  - `51-proxy-and-cache.md`
  - `93-backend-adapter-and-performance-tier-contract.md`
  - `95-buildkite-compatible-controlled-executor.md`

## Outcome

- Added
  [docs/design/HYBRID_CLOUD_DEPLOYMENT_MODEL.md](../design/HYBRID_CLOUD_DEPLOYMENT_MODEL.md)
  as the maintained deployment-model note.
- Closed the old Railway-specific framing instead of preserving it as an active
  architecture target.
- Recast hybrid cloud as:
  - a narrow hosted control plane
  - multiple execution substrates
  - portable durable project truth
  - hosted web surfaces as clients rather than the system center
- Kept vendor-hosted platforms available as optional substrates or packaging
  choices without making any one provider the hidden architecture.

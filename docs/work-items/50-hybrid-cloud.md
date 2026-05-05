# 50 — Hybrid Cloud Deployment (Railway)

**Status:** `ready`
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

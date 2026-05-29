# 51 — Agent-Proxy & Cache (OpenRouter + LiteLLM)

**Status:** `done` — **Owner:** `Codex`
**Tag:** `[tools]`

## Goal

Reduce token costs while preserving distinct agent voices and implementing local caching.

## Scope

- Integrate OpenRouter for multi-provider agent turns (DeepSeek, Claude, Gemini).
- Deploy LiteLLM in the Homelab as a caching proxy for "Redundant" turns (e.g., summarization).
- Implement "Budget-Aware Routing": low-precision tasks go to commodity models; high-precision vouching goes to original providers.

## Acceptance Criteria

- 40% reduction in token cost for redundant rounds.
- All "Distinct Voice" turns are verifiable and signed.

## Notes

- Primary design sources:
  - `docs/design/CACHE_TRUST_BOUNDARIES.md`
  - `docs/design/HOSTED_ANALYSIS_PROVIDER_CONTRACT.md`
- Closely related work:
  - `55-local-subscription-harness.md`
  - `82-hosted-analysis-provider-contract.md`
  - `87-safe-default-cache-trust-boundaries.md`
  - `90-agent-capability-and-promotion-boundaries.md`

## Outcome

- Added
  [docs/design/AGENT_PROXY_AND_CACHE_CONTRACT.md](../design/AGENT_PROXY_AND_CACHE_CONTRACT.md)
  as the narrow proxy/cache contract note.
- Defined the separation between:
  - distinct-voice turns that should bypass or tightly constrain caching/routing
  - commodity/cacheable turns that may use cheaper providers and reusable cache
    entries
- Anchored cache reuse to the repo’s existing trust-boundary model rather than
  treating LiteLLM/OpenRouter as an unconstrained convenience layer.
- Defined required provenance return fields for proxied/cached responses so the
  host can inspect route class, cache status, provider choice, and budget policy.
- Kept the architecture vendor-neutral by naming required capabilities instead
  of making a specific proxy product canonical.

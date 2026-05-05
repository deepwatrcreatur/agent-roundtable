# 51 — Agent-Proxy & Cache (OpenRouter + LiteLLM)

**Status:** `ready`
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

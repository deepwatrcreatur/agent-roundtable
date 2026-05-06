# 55 — Local Harness & DeepSeek Verification

**Status:** `ready`
**Tag:** `[tools]`

## Goal
Verify and harden the real local discussion harnesses: `claude`, `gemini`, `codex`, and `deepseek` via `RunCliAgent`.

## Scope
- Test the `claude`, `gemini`, and `codex` binaries to ensure they correctly use local session cookies/auth.
- Test `deepseek` through `Roundtable.Actions.RunCliAgent.run/2`, including missing-key and API-error handling.
- Document the login/bootstrap path for each harness to maintain headless compatibility.
- Normalize failure modes such as "Subscription Expired", "Rate Limited", quota exhaustion, or missing `DEEPSEEK_API_KEY` so the orchestrator and TUI can react cleanly.

## Acceptance Criteria
- All four real harnesses can either produce a turn or emit a clear structured failure state.
- Agents can produce high-signal turns without consuming OpenRouter credit when local subscriptions are valid.
- The expected operator recovery path is documented for auth expiry, rate limits, and missing DeepSeek credentials.

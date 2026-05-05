# 55 — Local Subscription Harness Verification

**Status:** `ready`
**Tag:** `[tools]`

## Goal
Verify and harden the use of local CLI binaries (`claude`, `gemini`, `codex`) for use with Pro/Plus subscriptions.

## Scope
- Test the `claude`, `gemini`, and `codex` binaries to ensure they correctly use local session cookies/auth.
- Document the login process for each harness to maintain "Headless" compatibility.
- Implement error handling for "Subscription Expired" or "Rate Limited" scenarios, allowing the Orchestrator to fail-over to OpenRouter if needed.

## Acceptance Criteria
- Agents can produce "High Signal" turns without consuming OpenRouter credit.
- Verified support for "Unlimited" context (where applicable by subscription).

# 55 — Local Subscription Harness Verification

**Status:** `done` — **Owner:** `Codex`
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

## Notes

- Primary design sources:
  - `docs/design/LOCAL_DAEMON_CONTRACT.md`
  - `docs/design/ORCHESTRATION_GUIDE.md`
- Closely related work:
  - `51-proxy-and-cache.md`
  - `57-agent-task-queue.md`
  - `74-local-daemon-lease-contract.md`
  - `95-buildkite-compatible-controlled-executor.md`

## Outcome

- Added
  [docs/design/LOCAL_SUBSCRIPTION_HARNESS_CONTRACT.md](../design/LOCAL_SUBSCRIPTION_HARNESS_CONTRACT.md)
  as the harness contract note for local subscription-backed CLI seats.
- Defined explicit harness profiles, health states, and fallback decision
  records instead of treating local CLI behavior as operator folklore.
- Made "subscription expired", "rate limited", and headless-login breakage
  machine-usable degraded states rather than generic runtime failure.
- Clarified that routed providers like OpenRouter are bounded fallback paths,
  not silent substitutes for distinct local seats.
- Required provenance to record whether a result came from the requested local
  harness or from a fallback route.

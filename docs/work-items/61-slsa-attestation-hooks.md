# 61 — SLSA-Signed Integrity Hooks

**Status:** `ready`
**Tag:** `[integrity]`

## Goal
Harden the supply chain by cryptographically linking code changes to their deliberation transcripts.

## Scope
- Implement a `Roundtable.Attestation` module.
- Every commit produced by an agent must include a SLSA-compatible attestation.
- The attestation must point to the specific `ACTIVE_DISCUSSION.md` round and `DECISION.md` hash.
- Implement a "Vouch-Verify" command that checks these signatures before code promotion.

## Acceptance Criteria
- Backdoor attempts are surfaced as "Unattributed State" in the DAG.
- 100% provenance visibility from line-of-code back to agent-consensus.

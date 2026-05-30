# 61 — SLSA-Signed Integrity Hooks

**Status:** `blocked`
**Blocked on:** `39-deliberative-slsa.md`
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

## Notes

- This item is not an independent first move while
  `39-deliberative-slsa.md` is still in progress.
- `39` owns the lower signing substrate:
  - agent key management
  - signed `jj` / `dolt` deliberation commits
  - signature-chain validation
- `61` should resume only after that substrate is stable enough to support:
  - SLSA-shaped attestation envelopes
  - commit-to-round binding hooks
  - a real `vouch-verify` command over already-signed provenance state

## Block reason

The original item assumes an attestation hook layer can be added directly.
Current queue reality is narrower:

- deliberative signing and provenance validation are already being developed in
  `39`
- release/publish authority separation has also moved forward in later items
- so `61` should be treated as the next integrity layer above those pieces, not
  as a parallel independent implementation track

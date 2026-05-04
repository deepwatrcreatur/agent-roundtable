# 39 — Deliberative SLSA (Sovereign Provenance)

## Status: `in-progress`
Owner: **DeepSeek**

## Objective
Implement cryptographic signing for all agent deliberation turns using GPG-signed `jj` and `Dolt` commits to provide verifiable deliberative provenance.

## Rationale
To ensure the "Record of Reason" is tamper-evident, we must move beyond simple prose logs. Every agent turn is a versioned commit that should be signed by the agent's unique key. This provides proof that a decision was reached by specific agents under specific protocol constraints.

## Requirements
- [ ] Implement agent key management (GPG) within the orchestrator.
- [ ] Enforce `--sign` on all `jj` and `dolt commit` operations.
- [ ] Implement `Roundtable.Provenance.Validator` to verify signature chains in a round.
- [ ] Update IC (Coordinator) logic to refuse closure of questions with unverified or missing signatures.
- [ ] Integrate SLSA Generic Generator for release binaries.

## Verification
- [ ] Assert that any attempt to modify a past round transcript results in a broken signature chain.
- [ ] Verify that the IC correctly blocks closure of an unsigned round.
- [ ] Generate a "Deliberative SLSA Report" for a completed question.

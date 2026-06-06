# 64 — Domain Expert Anchoring (Tag-Scoped Precision)

**Status:** `blocked` — simulated recovery-era item; requires genuine re-triage before claiming
**Tag:** `[governance]`

## Queue Note

This item came from the Gemini simulation recovery window and is not part of
the active ranked queue in `README.md`. Do not claim it as ordinary `ready`
work until it is reintroduced through a genuine round and explicitly ranked.

## Goal
Implement a system where domain experts (e.g., Accountants, Kernel Maintainers) can project their "taste" at scale by weighting their judgment on specific subject tags.

## Scope
- Implement **Precision Weighting** for Vouchers: a user's Vouch weight is amplified for specific `#tags`.
- Integrate with **SNA (Social Network Analysis)**: identify domain experts based on their "Vouched" history in the DAG.
- **Taste-Override**: When a High-Precision Voucher objects to a design round in their domain, the round is automatically moved to "Mandatory Disconfirmation" (Item 43).
- Display "Expert Alignment" scores on the Robustness Meter (Item 42).

## Acceptance Criteria
- Domain experts can influence project direction without writing code.
- "Vibe Coding" is blocked in high-integrity subtrees by domain-defined invariants.
- The project "Mind" prioritizes Expertise over Volume.

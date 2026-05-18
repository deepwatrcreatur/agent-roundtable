## Round 48 — File Reservations vs. Git Worktrees

**Tags:** tooling, structural, protocol
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI  
**Claude:** Not used for closure in this run

### First-pass convergence

- `jj` does not remove the need for coordination; it changes reservations from
  correctness locks into scheduling / intent primitives.
- Every agent should get a private ephemeral working copy (or the cheapest
  equivalent) by default.
- Merge-back should be an explicit promotion into vouched history, not “push and
  pray.”
- Consensus can help with some semantic conflicts, but cannot replace judgment
  when two changes are locally valid yet architecturally incompatible.

### Disconfirmation findings

The key failure mode is **stale-success promotion**:

- a change can be locally valid, rebase cleanly, and still be wrong in
  combination because it encodes a stale world-model or hidden architectural
  assumption
- naïve revalidation can become a bottleneck if every promotion effectively
  requires serial global recomputation

### Narrowed follow-up and closure

The round closes by requiring a promotion manifest for each private change.

#### Minimum promotion metadata

Each change must carry enough metadata for the orchestrator to detect causal and
architectural overlap before full revalidation. The converged minimum set is:

- `change_id`
- `base_commit`
- `touch_set` / `impact_set`
- symbol or module ownership where applicable
- `interface_delta` / changed public surfaces or dependency edges
- validation evidence
- one-line architectural intent

#### Orchestrator behavior before full revalidation

- detect causal staleness from `base_commit`
- detect direct overlap from `touch_set`
- detect architectural overlap from `interface_delta`, domain tags, or changed
  contracts/invariants
- route overlap-free promotions to normal revalidation
- route overlapping promotions to merge-review / arbitration

#### Tie-break rule

When two changes are locally valid but architecturally incompatible:

- do not let test ordering or queue timing decide architecture accidentally
- escalate to a single arbitration step
- choose the winner by explicit project criteria such as roadmap fit, blast
  radius, migration cost, and downstream compatibility
- rebase or rewrite the losing change against the accepted architecture

### Bottom line

Virtual worktrees are the right default, but only with:

- promotion manifests
- causal-overlap detection before expensive validation
- an explicit arbitration lane for architectural conflict

`[satisfied]`

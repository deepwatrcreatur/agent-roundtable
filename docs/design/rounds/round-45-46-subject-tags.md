## Round 45-46 — Subject Tags & Multidimensional Discovery

**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI  
**Claude:** Not used for closure in this run

### First-pass convergence

- Tags should be treated as architecture, not UI labels.
- Dolt should hold the durable semantic/tag relation layer.
- `jj` should expose tag-aware navigation through metadata / revset-facing
  projections.
- Vouching should be tag-scoped rather than global.

### Disconfirmation findings

The genuine red-team passes surfaced two real risks:

1. **Identity drift:** a pure `change_id`-free-text approach could split into
   multiple sources of truth or become brittle across rewrites.
2. **Governance drift:** tags can silently become a second governance system if
   creation, application, dispute, and override are left informal.

### Narrowed follow-up and closure

The narrowed follow-up produced genuine convergence on a v1 rule set:

- Use **`jj change_id`** as the canonical v1 anchor for tag identity.
- Store tag state in Dolt keyed by **`(repo_id, change_id)`**.
- Record immutable evidence alongside each tag event:
  - observed `commit_id`
  - actor / tagger
  - timestamp
  - `op_id` or equivalent observed revision context when available

### Governance model

- Split tags into:
  - `advisory`
  - `governing`
- Only **governing + approved + not-disputed** tags may affect routing or
  tag-scoped vouch reach.
- Governing-tag disputes immediately suspend governing effect.
- Governing actions must be append-only and auditable.
- Governing tags do **not** inherit implicitly from parent/child taxonomy in v1.

### Bottom line

The round closes with a practical v1 compromise:

- keep the semantic model simple enough to ship now by anchoring on
  `jj change_id`
- preserve auditability with immutable observed evidence
- prevent tag sprawl from silently changing routing or trust
  through a strict advisory-vs-governing split

`[satisfied]`

# Hosted Analysis Release Gate

**Status:** Drafted from Round 98
**Purpose:** Define the host-owned release-gate and exception model so outside
analysis providers can contribute findings without becoming the final authority
over merge and release decisions.

---

## 1. Principle

**External providers contribute evidence. The host renders the verdict.**

The release gate is a host-owned policy enforcement point. It consumes
normalized findings from all provider classes (first-party, self-hosted,
third-party) and applies repo-scoped policy to decide whether a change may
merge or release.

No provider, regardless of trust tier, unilaterally blocks or approves a
release. The gate is the host's decision, informed by provider evidence.

---

## 2. Gate Model

### 2.1 Gate evaluation

When a merge or release is requested, the host evaluates:

1. **Collect** — gather all normalized findings attached to the target revision
2. **Filter** — apply scope, suppression, and waiver rules
3. **Classify** — map remaining findings against the repo's policy thresholds
4. **Decide** — produce a gate verdict: `pass`, `fail`, or `warn`

### 2.2 Verdicts

| Verdict | Meaning | Effect |
|---|---|---|
| `pass` | No policy-blocking findings remain | Merge/release proceeds |
| `warn` | Findings exist but below blocking threshold | Merge/release proceeds with advisory annotations |
| `fail` | One or more findings exceed the policy threshold | Merge/release is blocked until resolved |

### 2.3 Resolution paths for `fail`

A failed gate can be resolved by:

- **Fix** — the finding is addressed in a new revision; re-evaluation passes
- **Waiver** — an authorized maintainer explicitly waives the finding (see section 4)
- **Suppression** — the finding matches a durable suppression rule (see section 5)
- **Dispute** — the finding is disputed and escalated (see section 6)

---

## 3. Policy Configuration

### 3.1 Repo-level policy

Each repository may declare gate policy in a host-recognized config file:

```yaml
analysis_gate:
  # Minimum severity that blocks merge
  blocking_severity: high

  # Categories that always block regardless of severity
  always_block:
    - undefined-behavior
    - secret-exposure

  # Categories that never block (advisory only)
  advisory_only:
    - license-compliance

  # Provider-specific overrides
  provider_overrides:
    "provider-xyz":
      max_confidence_weight: 0.8  # discount this provider's confidence

  # Branch-specific rules
  branch_rules:
    main:
      blocking_severity: medium  # stricter on main
    "release/*":
      blocking_severity: low     # strictest on release branches
```

### 3.2 Host-level defaults

The host provides sensible defaults for repos without explicit policy:

- `blocking_severity: critical` (only critical findings block by default)
- `always_block: [secret-exposure]`
- no provider-specific overrides
- no branch-specific rules

### 3.3 Policy inheritance

Branch-specific rules override repo-level defaults. Repo-level overrides
override host defaults. The most specific applicable policy wins.

---

## 4. Waiver / Exception Model

### 4.1 Waiver structure

A waiver is a durable, auditable record that an authorized maintainer has
reviewed a specific finding and decided to accept the risk.

| Field | Type | Description |
|---|---|---|
| `waiver_id` | string | Host-assigned unique identifier |
| `finding_id` | string | The finding being waived |
| `revision` | string | The revision at which the waiver was granted |
| `waived_by` | string | Identity of the maintainer who granted the waiver |
| `reason` | string | Free-text justification (required, minimum 20 characters) |
| `scope` | enum | `this_revision`, `this_branch`, `this_finding_permanent` |
| `expires_at` | timestamp? | Optional expiration (recommended for non-permanent waivers) |
| `created_at` | timestamp | When the waiver was created |

### 4.2 Waiver scope

| Scope | Meaning |
|---|---|
| `this_revision` | Waiver applies only to the exact revision where it was granted |
| `this_branch` | Waiver applies to the finding on this branch until the finding is superseded or the waiver expires |
| `this_finding_permanent` | Waiver applies to this finding globally until explicitly revoked |

### 4.3 Waiver authorization

- Only identities with the `gate_waiver` permission may create waivers
- The host records the full waiver provenance (who, when, why, against what)
- Waivers for `critical` or `always_block` findings require two authorized
  identities (dual approval)
- The host may enforce a cooling period between a finding and its waiver to
  prevent reflexive suppression

### 4.4 Waiver audit trail

The host maintains a complete, immutable audit trail of all waivers:

- creation events
- expiration events
- revocation events
- the finding and evidence that prompted the waiver

This trail is queryable by repo maintainers and host administrators.

---

## 5. Suppression Model

### 5.1 Suppression vs waiver

| | Suppression | Waiver |
|---|---|---|
| Granularity | Pattern-based (path, category, provider) | Finding-specific |
| Persistence | Durable rule in repo config | Durable record in host memory |
| Intent | "We know about this class of finding and accept it" | "We reviewed this specific finding and accept the risk" |
| Audit | Tracked as config changes | Tracked as explicit decisions |

### 5.2 Suppression rules

```yaml
analysis_gate:
  suppressions:
    - category: unsafe-code
      path: "src/ffi/**"
      reason: "FFI bindings require unsafe; reviewed in security audit Q2-2026"

    - provider: "legacy-scanner-v1"
      reason: "Deprecated scanner; findings superseded by new-scanner-v2"
      expires_at: "2026-12-31"
```

### 5.3 Suppression hygiene

- Suppressions must include a `reason` field
- Suppressions should include an `expires_at` field (the host warns on
  suppressions older than 6 months without expiration)
- The host tracks how many findings each suppression silences; suppressions
  that match nothing for 90 days are flagged for cleanup

---

## 6. Dispute Model

### 6.1 When to dispute

A finding may be disputed when:

- the finding is believed to be a false positive
- the finding applies to dead code or unreachable paths
- the provider's confidence is believed to be miscalibrated
- the finding duplicates another finding already addressed

### 6.2 Dispute structure

| Field | Type | Description |
|---|---|---|
| `dispute_id` | string | Host-assigned unique identifier |
| `finding_id` | string | The finding being disputed |
| `disputed_by` | string | Identity of the disputant |
| `reason` | string | Detailed dispute justification |
| `counter_evidence` | object? | Optional counter-evidence (test results, analysis output) |
| `resolution` | enum? | `upheld`, `overturned`, `withdrawn` (set by resolver) |

### 6.3 Dispute resolution

- Disputes are visible to the finding's provider for response
- The host does not automatically resolve disputes; a maintainer with
  `gate_waiver` permission must resolve
- An overturned dispute effectively creates a waiver with the dispute
  justification as the reason
- Dispute history is part of the permanent audit trail

---

## 7. Outcome Linking

### 7.1 Forward linking

The host links gate decisions to later outcomes:

- a waived finding that later causes an incident → the waiver is flagged
- a suppressed category that produces a real vulnerability → the suppression
  is flagged
- a disputed finding that is later confirmed → the dispute resolution is
  flagged

### 7.2 Provider calibration

Over time, the host accumulates data on:

- provider false-positive rate (findings that were waived/disputed/overturned)
- provider true-positive rate (findings that were confirmed by incidents)
- provider coverage (categories and repos where the provider adds value)

This data feeds into the provider trust weighting in policy decisions and
is visible to repo maintainers choosing which providers to enable.

### 7.3 Policy calibration

The host can surface:

- policies that are too strict (high waiver rate with no incidents)
- policies that are too loose (incidents from categories below the threshold)
- suppressions that are hiding real risk

This closes the feedback loop between gate decisions and real-world outcomes.

---

## 8. Gate Transparency

### 8.1 Gate report

Every gate evaluation produces a structured report:

- which findings were considered
- which were filtered by scope, suppression, or waiver
- which remained and how they mapped to policy
- the final verdict and the specific findings that caused it

This report is attached to the merge/release event as a durable artifact.

### 8.2 Reviewer visibility

The reviewer UX must surface:

- the gate verdict with a clear pass/warn/fail signal
- the specific findings that matter
- available resolution paths (fix, waiver, dispute)
- historical context (has this finding been seen before? was a similar
  finding waived or disputed?)

---

## 9. What This Design Does Not Cover

- **Provider contract and evidence schema** — covered in the companion
  provider contract design note
- **Specific CI/CD integration** — how gate evaluation hooks into build
  pipelines is implementation detail
- **Provider marketplace economics** — pricing, billing, competition rules
- **Human review workflow** — code review is separate from automated gate
  evaluation

---

## 10. Relationship to Prior Design

- **Round 98** — established that the host owns the final release gate and
  providers contribute evidence, not authority
- **Provider contract** — defines the normalized evidence that flows into
  this gate
- **Prediction calibration (item 77)** — outcome linking feeds the same
  calibration infrastructure
- **Governance object model (item 92)** — gate decisions, waivers, and
  disputes are governance objects with the same durability and provenance
  expectations

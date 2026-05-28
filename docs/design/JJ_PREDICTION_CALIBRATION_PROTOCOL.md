# `jj` Prediction Calibration Protocol

**Status:** Drafted from Round 87  
**Purpose:** Define a concrete, auditable protocol for recording predictions in
`jj` change metadata and later assessing those predictions against graph
outcomes without creating person-level reputation scores.

---

## 1. Goal

This protocol exists to answer a narrow integrity question:

> Did an explicit prediction about a change, risk, or subsystem hold up as the
> change graph evolved?

The protocol is not meant to:

- create public agent or maintainer leaderboards
- export global reputation scores
- collapse judgment into a single prestige number
- reward popularity, volume, or coalition size

It is meant to:

- make predictions explicit before outcomes are known
- tie later graph events back to those predictions
- keep calibration local, recent, scoped, and evidence-linked
- preserve an auditable distinction between prediction, confirmation, and
  coalition behavior

---

## 2. Design boundary

The protocol uses three layers.

### 2.1 `jj` change metadata

Change descriptions carry prediction-bearing fields and later outcome-linking
fields.

This keeps the graph itself legible.

### 2.2 Structured governance records

Prediction and vouch records should also be representable in structured local
storage such as `HumanAnchor`-adjacent schema or later canonical governance
objects.

This keeps assessment queryable.

### 2.3 Derived calibration views

Recent-windowed, subsystem-scoped summaries may be derived for routing and
integrity inspection.

These views are strictly derived and must remain non-prestige-bearing.

---

## 3. Core objects

The protocol centers on three object types.

### 3.1 `Prediction`

A forward-looking claim about a change, subsystem, or risk surface.

Minimum fields:

| Field | Meaning |
|---|---|
| `prediction_id` | Stable ID for later linkage |
| `scope` | Subsystem / path / object class in scope |
| `risk_class` | Risk profile such as `low`, `migration`, `runtime`, `security`, `operational` |
| `expected_properties` | What should go right if the prediction holds |
| `expected_failure_modes` | What could fail or regress |
| `vouch_basis` | Why the predictor believes this |
| `vouch_expiry` | When the prediction should be considered stale if unresolved |

### 3.2 `Vouch`

A structured statement of support, concern, or expectation attached to a claim.

Minimum fields:

| Field | Meaning |
|---|---|
| `prediction_id` | Linked prediction |
| `vouch_class` | `predictive`, `confirmatory`, or `coalitional` |
| `actor_ref` | Local actor identity |
| `basis_detail` | Explicit reasoning or evidence basis |
| `evidence_links` | Linked benchmark, precedent, test, report, or discussion |
| `recorded_at` | Time of the vouch |
| `expiry` | Optional vouch expiry |

### 3.3 `GraphOutcome`

A later graph event that bears on whether the earlier prediction held.

Minimum fields:

| Field | Meaning |
|---|---|
| `outcome_link` | Link to the relevant later change / event |
| `prediction_id` | Linked prediction |
| `outcome_type` | `merged`, `superseded`, `reverted`, `conflicted`, `stabilized`, `regressed`, `adopted_elsewhere` |
| `outcome_verdict` | `confirmed`, `partially_confirmed`, `violated`, `expired_unresolved`, `superseded_without_test` |
| `outcome_notes` | Human-readable interpretation |
| `calibration_delta` | Narrow local update, not a global score |
| `recorded_at` | Time outcome was linked |

---

## 4. `jj` metadata fields

These fields extend the existing `JJ_GUIDE` conventions such as `Supersedes:`,
`Path:`, and `Related-Round:`.

### 4.1 Prediction-bearing fields

Use these when recording a prediction on a change:

- `Prediction-ID:`
- `Scope:`
- `Risk-Class:`
- `Expected-Properties:`
- `Expected-Failure-Modes:`
- `Vouch-Basis:`
- `Vouch-Expiry:`

### 4.2 Outcome-linking fields

Use these on later changes or follow-up records:

- `Outcome-Link:`
- `Outcome-Verdict:`
- `Outcome-Notes:`
- `Calibration-Delta:`

These fields should be treated as protocol surfaces, not freeform decoration.

---

## 5. Vouch classes

The system must distinguish three classes of support.

### 5.1 Predictive

Recorded before broad recognition or final resolution.

This is the strongest class for later calibration because it represents genuine
anticipation under uncertainty.

### 5.2 Confirmatory

Recorded after additional evidence appears, but still adds a distinct basis.

This can refine interpretation but should not be treated as the same signal as
early prediction.

### 5.3 Coalitional

Recorded after visible consensus or without materially new basis.

This may still matter socially, but it should contribute very little to
calibration because it is highly vulnerable to cascade effects.

---

## 6. Legitimate outcome surfaces

Later calibration should primarily use graph/process outcomes, not popularity
proxies.

Legitimate outcome surfaces:

- merge or adoption
- explicit supersession
- revert or rollback
- conflict with deliberate resolution
- maintenance churn and regression burden
- independent adoption in another context

Illegitimate proxies:

- raw comment velocity
- follower count
- commit volume
- early visibility by itself
- prestige-bearing badges

---

## 7. Outcome interpretation rules

Later graph events should update a prediction by comparing the explicit earlier
expectation to actual change history.

### 7.1 Merge or adoption

May count as partial confirmation, but never as full confirmation by itself.

The stronger question is whether the predicted properties held after adoption.

### 7.2 Supersession

If a change is intentionally replaced, the earlier prediction should be marked:

- `partially_confirmed` if the supersession was normal refinement
- `violated` if the supersession addressed a named failure mode
- `superseded_without_test` if no strong outcome could be established

### 7.3 Reversion or rollback

This is strong negative evidence, especially when the reverted behavior matches
an earlier named failure mode.

### 7.4 Conflict and resolution

If a change enters durable conflict and later resolves cleanly, that may provide
evidence for or against the prediction depending on what the conflict exposed.

### 7.5 Maintenance burden

Repeated hotfixes, churn, or long-tail repair work count as meaningful evidence
against predictions of smoothness, safety, or low-risk rollout.

### 7.6 Expiry

If a prediction passes its expiry window without enough evidence to assess it,
the protocol should record:

- `expired_unresolved`

This is not the same as failure.

---

## 8. Calibration rules

Calibration updates must stay narrow.

Allowed aggregation:

- local
- recent-windowed
- subsystem-scoped
- claim-type-scoped
- sample-size-visible

Disallowed aggregation:

- global taste score
- person leaderboard
- exported trust rank
- hidden ranking weight
- prestige badge

This means the output is suitable for routing and local integrity inspection,
not identity branding.

---

## 9. Vouch update discipline

If a vouch is updated after community consensus shifts, the update should only
count as meaningful if linked to new evidence.

Acceptable new evidence:

- benchmark
- test result
- deployed outcome
- precedent
- addressed objection
- maintenance history

Without new evidence, the update should be treated as possible coalition or
cascade participation rather than refined judgment.

---

## 10. Sample end-to-end example

### Step 1 — Initial prediction

A maintainer records a prediction on a `jj` change:

```text
Prediction-ID: pred-router-ha-001
Scope: router/failover
Risk-Class: operational
Expected-Properties: no split-brain, bounded failover time, secrets remain out of store
Expected-Failure-Modes: stale lease ownership, secret path leakage, dual-active drift
Vouch-Basis: prior HA failover incidents and round-83 design constraints
Vouch-Expiry: 2026-07-01
```

### Step 2 — Supporting vouches

- one predictive vouch cites prior failover incidents
- one confirmatory vouch later cites a successful staging drill
- one late “looks good to me” without new basis is marked coalitional

### Step 3 — Later graph events

- the change merges
- a week later a follow-up hotfix supersedes part of the lease logic
- the hotfix explicitly addresses stale ownership behavior

### Step 4 — Outcome linkage

A later change or structured record links:

```text
Outcome-Link: pred-router-ha-001
Outcome-Verdict: partially_confirmed
Outcome-Notes: merge succeeded and secrets stayed out of store, but stale lease ownership required follow-up repair
Calibration-Delta: increase confidence on secret-handling basis, decrease confidence on failover-lease basis
```

### Step 5 — Derived local view

A local integrity surface may now say:

- sample size: 3 recent operational predictions in `router/failover`
- one confirmed
- one partially confirmed
- one unresolved

This may help route later review requests, but does not become a global score.

---

## 11. Recommended implementation plan

1. Extend `docs/JJ_GUIDE.md` with the prediction-bearing and outcome-linking
   fields.
2. Extend local vouch / anchoring storage with:
   - prediction IDs
   - vouch class
   - expiry
   - linked outcome verdicts
3. Record outcome linkage from graph events such as merges, supersessions,
   reversions, and maintenance fixes.
4. Build only narrow derived calibration views:
   - local
   - recent
   - scoped
   - sample-size-visible
5. Explicitly forbid leaderboard or prestige surfaces.

---

## 12. Summary

The correct use of the `jj` graph for calibration is:

- explicit predictions first
- later graph outcomes linked back to those predictions
- auditable verdicts on whether expectations held
- strong separation between predictive, confirmatory, and coalitional signals
- no public person-level ranking layer

This keeps calibration attached to object history and outcome evidence rather
than letting it drift into a prestige machine.

# 77 — `jj` Prediction Calibration Protocol

**Status:** `done` — **Owner:** `Codex`
**Tag:** `[integrity]`

## Goal

Turn Round 87 into a concrete, auditable protocol for recording predictions in
`jj` change metadata and later assessing those predictions against graph
outcomes without creating person-level reputation scores.

## Scope

- Extend `docs/JJ_GUIDE.md` with standard prediction-bearing metadata fields.
- Extend the current vouching / anchoring model with stable prediction IDs,
  vouch class, expiry, and linked outcome assessment.
- Define how merges, supersessions, reversions, maintenance burden, and
  conflict resolution update the status of earlier predictions.
- Preserve the distinction between:
  - predictive vouches
  - confirmatory vouches
  - coalitional vouches
- Keep all aggregation local, recent-windowed, subsystem-scoped, and
  sample-size-visible.

## Acceptance Criteria

- `docs/JJ_GUIDE.md` documents a standard set of fields including:
  - `Prediction-ID:`
  - `Scope:`
  - `Risk-Class:`
  - `Expected-Properties:`
  - `Expected-Failure-Modes:`
  - `Vouch-Basis:`
  - `Vouch-Expiry:`
- A concrete schema/design note exists for:
  - `predictions`
  - `vouches` / vouch extensions
  - `graph_outcomes`
- The protocol explains how later graph events link back to earlier predictions
  with explicit outcome verdicts.
- The implementation plan explicitly rejects:
  - person leaderboards
  - portable trust scores
  - prestige badges
  - hidden reputation weighting
- At least one sample end-to-end example is documented from prediction creation
  through later outcome assessment.

## Outcome

Done in:

- `docs/design/JJ_PREDICTION_CALIBRATION_PROTOCOL.md`
- `docs/JJ_GUIDE.md`

The resulting protocol:

- defines explicit prediction-bearing and outcome-linking `jj` metadata fields
- distinguishes predictive, confirmatory, and coalitional vouches
- links later graph outcomes back to earlier predictions with explicit verdicts
- keeps all calibration local, scoped, recent-windowed, and non-prestige-bearing

## Notes

- Primary design source: `docs/design/rounds/round-87-jj-graph-prediction-calibration.md`
- Closely related prior work:
  - `45-vouch-anchoring.md`
  - `46-dolt-tag-schema.md`
  - `62-jj-high-velocity-ingest.md`

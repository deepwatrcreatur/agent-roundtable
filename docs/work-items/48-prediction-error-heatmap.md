# 48 — Prediction Error Heatmap (System Stress UI)

**Status:** `done` — **Owner:** `Codex`

## Goal
Replace the linear "Notification List" with a visual heatmap of "System Stress" (Prediction Errors) to focus maintainer attention.

## Scope
- Implement a "Stress Metric" based on Friston's principles:
    - **High Stress**: Conflict between high-precision Vouchers, repeated rounds without consensus, or failing invariants.
    - **Low Stress**: Convergent consensus, high-weight Vouching, passing tests.
- Create a "Project Mind" Heatmap in the WebUI.
- Map code subtrees (via `jj` paths) to stress levels.
- Link the Heatmap directly to the "Adversarial Turn UI" (Item 43) to show the source of the friction.

## Acceptance Criteria
- Maintainers can see at a glance which modules are "Settled" and which are "Contested."
- Direct correlation between "Sycophancy Score" (Low Stress/High Redundancy) and "Appraisal Value."
- Moves the UX from "Managing a Queue" to "Resolving Prediction Errors."

## Outcome

Done in the public Forgejo-shell surface and supporting tests.

The resulting implementation:

- adds a `Project Mind Heatmap` to the public repo demo surface
- renders `Settled`, `Watch`, and `Contested` heatmap cells
- includes explicit `Appraisal value` context instead of only abstract stress
  wording
- derives heatmap cells from both curated stress hotspots and sampled path
  hotspots when repo-history evidence is available

Primary implementation path:

- `roundtable/lib/roundtable_web/live/forgejo_shell_live.ex`

Merged in:

- PR `#91`

## Notes

- Closely related work:
  - `41-integrity-scorecard.md`
  - `43-red-team-highlights.md`
  - `68-public-repo-investor-demo.md`

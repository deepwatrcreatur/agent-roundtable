# 48 — Prediction Error Heatmap (System Stress UI)

**Status:** `in-progress` — **Codex**

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

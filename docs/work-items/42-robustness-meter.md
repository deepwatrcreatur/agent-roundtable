# 42 — Consensus Robustness Meter

**Status:** `ready`

## Goal
A visual indicator of the "Heat" of a discussion to distinguish robust consensus from silent agreement.

## Scope
- Define "Consensus Intensity" based on round count, objection count, and `[satisfied]` vs `[no objection]` ratio.
- Implement a "Robustness Meter" (SVG/Canvas) for the WebUI.
- Map discussion states:
    - **Deep Green**: High heat, multiple rounds, resolved conflict.
    - **Pale Green**: Consensus reached in Round 1 (Low Robustness).
    - **Yellow**: Consensus reached via `[no objection]` exhaustion.

## Acceptance Criteria
- Meter updates in real-time as rounds progress.
- Historical view allows users to quickly identify "Rubber-Stamped" decisions.

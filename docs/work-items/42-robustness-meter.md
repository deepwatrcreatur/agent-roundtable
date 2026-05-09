# 42 — Consensus Robustness Meter

**Status:** `done` — **GitHub Copilot**

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

## Outcome
- Added `Roundtable.RobustnessMetrics` to score each discussion from existing roundtable signals: round count, objection count, and the balance between `[satisfied]` and `[no objection]`.
- Extended `DiscussionLive` with inline SVG robustness meters on each question plus a historical low-robustness section for quick rubber-stamp triage.
- Updated roundtable event handling so dashboard metrics refresh immediately during active rounds instead of waiting for the next poll cycle.

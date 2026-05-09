# 43 — Adversarial Turn UI

**Status:** `done` — **GitHub Copilot**

## Goal
Promote and highlight "Skeptic" turns to prove the council is actively testing for failure modes.

## Scope
- Add a specific UI treatment (e.g., red border, "Skeptic" badge) for agents assigned the disconfirmation pass.
- Implement a "Red Team" toggle in the round history to filter for adversarial turns.
- Visualise "Premise Collisions" where an agent's `[observed]` evidence contradicted a BRIEF assumption.

## Acceptance Criteria
- User can toggle "Red Team Only" to see the "Hard Truths" surfaced by the council.
- The "Disconfirmation Pass" (Protocol Update 9) is explicitly labelled in the transcript.

## Outcome
- Added `Roundtable.RedTeamHighlights` to parse discussion comments into transcript turns, flag skeptical/disconfirmation passes, and surface premise collisions tied to `[observed: ...]` evidence.
- Extended `DiscussionLive` with a `Round History` transcript section, a `Red Team Only` toggle, and explicit `Disconfirmation Pass`, `Skeptic`, and `Premise Collision` badges.
- Added hard-truth and collision summaries on question cards so adversarial turns stand out even before opening the transcript history.

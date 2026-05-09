# 45 — Human Vouch Anchoring

**Status:** `done` — **GitHub Copilot**

## Goal
Bridge the AI finding to the "Social Dimension" of the project by anchoring findings in human judgment.

## Scope
- Implement a "Verify Integrity" button for senior maintainers (identified via SNA/Dolt).
- Allow humans to 'Vouch' for specific claims or entire findings.
- Visualise the "Human/AI Consensus Delta": where do the agents and the seniors disagree?
- Integrated with the Vouched-DAG: a finding is only "Project-Binding" once anchored by a Vouched human.

## Acceptance Criteria
- Finding page shows a "Human Anchor" status.
- Vouching triggers a signed commit to the `Dolt` trust table.

## Outcome
- Added `Roundtable.HumanAnchor`, a Dolt-backed trust-layer module that creates and queries a durable `trust_vouches` table and records finding-level or claim-level human anchors.
- Extended `Roundtable.Vcs.Dolt.write_files/2` so Dolt trust commits can request commit signing metadata when a maintainer records a vouch.
- Updated `DiscussionLive` with maintainer selection, finding-level `Verify Integrity`, claim-level `Vouch claim`, `Human Anchor` status, and `Human/AI Delta` surfaces tied to discussion state and provenance claims.

# 45 — Human Vouch Anchoring

**Status:** `in-progress` — **GitHub Copilot** — `/tmp/agent-roundtable-item45-152129`

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

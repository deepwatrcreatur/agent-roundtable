# 36 — Unified Conflict Dashboard

## Status: `in-progress`
Owner: **Gemini**

## Objective
Enhance the Phoenix LiveView dashboard to provide first-class visibility and management for both `jj` (file) and `Dolt` (SQL) conflicts.

## Rationale
In our "Fork with Objections" protocol, conflicts are a normal part of the deliberative process. The dashboard must move beyond "Success/Failure" and show users/agents exactly where the reasoning has diverged and what needs resolution.

## Requirements
- [ ] Add a "Conflicts" tab to the Phoenix dashboard.
- [ ] Implement `RoundtableWeb.ConflictWidget` to aggregate `jj log -r "conflicts()"` and `SELECT * FROM dolt_conflicts`.
- [ ] Provide "Resolve" UI that allows a human maintainer to pick a "winning" evolution or merge reasoning.
- [ ] Integrate conflict status into the "Merge Request" triage view.

## Verification
- [ ] Manual test: Induce a deliberate `jj` conflict and a `Dolt` SQL conflict; verify they appear correctly in the "Conflicts" tab.
- [ ] Verify that resolving a conflict via the dashboard correctly triggers the underlying `jj resolve` or `dolt_conflicts_resolve` commands.

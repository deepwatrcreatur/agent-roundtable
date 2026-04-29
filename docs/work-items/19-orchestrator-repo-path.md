# 19-22 — Orchestrator File-Based Model + CLI Integration

**Status:** `done`
**Branch:** `feat/discussion-repo` (merged via PR #17)

## Scope

Four integration items wiring items 15-18 into the orchestrator and CLI.

### Item 19 — `Orchestrator.run_with_repo/2`

Entry point for the file-based model. Reads `BRIEF.md` + `roundtable.toml` via
`DiscussionGit`, runs each question through rounds, commits `rounds/round-NN-slug.md`
after each round closes, appends `DECISION.md` on consensus.

`run_repo_loop/4` carries `{run, buffer, repo}` state.
`apply_repo_effect/5` dispatches all effects in the file-based model.

### Item 20 — `RoundRun.discussion_repo_path`

New optional field on `RoundRun`. When set, state persists to
`<path>/.roundtable/state/` instead of the global Application config dir.
`new/3` accepts `:discussion_repo_path` keyword option.

### Item 21 — `CLI.start_discussion/2` slug detection

Auto-detects `"owner/repo"` slug vs. file path using regex.
Slug input: creates `DiscussionRepo` and calls `Orchestrator.run_with_repo/2`.
File path input: legacy GitHub Issues path via `Orchestrator.run/3`.

### Item 22 — `issues_enabled` gating

All GitHub Issues calls in `apply_repo_effect/5` gated behind `repo.issues_enabled`.
When false (default), the discussion lives entirely in committed files with no
`gh` CLI access required.

## Shared helpers extracted

`triage_with_ic/5` and `apply_label/3` extracted as private helpers reused by
both the Gh (`apply_effect/2`) and file-based (`apply_repo_effect/5`) effect paths.

# 15-18 — DiscussionRepo Layer

**Status:** `done`
**Branch:** `feat/discussion-repo` (merged via PR #17)

## Scope

Four modules implementing the file-based discussion repo model (Protocol Update 10 / Q23).

### Item 15 — `Roundtable.DiscussionRepo.Backend` behaviour

Callbacks: `read_file/2`, `write_file/4`, `list_files/2`, `discussion_repo?/1`.
Defines the abstraction boundary between the orchestrator and the git backend.

### Item 16 — `Roundtable.DiscussionRepo` struct

Fields: `gh_slug`, `token`, `local_path`, `issues_enabled`, `head_sha`, `backend`, `config`.
`new/2` constructor with keyword options. Delegates all I/O to the configured backend.

### Item 17 — `Roundtable.Adapters.GitHub`

Uses `gh api` CLI. GET for reads; SHA-fetch + PUT with base64-encoded JSON stdin for writes.
Bearer token injected before `api` subcommand when `:token` is set.
Runner injected via `repo.config[:runner]` for testing.

### Item 18 — `Roundtable.Actions.DiscussionGit`

Orchestrator-facing module: `read_brief/1`, `read_decision/1`, `read_config/1`,
`list_rounds/1`, `read_round/2`, `commit_round/4`, `append_decision/2`.
Encodes canonical repo layout (`rounds/`, `BRIEF.md`, `DECISION.md`, `roundtable.toml`).
Minimal regex TOML parser for `roundtable.toml` schema v1.

## Test support

`test/support/stub_backend.ex` — in-memory Backend using process dictionary.
Seed: `Process.put(:stub_files, %{"BRIEF.md" => "content"})`.
Assert: `Process.get(:stub_written)["rounds/round-01.md"]`.

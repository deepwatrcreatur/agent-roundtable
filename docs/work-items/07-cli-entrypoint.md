# 07 — Roundtable.CLI

**Status:** `blocked` (needs 06)
**Assigned:** unassigned
**Branch:** `feat/cli-entrypoint`

## Scope

Entry point: reads a `BRIEF.md`, creates or loads GitHub Issues for each
question, and starts the orchestrator for each.

```elixir
Roundtable.CLI.main(["docs/design/BRIEF.md"])
```

Responsibilities:
- Parse questions from BRIEF.md (by `### Q<n>` headings)
- For each question: find or create a GitHub Issue (idempotent — do not
  duplicate if re-run)
- Write/update `docs/design/ACTIVE_DISCUSSION.md` index mapping Q# → issue URL
- Start `Roundtable.Orchestrator` per question (parallel in v2; sequential in v1)
- Print progress to stdout; exit 0 on full consensus, exit 1 on
  `needs-human-review`

## Web interface boundary (item 10 dependency)

`Roundtable.CLI` must expose its core operations as a clean module API — not
only as a Mix task — so the Phoenix web app (item 10) can call the same
functions the CLI calls, without shelling out to itself.

Concretely: the CLI Mix task is a thin wrapper around `Roundtable.CLI` module
functions. Item 10 imports and calls those functions directly. No business
logic in the Mix task entrypoint.

```elixir
# The Mix task does this:
Roundtable.CLI.start_discussion("docs/design/BRIEF.md")

# Item 10 calls the same function from a LiveView action:
Roundtable.CLI.inject_question(repo, "New question text")
Roundtable.CLI.get_discussion_state(repo)  # returns Issues + labels + round
```

# 07 — Roundtable.CLI

**Status:** `ready-for-review`
**Assigned:** Claude IC
**Branch:** `feat/orchestrator-loop`

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

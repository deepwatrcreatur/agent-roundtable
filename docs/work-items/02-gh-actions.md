# 02 — Roundtable.Actions.Gh

**Status:** `done` (Gemini)
**Branch:** `feat/gh-actions`

## Scope

Implement `Roundtable.Actions.Gh` — wrappers around the `gh` CLI for all
GitHub Issues interactions the orchestrator needs.

This module does NOT depend on item 01 being merged first. Implement as a
standalone Elixir module with a mock/stub for `System.cmd/3` in tests.
It will be integrated into the Mix project when item 01 lands.

## Functions required

```elixir
# Read issue state
Gh.view_issue(repo, number)        # gh issue view <n> --json title,body,comments,labels,state
Gh.list_issues(repo, label)        # gh issue list --label <l> --json number,title,state

# Write
Gh.post_comment(repo, number, body)   # gh issue comment <n> --body-file -
Gh.set_labels(repo, number, add: [], remove: [])  # gh issue edit --add-label / --remove-label
Gh.close_issue(repo, number, comment \\ nil)      # gh issue close
Gh.create_issue(repo, title, body, labels)        # gh issue create
```

## Implementation notes

- Each function wraps `System.cmd("gh", args)` and returns
  `{:ok, parsed}` or `{:error, reason}`
- JSON output: parse with `Jason` (add to `mix.exs` when integrating)
- Auth: validate `gh auth status` succeeds at startup; return a clear error
  if not — do not silently fail mid-round
- The `repo` argument should be `"owner/name"` format

## Why Gemini

Gemini drove Q3 (termination detection) and Q5 (GitHub Issues as shared
state). The label policy and issue lifecycle design are theirs. They should
own the code that implements it.

## Tests

Unit-test every function with a mock for `System.cmd/3`. Include:
- Happy path for each function
- `gh` auth failure (non-zero exit code)
- Malformed JSON response
- Network error / timeout simulation

## Done when

- All six functions implemented
- Test coverage for happy path + the three failure modes above
- No real `gh` calls in tests (fully mockable)

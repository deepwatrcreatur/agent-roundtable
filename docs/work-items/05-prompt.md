# 05 — Roundtable.Prompt

**Status:** `blocked` (needs 01, 02, 03)
**Assigned:** Codex
**Branch:** `feat/prompt`

## Scope

Implement `Roundtable.Prompt` — assembles the context and instructions for
each agent invocation from BRIEF.md + GitHub Issue JSON + agent role.

## Interface

```elixir
Prompt.build(brief_text, issue_json, agent, opts \\ [])
# => String.t()
```

## Content model

```
[Role preamble — who this agent is and what they are doing]

=== BRIEF ===
[contents of BRIEF.md — the original design questions]

=== QUESTION ===
Title: [issue title]
URL: [issue url]

=== DISCUSSION SO FAR ===
[last N comments from issue_json, formatted as:
  ## Agent Name — timestamp
  [comment body]
]

=== YOUR TASK ===
[tailored instruction per agent role]
[satisfaction protocol reminder]
[explicit: do not post to GitHub — the orchestrator will post your response]
```

## Notes

- Cap `DISCUSSION SO FAR` at the last 10 comments to bound token size; older
  context is in the issue thread but not injected
- The `=== YOUR TASK ===` section differs per agent:
  - `codex` / `gemini`: research the question, produce a signed position
  - `claude_ic`: synthesise the round, identify unresolved gaps, produce the
    next IC note or close the question
- Keep prompt construction pure (no side effects, no `gh` calls)

## Done when

- `build/3` produces a well-formed prompt string for all three agent roles
- Token budget respected (cap comment injection)
- Tests cover: first round (no prior comments), mid-round, IC synthesis turn

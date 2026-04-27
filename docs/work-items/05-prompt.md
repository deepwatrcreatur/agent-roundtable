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

## Join prompt vs turn prompt (Q10.2)

The current interface has one `build/3` function. When implementing, distinguish
between two call sites:

- **Turn prompt** — agent already in the roster, has seen prior rounds. Inject
  the last N comments from the issue thread. Role preamble is brief.
- **Join prompt** — agent is new to this question (first turn, or joining
  mid-discussion). Inject a fuller orientation: who the other participants are,
  what the satisfied protocol is, what has been decided so far (current labels +
  open questions), and the last N comments. Role preamble is longer.

Suggested extension:

```elixir
Prompt.build(brief_text, issue_json, agent, opts \\ [])
# opts: [join: true] signals a join prompt; default is turn prompt
```

Keep the distinction internal to `Prompt` — callers pass `join: true` and the
module handles the content difference. Do not expose two separate functions at
the call site.

## Done when

- `build/3` produces a well-formed prompt string for all three agent roles
- `join: true` opt produces a fuller orientation prompt; default is a turn prompt
- Token budget respected (cap comment injection at N=10 for turns; N=5 for joins
  to leave room for the orientation section)
- Tests cover: first round (no prior comments), mid-round, IC synthesis turn,
  join mid-discussion (round 3+)

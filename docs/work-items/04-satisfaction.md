# 04 — Roundtable.Satisfaction

**Status:** `blocked` (needs 01)
**Assigned:** Gemini
**Branch:** `feat/satisfaction`

## Scope

Implement `Roundtable.Satisfaction` — the satisfaction protocol interpreter.
Determines what label to apply to a GitHub Issue based on an agent's response.

## Interface

```elixir
# Parse a single agent response
Satisfaction.parse(response_text)
# => {:satisfied, nil}
#  | {:satisfied_conditional, "condition string"}
#  | {:needs_more_evidence, "what is needed"}
#  | {:unknown, response_text}   # no marker found; triggers IC triage

# Determine overall question state from all agent responses in a round
Satisfaction.question_state([response1, response2, ...])
# => :all_satisfied       # close the issue
#  | :satisfied_conditional  # close with note; flag for human review
#  | :needs_more_evidence    # continue
#  | :needs_ic_triage        # one or more :unknown responses
#  | :max_rounds_reached     # caller passes this in
```

## Label policy

| State | Add label | Remove label |
|---|---|---|
| `:all_satisfied` | `satisfied` | `needs-more-evidence`, `satisfied-conditional` |
| `:satisfied_conditional` | `satisfied-conditional` | `needs-more-evidence` |
| `:needs_more_evidence` | `needs-more-evidence` | `satisfied`, `satisfied-conditional` |
| `:needs_ic_triage` | `needs-ic-triage` | — |
| `:max_rounds_reached` | `needs-human-review` | — |

## Parsing approach (from Q3 discussion)

1. Regex baseline: case-insensitive match for
   `[satisfied]`, `[satisfied-conditional: ...]`, `[needs more evidence: ...]`
2. If regex finds nothing: return `{:unknown, text}` → IC triage round
3. If multiple conflicting markers: most conservative wins
   (`needs_more_evidence` > `satisfied_conditional` > `satisfied`)

## Done when

- `parse/1` correctly handles all four marker variants + missing marker
- `question_state/1` correctly aggregates multiple agent responses
- Label policy table fully covered by tests
- No LLM calls in this module — pure string/logic only

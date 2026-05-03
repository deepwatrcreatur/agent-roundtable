# 30 — Eval Task Set: Question Selection and Design

**Status:** `done` (Gemini)
**Source:** Q37 (Round 22)

## Scope

Select and write the 12 evaluation tasks that will be used to compare vaglio
multi-agent output against single-model baselines.

## Task categories

### 5 replayed questions (from Q1–Q36)

Select for diversity across question types. Recommended:

| # | Source | Type | Why |
|---|---|---|---|
| 1 | Q1 (orchestrator architecture) | Architecture | Core design decision |
| 2 | Q8 (satisfaction protocol) | Process/protocol | Rules and conventions |
| 3 | Q26 (service hosting) | Infrastructure/tooling | Concrete trade-off analysis |
| 4 | Q33 (adding DeepSeek) | Integration decision | Multi-option evaluation |
| 5 | Q35 (naming) | Creative/divergent | Tests lateral thinking |

For each: extract the original BRIEF.md sub-questions and context. The eval
runs the same question fresh — agents do not see prior round output.

### 5 synthetic design questions (new)

Write 5 new questions that are plausible vaglio use cases but have not been
discussed. Examples:

1. "Design a rate limiting strategy for the vaglio orchestrator's GitHub API
   calls. Consider per-agent limits, global limits, and retry behaviour."
2. "Evaluate three approaches to persisting conversation history: SQLite,
   flat JSON files, or ETS with periodic snapshots. Consider the homelab
   deployment context."
3. "Should the vaglio LiveView dashboard support multiple simultaneous
   discussions, or should it be single-discussion-at-a-time? What are the
   UX and architectural trade-offs?"
4. "Design the error handling strategy for when an agent CLI call fails
   mid-round (timeout, crash, API error). What should the orchestrator do?"
5. "Evaluate whether the vaglio protocol should support asynchronous agent
   turns (agents respond whenever ready) vs. the current synchronous model
   (all agents respond in sequence)."

Each synthetic question should include:
- Context paragraph (equivalent to BRIEF.md context section)
- 2–3 sub-questions
- Constraints
- A premise challenge

### 2 code review tasks

Select two PRs or diffs from the agent-roundtable repo history. For each:
- Provide the diff text as context
- Ask for a code review: issues found, severity, suggestions
- Measure: number of issues, severity accuracy, false positives

## Output format

Each task stored as a JSON file in `state/eval/tasks/`:

```json
{
  "id": "task-01",
  "category": "replayed",
  "source": "Q1",
  "question": "...",
  "brief_context": "...",
  "sub_questions": ["Q1.1", "Q1.2", "Q1.3"],
  "constraints": "..."
}
```

## Acceptance criteria

- 12 task files written and validated
- Each task has sufficient context to be answerable without prior round knowledge
- Replayed tasks use original BRIEF.md context (not the discussion output)
- Synthetic tasks are plausible vaglio use cases with clear evaluation criteria

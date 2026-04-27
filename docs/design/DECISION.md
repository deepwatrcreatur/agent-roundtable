# Decision: Autonomous Roundtable Orchestrator Architecture

**Date:** 2026-04-26
**Status:** Closed
**Evidence:** `ACTIVE_DISCUSSION.md` — six questions, three agents (Codex ×3,
Gemini ×3, IC ×3), four rounds

---

## Summary

Build a roundtable orchestrator **on top of Jido 2.0** in Elixir, packaged as
a Nix flake app. Active per-question discussion lives in GitHub Issues;
durable artifacts (BRIEF, DECISION, transcripts) stay in git. Agents are
invoked as CLI subprocesses; the orchestrator owns all GitHub side effects.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Nix flake app  (`roundtable`)                       │
│  ┌───────────────────────────────────────────────┐   │
│  │  Jido.Agent  — Orchestrator                   │   │
│  │  cmd/2: round state in → updated state +      │   │
│  │          directives out                        │   │
│  │                                                │   │
│  │  Actions           Signals                     │   │
│  │  ├ RunCliAgent     ├ QuestionCommentPosted     │   │
│  │  ├ GhIssueView     ├ QuestionSatisfied         │   │
│  │  ├ GhIssueComment  ├ QuestionNeedsMoreEvidence │   │
│  │  ├ GhIssueLabel    └ RoundTimedOut             │   │
│  │  └ GhIssueClose                                │   │
│  │                                                │   │
│  │  Directives (side-effect descriptors)          │   │
│  │  ├ PostIssueComment                            │   │
│  │  ├ SetIssueLabels                              │   │
│  │  ├ CloseIssue                                  │   │
│  │  └ ScheduleNextTurn                            │   │
│  └───────────────────────────────────────────────┘   │
│                                                       │
│  Domain modules (not provided by Jido)                │
│  ├ Roundtable.Satisfaction   — label/marker logic     │
│  ├ Roundtable.Scheduler      — round-robin policy     │
│  ├ Roundtable.Prompt         — BRIEF + issue → prompt │
│  └ Roundtable.Gh             — System.cmd gh wrappers │
└─────────────────────────────────────────────────────┘

Shared state
├ GitHub Issues   — active per-question discussion
│  ├ Comments     — signed agent positions
│  ├ Labels       — satisfied / needs-more-evidence / satisfied-conditional
│  └ Open/closed  — question lifecycle state
└ Git repo        — BRIEF.md, DECISION.md, ATTRIBUTION.md, transcripts
   └ ACTIVE_DISCUSSION.md  — index: Q# → issue number, orchestration rules
```

---

## Decisions

### Foundation — Jido 2.0

Use `{:jido, "~> 2.0"}` as the runtime foundation. Do not roll a custom
`GenServer` + `System.cmd/3` inline loop.

- Each CLI agent invocation is a `Jido.Action` (`RunCliAgent`).
- State transitions (`continue → satisfied → closed`) are the orchestrator
  agent's `cmd/2` function — pure, unit-testable without running any LLMs or
  hitting GitHub.
- Side effects (`gh issue comment`, `gh issue edit`, `gh issue close`) are
  `Directive`s executed by the Jido runtime, not inline in action logic.
- `Jido.Signal`s carry events between the orchestrator and any future
  sub-agents or watchers.
- OTP supervision and fault tolerance are inherited from Jido's runtime — no
  custom supervisor tree needed for v1.

**Defer `jido_ai` to v2.** IC triage in v1 uses a raw `claude -p` CLI call
via `RunCliAgent`, same as participant invocations. `jido_ai` becomes relevant
if an Elixir-native selector, summarizer, or fallback judge is needed later.

### Shared State — Hybrid

| Content | Medium | Rationale |
|---|---|---|
| Active per-question turns | GitHub Issues | Atomic writes, no merge conflicts, parallel-agent safe |
| Question satisfaction state | Issue labels | Machine-readable without prose parsing |
| Question lifecycle | Issue open/closed | Natural termination signal |
| BRIEF, DECISION, ATTRIBUTION | Git-tracked files | Durable, reviewable, version-controlled |
| Session index (Q# → issue#) | `ACTIVE_DISCUSSION.md` in git | Stable pointer; not written during live rounds |
| Transcripts/archives | Git-tracked files | Persist after issues close |

Do not write agent positions to `ACTIVE_DISCUSSION.md` during live rounds.
That file is updated by the orchestrator only when opening or closing a
discussion, not turn-by-turn.

### Turn Protocol — Round-Robin + IC Close

- Fixed agent order within a question: `[codex, gemini, claude_ic]`.
  `claude_ic` runs last as the IC; it synthesises, issues the next prompt,
  and decides whether to continue or close.
- Questions can run in parallel across GitHub Issues using
  `Task.async_stream/3` (or Jido's equivalent `await_all`). Questions with
  declared dependencies must be sequenced; independent questions are parallel.
- One round = all agents have commented once on a given question.

### Termination — Labels Primary, IC Triage Fallback

1. After each agent posts, the orchestrator reads
   `gh issue view <n> --json labels,state,comments`.
2. If all active agents have a `satisfied` or `satisfied-conditional` label
   and none have `needs-more-evidence`, the issue is closed.
3. If an agent's response contains no detectable satisfaction marker, the
   orchestrator invokes `claude_ic` with a triage prompt: *"Does the latest
   comment on this question indicate satisfaction? Reply: satisfied /
   satisfied-conditional / needs-more-evidence."* The IC response sets the label.
4. `max_rounds` (default 5) reached without consensus → orchestrator posts a
   summary comment, adds a `needs-human-review` label, leaves the issue open,
   and exits.

### CLI Agent Invocation

The orchestrator, not the agent, handles all GitHub mutations. Agents only
produce prose.

```
# Prompt construction
prompt = Roundtable.Prompt.build(brief_path, issue_json, agent_role)

# Invocation (per-agent headless flags confirmed against installed versions)
claude 2.1.83:    claude -p --output-format json  <<< prompt
codex 0.116.0:    printf prompt | codex exec - --json --output-last-message /tmp/out
gemini 0.35.0:    gemini -p prompt --output-format json

# Posting (orchestrator side effect)
gh issue comment <n> --body-file <rendered_response>
gh issue edit    <n> --add-label satisfied --remove-label needs-more-evidence
gh issue close   <n>
```

**Q1 caveat (Codex):** headless flags and auth preconditions confirmed
locally. One live end-to-end scripted run per agent is still needed to
characterise output truncation/edge cases before hardening the parser.
This is a production-hardening item, not a blocker for the v1 scaffold.

### Implementation Form — Elixir/Mix + Nix Flake

- `mix new roundtable --sup` with `{:jido, "~> 2.0"}` in `mix.exs`.
- Entry point: `mix run -e 'Roundtable.CLI.main(["docs/design/BRIEF.md"])'`
- Nix flake provides a `devShell` with Elixir + Erlang + `gh` + the three
  CLI agents. A `packages.default` app output wraps `mix run` as `roundtable`.
- No Docker, no external database, no message broker.

---

## What Needs Building (Domain Pieces)

Jido provides the runtime. These modules are project-specific:

| Module | Responsibility |
|---|---|
| `Roundtable.Actions.RunCliAgent` | `System.cmd/3` wrapper for claude/codex/gemini |
| `Roundtable.Actions.Gh.*` | `gh issue view/comment/edit/close` wrappers |
| `Roundtable.Prompt` | Assemble BRIEF.md + issue JSON + agent role → prompt string |
| `Roundtable.Satisfaction` | Parse/apply label policy from agent response |
| `Roundtable.Scheduler` | Round-robin agent order, dependency-aware question sequencing |
| `Roundtable.CLI` | Entry point: parse BRIEF, create/load issues, run rounds |

---

## What Is Deferred

- `jido_ai` integration — defer to v2; IC triage uses raw `claude -p` in v1
- Filesystem-only offline fallback mode — defer; GitHub Issues is the primary path
- Parallel question execution — implement after sequential single-question
  proof-of-concept works end-to-end
- Automated issue creation from BRIEF.md — v1 may create issues manually;
  automate in v2
- `OpenCodeHarness` backend — defer to v2; enables GitHub Copilot and Opencode
  Go as first-class participants via `opencode serve` HTTP API
- `GitHubAPI` and `CodeStorage` git backends — defer to v2; `LocalGit` is
  sufficient for v1 finalization writes

## Protocol Updates (from Q15 discussion)

Three changes to the satisfaction-convergence protocol derived from comparing
it to the YC founder interview protocol:

**1. Rotating skeptic role**
The IC may assign `[role: skeptic]` to one agent per round when convergence
looks premature. The skeptic's mandate is to actively disconfirm — challenge
assumptions, find the missing evidence, argue against the emerging consensus.
This role is temporary and scoped to the round; it is not a standing persona.

**2. Majority convergence + noted dissent (no skeptic veto)**
Closure does not require unanimous satisfaction from every agent. After
`max_skeptic_rounds` (default: 1 additional round beyond majority consensus),
the IC may close with `[closed-with-dissent: X]`, recording the minority
position in the issue thread and in the decision record. The dissent is
preserved, not erased — but it is not a veto. This separates the right to be
heard from the power to block.

**3. Execution gate binary outcomes**
The orchestrator emits binary decisions at defined execution gates: merge PR,
ship v1, grant permission, proceed to next work item. The web dashboard
(item 10) surfaces these as owner action buttons, backed by the graduated
discussion record that justifies them. Graduated markers are for understanding
phases; binary outputs are for gating/authority phases.

---

## Protocol Updates (from Q16 discussion)

Two additional design decisions derived from the agent memory and model
diversity discussion:

**4. Agent memory policy — three classes**

Memory partitioning by class is the decided approach. Memory yes/no is the
wrong frame.

| Class | Persistence | Policy |
|---|---|---|
| `project_knowledge` | Durable, per-project | Allowed; read-only during deliberation |
| `process_memory` | Ephemeral per issue | Allowed; writable during active round |
| `consensus_memory` | Must not persist | Forbidden for independent deliberation voices |

`consensus_memory` must not persist silently across rounds for any agent
declared as an independent deliberation voice. Prior `[satisfied]` /
`[needs more evidence]` positions, unrecorded synthesis from previous rounds,
and latent "I already agreed with X" commitments all fall in this class.

A historian/continuity role may persist `consensus_memory` across rounds,
but must be declared non-independent in the round config.

The `AgentHarness` config accepts memory policy explicitly:

```elixir
%{
  harness: :hermes,             # or :vendor_cli, :opencode
  memory_scope: :project,
  memory_write: false,
  memory_classes: [:project_knowledge]
}
```

Memory backend (Letta, Zep, Hermes provider) is a v2 configuration item;
defer until `AgentHarness` has a concrete v1 implementation to attach it to.

**5. Model roster policy — 3 default, cost-constrained escalation**

The current three-family roster (Anthropic / OpenAI / Google) is the v1
default. Additions should be ranked:

1. New provider family (DeepSeek, Kimi) — independent training stack, most
   value per voice
2. New deployment profile (local / open-weight vs hosted frontier)
3. Same-vendor tier specialization (Opus vs Sonnet) — role differentiation,
   not independence

DeepSeek is the highest-value next addition: independent training, ~15x lower
cost per token, strong long-context reasoning.

Same-vendor tiers share training corpora and architectures; treat them as role
assignments, not independent voices.

Diminishing returns begin around four to five voices unless roles are strongly
specialized.

Default orchestrator scheduling:
- 3-agent round by default
- Escalate to 4th/5th specialist agent when `needs-more-evidence` persists
  past `max_skeptic_rounds` or the question is high-leverage
- Optional: Opus as IC for difficult rounds; DeepSeek for high-volume
  iterative turns

---

## Open Questions (not yet decided)

**PR review as a coordination surface**

The current orchestrator design handles the discussion loop (Issues) and the
artifact write loop (git commits). It does not yet handle the implementation
loop: agent opens PR → review bot comments → agent addresses comments → PR
merges. This is a distinct event stream (PR review comments, CI checks, bot
feedback) that the orchestrator will eventually need to drive. Defer to v2;
the PR review loop requires `Roundtable.Actions.Gh` to be extended with
`pr_create`, `pr_view`, and `pr_comment` wrappers, and the Orchestrator
state machine to add a `:pr_review` state between `:round_in_progress` and
`:satisfied`.

**Q10.3 — Mid-discussion join context**

What compressed context does a new agent receive when joining a discussion that
is already in progress (e.g., round 3 of 5)?

Options:
- Full issue comment history (accurate but token-expensive at round 3+)
- Last N comments only, same as a turn prompt (cheap but loses early positions)
- IC-generated summary comment posted to the issue before the join turn (accurate,
  bounded, but requires an extra IC invocation)
- Current satisfaction state only: open questions + current labels, no prose

No decision made. Discover empirically when the orchestrator first attempts to
add a late-joining agent. The `Roundtable.Prompt` `join: true` path (item 05)
should leave this configurable rather than hardcoding one approach.

---

## Starting Point

```
mix new roundtable --sup
cd roundtable
# Add to mix.exs deps: {:jido, "~> 2.0"}
mix deps.get
# Implement in order:
# 1. Roundtable.Actions.Gh       — gh CLI wrappers (unit-testable with mock)
# 2. Roundtable.Actions.RunCliAgent — CLI agent invocation
# 3. Roundtable.Satisfaction     — label policy
# 4. Roundtable.Prompt           — prompt assembly
# 5. Roundtable.Orchestrator     — Jido.Agent with cmd/2 loop
# 6. Roundtable.CLI              — entry point
# 7. flake.nix                   — devShell + app wrapper
```

Build `Gh` actions first — they are the most testable (mock `System.cmd/3`)
and the most likely source of environment-specific surprises (auth, rate limits,
field names in `gh --json` output).

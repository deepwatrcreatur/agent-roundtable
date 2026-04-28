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

---

## Protocol Update 6 — Mobile Supervision Architecture (Q18, 2026-04-28)

**Decision:** Companion REST + SSE API is the canonical mobile contract; LiveView dashboard is the primary browser UI.

### Ruled out
- **LiveView Native** — archived February 10, 2026. Do not use.
- **OpenCode fork as primary path** — satisfaction labels and round triggering absent from OpenCode data model; upstream moves at ~1 release/day. Deferred to v2 if supervision scope expands.

### Required additions (v1)

**Push notifications:**
- Orchestrator emits HTTP POST to ntfy.sh on `consensus_reached` and `needs_human_review` events.
- Config: `NTFY_TOPIC` env var. When unset, notifications are silently skipped.
- ntfy.sh is the default backend (self-hostable, free iOS app). Pushover is an acceptable alternative via the same abstraction.

**Companion API (new module: `RoundtableWeb.ApiController`):**
```
GET  /api/state             — map of issue_number => state_map (same shape as get_discussion_state/1)
GET  /api/events            — SSE stream; events: agent_done, round_start, consensus_reached, needs_human_review
POST /api/questions         — body: {text: String} — calls inject_question/3
POST /api/rounds/trigger    — body: {} — calls start_discussion/2 in background Task
```
Authentication: bearer token in `Authorization` header; token set via `ROUNDTABLE_API_TOKEN` env var.

**PWA:**
- LiveView dashboard served with `manifest.json` (name, icons, display: standalone, start_url: /).
- iOS 16.4+ Web Push via Service Worker is the alerting path for home-screen installs.

### Mobile supervision feature classification
| Task | Mechanism | Real-time |
|---|---|---|
| Watch | SSE `/api/events` | Yes |
| Alert | ntfy.sh / Pushover push | Yes (out-of-app) |
| Inject | POST `/api/questions` | No |
| Trigger | POST `/api/rounds/trigger` | No |

Apple Shortcuts can drive Inject and Trigger against the companion API with no native app required.


---

## Protocol Update 7 — Orchestrator Structural Improvements (Q19, 2026-04-28)

**Decision:** Three concrete structural improvements derived from the agent orchestration framework survey (Symphony, LangGraph, AutoGen/AG2, CrewAI, Temporal).

### New work items to implement (items 11, 12, 13)

**Item 11 — `Roundtable.RoundRun` persisted state**
```elixir
%Roundtable.RoundRun{
  issue_number: pos_integer(),
  phase: :awaiting_turns | :triage_missing_markers | :consensus_check
        | :closed | :needs_human_review | :needs_human_input,
  expected_speakers: [atom()],
  completed_speakers: [atom()],
  last_comment_ids: [String.t()],
  satisfaction_map: %{atom() => atom()},
  retry_count: non_neg_integer()
}
```
Persisted to ETS + periodic flush to `state/` git-tracked directory. On restart, reconcile from `gh issue view --json labels,state,comments`.

**Item 12 — Explicit phase state machine in `Roundtable.Orchestrator`**
Replace recursive `do_rounds/7` with named phase transition functions. Each phase function is pure: takes `RoundRun`, returns `{next_run, [effect]}`. Effects (gh calls, CLI invocations) are applied separately. Makes phases testable and replay-safe.

Phase transitions:
```
:awaiting_turns
  → all expected speakers completed → :triage_missing_markers
  → max_rounds exceeded → :needs_human_review

:triage_missing_markers
  → all markers present → :consensus_check
  → IC triage completes → :consensus_check

:consensus_check
  → all [satisfied|satisfied-conditional], no [needs-more-evidence] → :closed
  → any [needs-more-evidence] → :awaiting_turns (next round)
  → max_rounds → :needs_human_review

:needs_human_input  (new — HITL interrupt)
  → operator approves/dismisses → resumes from suspended phase
```

**Item 13 — OTEL span taxonomy**
Define and emit spans for each orchestrator event:
```
roundtable.issue.poll       — gh issue view call
roundtable.agent.turn       — RunCliAgent invocation (includes agent, issue_number)
roundtable.gh.comment       — gh issue comment post
roundtable.satisfaction.parse — marker extraction from agent response
roundtable.ic.triage        — IC classification call
roundtable.consensus.check  — Satisfaction.consensus? evaluation
roundtable.issue.close      — gh issue close
```
Wire via Jido telemetry. Export to OTEL collector in prod; log to structured stdout in dev.

### LiveView dashboard updates (item 10 extension)
- Display current `RoundRun.phase` per question alongside satisfaction badge
- Show `completed_speakers` vs `expected_speakers` progress
- Add approve/dismiss button for `:needs_human_input` phase

### What was ruled out
- Importing LangGraph, Temporal, or AutoGen as runtimes — borrow patterns, not runtimes
- Conductor pre-stage (Symphony-style agent selector) — deferred to v2
- Directed IC routing (re-invoke specific agent) — deferred to v2
- Replacing Jido with another runtime — Jido is the right substrate

### Correction — Symphony is Elixir, not Python (2026-04-28)

The Q19 IC synthesis incorrectly characterised `openai/symphony` as Python-based. **Correction:**

- **Symphony the spec:** language-agnostic (`SPEC.md`).
- **Symphony the reference implementation:** written in **Elixir** (95.5% of repo). OpenAI's April 27, 2026 post explicitly states: *"The reference implementation is written in Elixir"* and cites concurrency and OTP supervision as the reason.
- Gemini's Q19.1 Elixir claim was correct; the IC's rejection of it was wrong and is retracted.
- Consequence: Symphony is a **directly relevant Elixir reference architecture**, not just a tangential comparison. Its workspace isolation, boot reconciliation, and `WORKFLOW.md` policy patterns are worth studying before extending the v2 implementation loop.
- Work items 11, 12, 13 (derived from architectural patterns, not implementation language) are unaffected.

---

## Protocol Update 8 — Coordinator Failover and Degraded-Mode Continuity (Q20 precondition, 2026-04-28)

**Decision:** The system must treat **coordinator/IC unavailability** as a
first-class orchestration failure mode, not an ad hoc human-relay event.

### Failure mode observed

During the Q20 handoff, the primary discussion leader became unable to
continue orchestration due to provider overload. The prompt already existed,
but round continuity depended on another agent informally noticing the stall,
taking over, and writing a continuity note.

That is operationally unsafe. A future autonomous orchestrator must detect
"leader stalled / provider degraded / synthesis not progressing" and either
resume via a standby coordinator or surface a structured human-review state.

### Required robustness additions

**Coordinator lease + heartbeat**
- Each active round has a recorded coordinator identity and lease timestamp.
- Coordinator writes a heartbeat on meaningful progress boundaries:
  prompt posted, agent position received, synthesis started, synthesis posted.
- If the lease expires without heartbeat, another eligible coordinator may take
  over and must record a continuity note.

**Resumable synthesis state**
- `Roundtable.RoundRun` must persist coordination metadata in addition to
  speaker progress:
  - `coordinator`
  - `coordinator_lease_expires_at`
  - `last_progress_at`
  - `suspended_phase`
  - `takeover_count`
- A takeover resumes from persisted state; it must not require rereading the
  full discussion from scratch to determine who already responded and what
  remains open.

**Degraded-mode phase**
- Add `:coordinator_unavailable` as an explicit orchestrator phase.
- Transition into it when coordinator retries/timeouts exceed threshold or
  provider health for the assigned coordinator is degraded.
- Exit paths:
  - standby coordinator takeover → resume prior suspended phase
  - human operator ack → `:needs_human_input`
  - repeated takeover failure → `:needs_human_review`

**Provider diversity for the coordinator role**
- The same provider family should not be a single point of failure for both
  participant reasoning and IC synthesis.
- Coordinator assignment must be swappable by config and by live takeover.

**Auditability**
- Every takeover must emit a structured event and write a durable continuity
  note to the discussion artifact.

### New work item

**Item 14 — Coordinator failover**
- standby coordinator selection policy
- lease/heartbeat persistence in `RoundRun`
- takeover transition rules in the phase state machine
- telemetry spans for takeover and degraded mode
- LiveView display of coordinator identity and degraded-state banner

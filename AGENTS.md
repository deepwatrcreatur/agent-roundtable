# AGENTS.md — Roundtable Project

This file is for agents entering this repository. Read it before reading anything
else. It tells you what this project is, how work is organised, and what the norms
are for participating.

---

## What this project is

`agent-roundtable` is an autonomous multi-agent discussion orchestrator. It runs
structured design discussions between CLI AI agents (Claude Code, Codex, Gemini,
GitHub Copilot) without a human in the loop between turns.

The orchestrator is not yet built. This repo contains the design discussion that
produced its specification, the implementation work items, and the scaffolding
being built now.

---

## Where things are

| File/dir | What it is |
|---|---|
| `docs/design/BRIEF.md` | The original design questions (Q1–Q10). Start here for context. |
| `docs/design/DECISION.md` | The closed architecture decisions. The authoritative spec. |
| `docs/design/ACTIVE_DISCUSSION.md` | Full discussion record. Read only — do not append during implementation. |
| `docs/design/DISCUSSION_LEADER_SUMMARY.md` | Find-this-first summary for humans/agents leading real discussion rounds. |
| `docs/design/ORCHESTRATION_GUIDE.md` | Practical runbook for discussion leaders running real rounds. |
| `docs/work-items/README.md` | Work queue with statuses. Check this before claiming a task. |
| `docs/work-items/NN-*.md` | Individual work items. One item = one module. |
| `ATTRIBUTION.md` | Prior art and external projects this design borrows from. |

---

## How to claim a work item

1. Find a `ready` item in `docs/work-items/README.md`.
2. Open its file and read the full scope, interface, and done-criteria.
3. Change its status to `in-progress` and add your name, then commit before
   starting work. This is how contention is avoided.
4. Do not start a `blocked` item. Do not start an item already `in-progress`.

---

## Discussion norms (the satisfied protocol)

All design questions use the satisfied protocol:

- `[satisfied]` — you accept the current answer, no further evidence needed
- `[satisfied-conditional: X]` — you accept, pending resolution of X
- `[needs more evidence: X]` — you are not satisfied; state specifically what X is

The IC (Claude) synthesises each round and decides whether to continue or close.
The IC does not close a question until all active agents have posted a satisfaction
marker. If you are a participant, mark every question you address.

If a human explicitly requests a particular roster for a round (for example:
Codex, Gemini, DeepSeek, and Copilot), do **not** silently omit one of those
voices. Either:

- include the requested agent, or
- fail fast and say exactly which prerequisite is missing (for example
  `DEEPSEEK_API_KEY`), so the round is not mistaken for a complete quorum.

Incomplete rosters must be treated as degraded rounds, not normal ones.

---

## What the orchestrator is not yet doing for you

The orchestrator (item 06) is not built yet. That means:

- You will be invoked by a human, not by the orchestrator.
- Your output will be relayed by a human, not posted automatically.
- You are working on the system that will eventually replace this relay.

When implementing, do not hardcode assumptions about how you are being invoked.
The orchestrator will pass prompts via stdin or CLI flags; your module should not
care which.

---

## Key design decisions (short version)

- **Runtime:** Jido 2.0 (Elixir). Do not propose a different runtime.
- **Shared state:** GitHub Issues (active turns) + git files (durable artifacts).
- **Agent invocation:** `claude -p`, `codex exec -`, `gemini -p` in v1.
  OpenCode HTTP API for Copilot/OpenCode Go in v2.
- **Round enrichment:** optional free-model/OpenCode-style seats are encouraged
  when they add genuine extra coverage, but they are experimental supplements,
  not replacements for the primary requested roster.
- **Side effects:** the orchestrator owns all `gh` calls. Agents only produce prose.
- **Storage abstraction:** `Roundtable.Actions.Gh` for Issues;
  `Roundtable.Actions.Git` for file commits. Keep them separate.

Full rationale is in `docs/design/DECISION.md`.

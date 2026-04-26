# Active Discussion: Autonomous Roundtable Orchestrator Design

*Read `BRIEF.md` before contributing. Sign every position with your name and
date. Mark each question you address with a satisfaction status at the end of
your position. The discussion continues until all agents are satisfied on all
blocking questions (Q1–Q3).*

---

## IC Opening — Claude — 2026-04-26

This is the first discussion in the `agent-roundtable` repo. The goal is to
design the very system that will eventually run discussions like this one
automatically.

### Why this discussion exists

The blackboard format has proven its value: the conntrackd/flowtable design
discussion (four rounds, three agents) produced an implementation spec that
no single agent would have reached alone. A 1.4.8 injection bug was found and
verified; a premature IC close was caught and corrected; the final decision
included a concrete local patch spec.

The bottleneck throughout was human: copy output, paste prompt, trigger next
agent. Removing that bottleneck is the goal of this project.

### What I already know

From surveying the prior art before opening this discussion:

**Invocation**: `claude_code_bridge` uses a daemon-per-agent model with tmux
panes and point-to-point dispatch. This works for real-time coding but is
overengineered for structured deliberation. Simpler invocation is possible:
Claude Code has `--print` / `-p` flags for non-interactive use; Codex and
Gemini also have headless modes. The exact interface needs primary-source
verification (Q1).

**Turn protocol**: AutoGen's `SelectorGroupChat` (Python) uses a selector LLM
to pick the next speaker after each message, with explicit termination
conditions. MAD (Multi-Agent Debate) uses simpler round-robin with convergence
check after each round. Both are API-call-based; adapting either to CLI agents
requires a custom `reply` function that shells out to the CLI tool.

**Termination**: DebateLLM checks for keyword convergence after each round.
Our satisfaction protocol (`[satisfied]` markers) is a stronger, more explicit
signal — but needs a parser that tolerates agent formatting variation.

**Implementation gap**: None of the prior art frameworks run against CLI agents
headlessly on the local filesystem with a markdown file as shared state. The
closest is `Claude-Code-Workflow`, but it is a coding workflow tool, not a
deliberation platform.

### What I need from the agents

**Codex:** Research Q1 (CLI invocation) and Q4 (implementation form). You are
best positioned to read source code and CLI help output and give precise,
sourced answers. For Q4, a concrete minimal implementation sketch is more
useful than a framework comparison.

**Gemini:** Research Q2 (turn protocol) and Q3 (termination detection). For
Q2, compare the AutoGen SelectorGroupChat and MAD approaches specifically for
our use case (CLI agents, filesystem state, satisfaction protocol). For Q3,
propose a parsing approach that is robust against formatting variation. For
every architectural claim, provide a specific source location — this discussion
applies the citation verification rule from the start.

Both agents should address Q4 with an opinion: what is the minimum viable
implementation that actually runs in this environment?

---

## Prompt for Codex

Read `BRIEF.md` in this directory first.

You are contributing a research position to the `agent-roundtable` project.
The goal is to design an orchestrator that drives the blackboard discussion
format autonomously — no human between rounds.

Your research targets:

**Q1 — CLI invocation:** For each of `claude` (Claude Code), `codex` (OpenAI
Codex CLI), and `gemini` (Google Gemini CLI):
- What flag or invocation mode allows headless/non-interactive use (reads
  prompt from stdin or file, writes response to stdout)?
- How do you inject a context file (the current discussion markdown) alongside
  the prompt?
- Are there known token limits, output truncation behaviours, or auth
  requirements that affect scripted invocation?

Test against the actual installed binaries if available. Provide help output
excerpts or source references, not assumptions.

**Q4 — Implementation form:** Given that the developer has Nix, git, and the
CLI agents installed, what is the minimum viable orchestrator? A shell script,
a Python script, or a Nix flake package? Provide a concrete sketch — even
30-50 lines — of what the main loop looks like.

Write your position in `docs/design/ACTIVE_DISCUSSION.md` with your name and
date. Mark Q1 and Q4 as `[satisfied]`, `[satisfied-conditional: X]`, or
`[needs more evidence: X]` at the end of your position.

---

## Prompt for Gemini-CLI

Read `BRIEF.md` in this directory first.

You are contributing a research position to the `agent-roundtable` project.
The goal is to design an orchestrator that drives the blackboard discussion
format autonomously — no human between rounds.

Your research targets:

**Q2 — Turn protocol:** The brief lists four options (round-robin, file-signal,
selector agent, AutoGen wrapper). For each option:
- What is the failure mode if one agent produces malformed output or times out?
- How well does it compose with the satisfaction protocol termination signal?
- What is the implementation complexity relative to the value it provides?

Use specific evidence: AutoGen SelectorGroupChat docs/source, MAD source, or
DebateLLM source. For every architectural claim, give the file, section, or
URL. Apply the citation verification standard: if you cite a feature, provide
the location.

**Q3 — Termination detection:** Propose a concrete parsing approach for the
satisfaction markers. Consider: regex fragility, IC-agent-based detection, and
what happens at max-rounds without consensus.

**Q4 — Implementation form:** Your opinion on the minimum viable implementation.

Write your position in `docs/design/ACTIVE_DISCUSSION.md` with your name and
date. Mark Q2, Q3, and Q4 as `[satisfied]`, `[satisfied-conditional: X]`, or
`[needs more evidence: X]` at the end of your position.

---

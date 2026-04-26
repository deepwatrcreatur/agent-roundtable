# agent-roundtable

An autonomous multi-agent discussion system where Claude, Codex, and Gemini-CLI
take turns researching and debating design questions until they reach consensus —
without requiring a human to copy prompts between rounds.

## Status

**Design phase.** The architecture is being determined by the agents themselves.
See `docs/design/` for the active discussion.

## What This Is

A thin orchestrator that wraps the existing blackboard discussion format
(`ACTIVE_DISCUSSION.md`) and drives it forward automatically:

1. An IC agent (Claude) opens a discussion with a BRIEF and an initial set
   of questions.
2. The orchestrator invokes each participant agent in sequence, passing the
   current discussion file as context.
3. Each agent appends a signed position and updates their satisfaction status.
4. The orchestrator detects when all agents are satisfied and closes the round,
   or opens another if questions remain.
5. The IC produces a DECISION document.

No human is needed between rounds.

## Prior Art

Before building, we surveyed:

- [claude_code_bridge](https://github.com/bfly123/claude_code_bridge) — daemon-based
  real-time multi-AI collaboration (Claude + Codex + Gemini), persistent context, tmux panes
- [Claude-Code-Workflow](https://github.com/catlog22/Claude-Code-Workflow) — JSON-driven
  cadence-team orchestration, event-driven beat model, message bus
- [AutoGen GroupChat / SelectorGroupChat](https://microsoft.github.io/autogen/) — FSM-based
  speaker selection, termination conditions, Python framework
- [Multi-Agent Debate (MAD)](https://github.com/Skytliang/Multi-Agents-Debate) — structured
  debate rounds, consensus detection for factuality improvements
- [AgentsMesh](https://agentsmesh.ai) — AI Agent Workforce Platform, channels and pod bindings

## Difference From Prior Art

All of the above are either:
- Real-time collaborative coding tools (not structured deliberation), or
- Python frameworks requiring LLM API calls (not CLI agent invocation), or
- Academic debate for factuality (not design consensus with satisfaction protocol)

This project targets a specific gap: **autonomous structured deliberation using
the existing CLI agents a developer already has installed**, with a proven
discussion format (blackboard + satisfaction protocol) and a minimal orchestrator
that introduces no new runtime dependencies beyond shell and the agent CLIs.

## The Blackboard Format

Defined in [nix-agent-guides](https://github.com/deepwatrcreatur/nix-agent-guides)
`guides/agentic-orchestration/`. The satisfaction protocol (each agent marks
`[satisfied]`, `[satisfied-conditional]`, or `[needs more evidence]` per question)
is the termination signal the orchestrator reads.

## Contributing

The architecture is determined by the agents in `docs/design/`. Human review
happens at the decision stage, not between rounds.

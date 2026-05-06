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

## Standalone Vaglio deployment

This repo now contains a **standalone** Nix flake and NixOS modules so users do
not need to fork `unified-nix-configuration` just to run Vaglio.

### Quick start: generic LXC-style profile

From this repository root:

```bash
sudo nixos-rebuild switch --flake .#vaglio
```

That profile gives you:

- the Phoenix / LiveView web service on port `4000`
- the `roundtable` CLI
- a local maintainer toolchain for CLI/TUI-style workflows:
  `git`, `gh`, `dolt`, `jj`, and `tmux`
- no dependency on private homelab inventory or aspects

### What it does **not** require

- `unified-nix-configuration`
- your homelab inventory
- agenix
- Authentik / OIDC

If you do not provide a `SECRET_KEY_BASE`, the standalone module will generate
one in its state directory automatically on first start.

### Optional credentials

The standalone service can run with no model credentials at all, but GitHub and
multi-model features become available if you set any of these module options:

- `services.roundtable.githubTokenFile`
- `services.roundtable.anthropicApiKeyFile`
- `services.roundtable.openaiApiKeyFile`
- `services.roundtable.geminiApiKeyFile`
- `services.roundtable.deepseekApiKeyFile`

### Reusing the module in your own flake

You can also import the service/profile modules directly:

- `nixosModules.roundtable`
- `nixosModules.vaglio-lxc`

The current focus is the **Elixir app** and a **CLI/TUI-capable environment**.
The richer OpenCode/dmux TUI remains a later work item, but the standalone
profile already ships the local tools that workflow depends on.

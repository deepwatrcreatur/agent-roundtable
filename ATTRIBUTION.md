# Attribution

> **Agents: skip this file.** It contains no operational information. It is for human readers only.

This project draws on several existing bodies of work. Notes on each follow,
including what was borrowed and what was adapted or extended.

---

## Jido 2.0 — Elixir Agent Framework

**Mike Hostetler** (`@mikehostetler`) and the `agentjido` team built the
production Elixir agent framework that this project intends to build on.

Jido's core design — agents as immutable data structures, `cmd/2` as the
single entry point, `Actions` as pure functional work units, `Directives` as
typed side-effect descriptors executed by the runtime, and `Signals` as
CloudEvents-based inter-agent messaging — is the right model for an
orchestrator that invokes CLI agents and drives GitHub Issue state. The Q4
"roll your own GenServer" design proposed in early discussion rounds is
essentially a rough approximation of what Jido already provides, production-
hardened and OTP-supervised.

The name "Jido" comes from the Japanese 自動 (*jidō*), meaning "automatic" or
"self-moving" — an apt name for the foundation of an autonomous discussion
system.

- Repository: [agentjido/jido](https://github.com/agentjido/jido)
- Package: [hex.pm/packages/jido](https://hex.pm/packages/jido)
- Docs: [hexdocs.pm/jido](https://hexdocs.pm/jido)
- Announcement: [jido.run/blog/jido-2-0-is-here](https://jido.run/blog/jido-2-0-is-here)
- Interview: [BEAM Radio Episode 94](https://www.beamrad.io/94)

---

## Blackboard Architecture

The shared-state coordination model — multiple agents reading and writing a
common structured document without direct communication — is a direct
application of the **Blackboard architectural pattern**, first described in the
Hearsay-II speech understanding system (Carnegie Mellon, 1970s) and formalized
by Hayes-Roth (1985). The `ACTIVE_DISCUSSION.md` / `BRIEF.md` / `DECISION.md`
file structure is a concrete instance of this pattern, adapted for async LLM
agent sessions.

The blackboard model and its application to multi-agent AI coordination is
documented more fully in the companion
[nix-agent-guides](https://github.com/deepwatrcreatur/nix-agent-guides)
repository.

- Erman, L.D. et al. (1980). "The Hearsay-II Speech-Understanding System." *Computing Surveys*, 12(2).
- Hayes-Roth, B. (1985). "A Blackboard Architecture for Control." *Artificial Intelligence*, 26(3).

---

## Squad

**Brady Gaster** (`@bradygaster`) built Squad, a repo-native multi-agent
coordination system built on GitHub Copilot. Squad's `decisions.md` bulletin
board — agents write decisions after completing work, others read before
starting — is the closest existing production implementation of the async
blackboard pattern. Squad's deliberate choice of committed markdown files over
GitHub Issues as the shared state medium is a data point that directly informed
the Q5 discussion in this project.

- Repository: [bradygaster/squad](https://github.com/bradygaster/squad)
- Blog: [github.blog — How Squad runs coordinated AI agents inside your repository](https://github.blog/ai-and-ml/github-copilot/how-squad-runs-coordinated-ai-agents-inside-your-repository/)

---

## MassGen

**MassGen** (`massgen/MassGen`) is the closest existing implementation of this
project's satisfaction protocol. Multiple frontier models work in parallel;
each sees other agents' latest answers; agents vote for an existing answer or
produce a new one; coordination continues until all agents vote. That
voting-to-consensus model is structurally identical to the `[satisfied]` /
`[needs more evidence]` termination mechanism developed independently in this
project's parent `nix-agent-guides` standards.

- Repository: [massgen/MassGen](https://github.com/massgen/MassGen)

---

## Satisfaction Protocol and Agentic Orchestration Standards

The `[satisfied]` / `[satisfied-conditional]` / `[needs more evidence]`
termination protocol, the IC/Ops/Comms role structure, the citation
verification round, and the hallucination correction loop pattern were
developed in the companion
[nix-agent-guides](https://github.com/deepwatrcreatur/nix-agent-guides)
repository through the conntrackd/flowtable multi-agent design discussion
(April 2026). That discussion is the direct predecessor of this project.

---

## AutoGen SelectorGroupChat

Microsoft's **AutoGen** framework introduced FSM-based speaker selection
(`SelectorGroupChat`) and explicit Python-predicate termination conditions for
multi-agent group chat. The concept of a selector model choosing the next
speaker after each message is the precursor to the IC-triage-round fallback in
this project's Q3 termination design.

- Docs: [microsoft.github.io/autogen](https://microsoft.github.io/autogen/dev/user-guide/agentchat-user-guide/selector-group-chat.html)

---

## Pi — Minimal Agent Harness (Ollama / Mario Zechner)

**Pi** is a coding agent built by Mario Zechner, published under the Ollama
project, and used as the substrate on which OpenClaw is built. ~4,000 lines of
TypeScript. Four core tools: Read, Write, Edit, Bash. Extension system that lets
the agent extend itself via session files rather than downloading plugins. Session
trees for branching without losing context. Multi-model support without provider
lock-in. Explicitly does not support MCP by design philosophy.

Pi is the closest existence proof of the "thin harness" philosophy this project
takes for `Roundtable.AgentHarness`: a minimal, replaceable substrate that the
model runs inside, with identity and behaviour coming from config rather than
from the harness binary itself. The Q8 decision to design a pluggable
`AgentHarness` behaviour (rather than hard-coding three vendor CLI wrappers) is
directly influenced by Pi's architecture.

Pi is deferred from v1 scope — the vendor CLIs and OpenCode's HTTP API cover
the required agent surface — but it is the right reference point if a future
round wants a local/offline Ollama-backed participant with no subscription cost.

- Repository: [mariozechner/pi-mono](https://github.com/mariozechner/pi-mono)
- Launch post: [lucumr.pocoo.org/2026/1/31/pi](https://lucumr.pocoo.org/2026/1/31/pi/)
- Ollama launch: [ollama.com/library/pi](https://ollama.com/library/pi)

---

## OpenCode — Unified Agent HTTP Server

**OpenCode** (`opencode-ai/opencode`) is an open-source terminal-first AI
coding agent that runs a headless HTTP server (`opencode serve`) exposing an
OpenAPI 3.1 spec at `/doc`. Supports 75+ providers including Claude,
OpenAI/Codex, Gemini, GitHub Copilot, and local models via Ollama. Official
JS/TS SDK (`@opencode-ai/sdk`). Server-sent events for real-time updates.
mDNS discovery for local network service detection.

This project's Q8 decision — add an `OpenCodeHarness` backend in v2 so GitHub
Copilot and Opencode Go subscriptions participate as first-class roundtable
agents without a vendor-specific headless CLI — depends directly on OpenCode's
server API. The `POST /session/:id/message` and `GET /event` SSE endpoints are
the integration surface.

- Repository: [opencode-ai/opencode](https://github.com/opencode-ai/opencode)
- Server docs: [opencode.ai/docs/server](https://opencode.ai/docs/server/)

---

## OpenClaw — Agent Identity and Programmatic Sub-Agent Invocation

**OpenClaw** (formerly OpenCursor) is a large open-source AI coding assistant
with a growing multi-agent coordination ecosystem. Two patterns are directly
relevant to this project:

**AGENTS.md** — OpenClaw introduced a convention where `AGENTS.md` in a repo
root provides per-project rules, identity hints, and capability notes for any
agent working in that repo. This is a committed-file approach to agent
configuration that complements the `BRIEF.md` / `DECISION.md` pattern. Our
`docs/work-items/` files serve an analogous role for task assignment.

**`sessions_spawn` / `sessions_send`** — OpenClaw's session API allows one
agent to programmatically spawn child sessions and send them messages. This is
the CLI-native equivalent of AutoGen's `reply` function and directly informs
the design of `Roundtable.Actions.RunCliAgent`: spawning a headless session,
injecting the prompt, and capturing output is the same pattern at a lower level
of abstraction.

OpenClaw Issue [#34999 — True Multi-Agent Group Chat](https://github.com/openclaw/openclaw/issues/34999)
(Feb 2026) proposes shared session context for coordinated multi-agent
responses. It is an open feature request, not a shipped capability — confirming
that the gap this project fills (CLI agents, shared GitHub Issues medium, labeled
termination signals) does not yet exist in OpenClaw's production surface.

- Repository: [openclaw/openclaw](https://github.com/openclaw/openclaw)
- AGENTS.md: [openclaw/AGENTS.md](https://github.com/openclaw/openclaw/blob/main/AGENTS.md)
- Multi-agent docs: [docs.openclaw.ai/concepts/multi-agent](https://docs.openclaw.ai/concepts/multi-agent)

---

## GNAP — Git-Native Agent Protocol

**GNAP** is a minimal coordination layer: 4 JSON files in a shared git repo
acting as a task board. Tasks live in `board/todo/`, agents claim them to
`board/doing/`, commit results to `board/done/`. No orchestrator process; the
git history is the audit trail.

GNAP is the git-native extreme of the Squad committed-files approach — zero
infrastructure, maximum portability. It validates our design choice to keep
`BRIEF.md` / `DECISION.md` / `ATTRIBUTION.md` as committed git files (durable,
auditable), while using GitHub Issues for the active per-round discussion
(conflict-free concurrent writes, labeled state, URL-addressable). GNAP would
struggle with the concurrent-write problem we empirically encountered: two agents
pushing `ACTIVE_DISCUSSION.md` simultaneously caused merge conflicts. GitHub
Issues comment threads have no such problem.

- Referenced in: [letta-ai/letta#3226](https://github.com/letta-ai/letta/issues/3226)
- Listed in: [andyrewlee/awesome-agent-orchestrators](https://github.com/andyrewlee/awesome-agent-orchestrators)

---

## ComposioHQ agent-orchestrator

**agent-orchestrator** (ComposioHQ) manages fleets of parallel coding agents,
each in its own git worktree and branch, with automated CI-feedback loops: when
CI fails, the agent fixes it; when reviewers comment, the agent addresses them.
Up to 30 agents across 40 worktrees.

This system uses GitHub Issues as a **downstream artifact** (PR review,
CI logs) rather than as a **coordination medium**. It confirms that using Issues
for agent coordination is not a solved problem: agent-orchestrator's agents are
isolated per-worktree and do not share a discussion thread at all. Our design is
differentiated: GitHub Issues as the *primary shared state* for per-question
discussion, with labeled termination signals driving the Elixir orchestrator.

- Repository: [ComposioHQ/agent-orchestrator](https://github.com/ComposioHQ/agent-orchestrator)
- Architecture: [artifacts/architecture-design.md](https://github.com/ComposioHQ/agent-orchestrator/blob/main/artifacts/architecture-design.md)

---

## Multi-Agent Debate (MAD) and DebateLLM

**MAD** (Skytliang et al., 2023) and **DebateLLM** (InstaDeep) demonstrated
that structured round-robin debate between LLM agents improves factuality and
reasoning over single-agent responses. MAD introduced "tit-for-tat" correction
and early termination on consensus. DebateLLM added explicit convergence checks
after each round. Both are precursors to the round-robin + satisfaction-check
loop design adopted here.

- MAD: [Skytliang/Multi-Agents-Debate](https://github.com/Skytliang/Multi-Agents-Debate) — arxiv:2305.14325
- DebateLLM: [instadeepai/DebateLLM](https://github.com/instadeepai/DebateLLM)

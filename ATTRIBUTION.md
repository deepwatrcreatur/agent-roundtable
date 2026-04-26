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

## Multi-Agent Debate (MAD) and DebateLLM

**MAD** (Skytliang et al., 2023) and **DebateLLM** (InstaDeep) demonstrated
that structured round-robin debate between LLM agents improves factuality and
reasoning over single-agent responses. MAD introduced "tit-for-tat" correction
and early termination on consensus. DebateLLM added explicit convergence checks
after each round. Both are precursors to the round-robin + satisfaction-check
loop design adopted here.

- MAD: [Skytliang/Multi-Agents-Debate](https://github.com/Skytliang/Multi-Agents-Debate) — arxiv:2305.14325
- DebateLLM: [instadeepai/DebateLLM](https://github.com/instadeepai/DebateLLM)

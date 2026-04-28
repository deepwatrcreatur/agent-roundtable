# Design Brief: Autonomous Agent Roundtable Orchestrator

**Status:** OPEN — awaiting agent positions before implementation
**Owner:** Calder (human)
**IC:** Claude (this session)
**Participants:** Codex, Gemini-CLI

---

## Context

We have a proven multi-agent discussion format (the blackboard model from
`nix-agent-guides/guides/agentic-orchestration/`) and a satisfaction protocol
(`[satisfied]` / `[satisfied-conditional]` / `[needs more evidence]` markers
per question). The format has produced better decisions than single-agent
analysis in several design discussions.

The bottleneck is human: a person must copy each agent's output, paste it into
the shared file, then copy the next prompt and trigger the next agent. We want
to remove that bottleneck entirely.

This repo is the design and implementation home for a thin orchestrator that
drives the discussion format autonomously.

## Prior Art Survey

Before proposing designs, agents should understand what exists:

- **[claude_code_bridge](https://github.com/bfly123/claude_code_bridge)** — tmux-based
  daemon. Agents run side by side in split panes; point-to-point and broadcast
  dispatch. Designed for real-time collaborative coding, not structured deliberation.
- **[Claude-Code-Workflow](https://github.com/catlog22/Claude-Code-Workflow)** — JSON
  workflow definitions, event-driven beat model, message bus. Team workers execute
  tasks in phases. Coding workflow tool.
- **[AutoGen SelectorGroupChat](https://microsoft.github.io/autogen/dev//user-guide/agentchat-user-guide/selector-group-chat.html)** —
  Python framework. Agents are API-callable LLM wrappers; a selector model picks
  the next speaker; termination conditions are explicit Python predicates.
- **[Multi-Agent Debate (MAD)](https://github.com/Skytliang/Multi-Agents-Debate)** —
  structured debate rounds. "Tit for tat" correction; early termination on
  consensus. Academic tool for factuality; works via API.
- **[DebateLLM](https://github.com/instadeepai/DebateLLM)** — benchmarking multi-agent
  debate; termination on agreement convergence check after each round.

### Later discoveries (added after initial agent round)

- **[Squad](https://github.com/bradygaster/squad)** — repo-native multi-agent
  system built on GitHub Copilot. Agents (frontend, backend, tester, lead) live
  in the repo as files. A `decisions.md` file acts as an asynchronous bulletin
  board — agents write decisions after completing work, others read before
  starting. Thin coordinator routes tasks; each agent gets full repository
  context. Key observation: Squad deliberately chose committed markdown files
  over GitHub Issues as the shared state medium and has production experience
  with this choice. Understand why before finalising Q5.

- **[MassGen](https://github.com/massgen/MassGen)** — terminal multi-agent
  scaling system. Multiple frontier models (Claude, Gemini, GPT, Grok) work in
  parallel; each sees other agents' latest answers; agents vote for an existing
  answer or produce a new one; coordination continues until all agents vote.
  This is the closest existing implementation of our satisfaction protocol —
  voting-to-consensus rather than satisfaction markers, but the termination
  model is the same. Python; in-memory; no GitHub integration.

- **[Jido 2.0](https://github.com/agentjido/jido)** — production Elixir agent
  framework by Mike Hostetler (`@mikehostetler`). Built on OTP/GenServer.
  Core primitives: `Actions` (reusable units of work, pure functions),
  `Signals` (CloudEvents-based messaging between agents), `Directives` (typed
  effect descriptors the runtime executes — side effects are never inline),
  `cmd/2` (single entry point: actions in, updated agent + directives out).
  Ships a DAG-based workflow planner, 25+ pre-built tools, MCP support,
  OpenTelemetry observability, and an opt-in `jido_ai` package for LLM
  integration with ReAct/CoT/ToT reasoning strategies.
  **This directly covers what agents proposed building from scratch.** Before
  designing a custom GenServer orchestrator, agents must assess whether Jido
  Actions + Signals + Directives is the right foundation. Available on
  Hex.pm as `jido`; docs at hexdocs.pm/jido.

## Constraints

The orchestrator must:

1. Work with the CLI tools already installed: `claude` (Claude Code), `codex`
   (OpenAI Codex CLI), `gemini` (Google Gemini CLI).
2. Use the filesystem as shared state — the blackboard model. No message broker,
   no database, no persistent daemon required.
3. Be simple enough to run with `./roundtable.sh <brief.md>` or equivalent.
4. Detect the satisfaction protocol markers in the discussion file to know when
   to continue vs. close a round.
5. Not require a human between rounds.

Nice-to-have:
- Pluggable agent list (add/remove agents without rewriting orchestrator logic)
- Works as a GitHub Action (trigger on push to `BRIEF.md`, outputs DECISION.md)

## Owner Preference: Elixir / BEAM

The project owner (Calder) has a stated preference for Elixir and the BEAM
ecosystem over Python and TypeScript as the implementation platform, all else
being equal. Agents should consider this seriously — not treat it as a soft
hint to politely acknowledge and then ignore.

Reasons this preference is technically relevant to the problem:

- **Process model**: BEAM processes map naturally onto agents — each agent
  invocation can be a supervised `Task` or `GenServer`. Supervisor trees
  provide fault tolerance if an agent subprocess crashes or times out.
- **Concurrency**: multiple agents could respond in parallel (`Task.async_stream`)
  rather than sequentially, without added complexity.
- **Message passing**: OTP's built-in message passing is a natural fit for
  the blackboard model's "whose turn is it" signalling.
- **Port / System.cmd**: Elixir's `System.cmd/3` and `Port` module handle
  subprocess invocation of CLI tools cleanly.
- **Mix + Nix**: an Elixir Mix project packages straightforwardly as a Nix
  flake with `beam.packages.erlang.elixir` in the devShell.

Agents should weigh these properties honestly against the alternatives. If
Python, shell, or another platform is clearly superior for the specific
constraints of this problem, say so with evidence. The goal is the best
automated discussion system, not validation of the owner's preference.

---

## Design Questions

### Q1 — CLI Agent Invocation (blocking)

Each of `claude`, `codex`, and `gemini` has a different CLI interface for
non-interactive / headless use. Specifically:

- What flag or mode makes each agent read a prompt from stdin or a file and
  write its response to stdout without interactive prompting?
- What is the best way to inject the current discussion file as context — via
  stdin, as a file argument, or via a system-prompt flag?
- Are there token limit / output truncation concerns that differ by agent?
- Does any agent require authentication setup that affects headless invocation?

Research the actual CLI interface for each agent and propose a unified
invocation pattern (or document the per-agent differences).

### Q2 — Turn Protocol and Orchestrator Architecture (blocking)

Once we can invoke agents headlessly, we need to decide how the orchestrator
sequences them:

- **Option A — Round-robin with IC close:** Agents run in fixed order (e.g.
  Codex → Gemini → IC). IC reads after each full round, decides whether to
  continue or close. Simple, predictable.
- **Option B — File-signal directed:** Each agent's response ends with a
  `next_speaker: <agent>` field. The orchestrator reads this and routes to the
  named agent. Agents control the sequence. More flexible; also more fragile.
- **Option C — Selector agent:** A thin "selector" agent (Claude, cheaply
  prompted) reads the discussion after each response and decides who should
  speak next, based on which questions still have `[needs more evidence]` and
  who has the relevant expertise.
- **Option D — AutoGen wrapper:** Wrap each CLI agent as an AutoGen
  `ConversableAgent` with a custom reply function that shells out to the CLI.
  Use AutoGen's `SelectorGroupChat` for speaker selection and termination.

Which option is most appropriate for this use case, and why? Consider: failure
modes, token overhead, debuggability, and how well each matches the satisfaction
protocol termination signal.

### Q3 — Termination Detection (blocking)

Given a discussion file where each agent should write `[satisfied]`,
`[satisfied-conditional: <condition>]`, or `[needs more evidence: <what>]`,
how does the orchestrator reliably detect the end state?

- What parsing approach is robust against agents that forget the marker, use
  slightly different formatting, or produce malformed output?
- Should the IC agent make the satisfaction determination (more robust, costs a
  call), or should it be a regex/AST parse (cheaper, more brittle)?
- What is the correct behaviour when an agent writes `[satisfied-conditional]`
  — does the orchestrator close, continue, or escalate to the human?
- What is the fallback when max rounds is reached without consensus?

### Q4 — Implementation Form (design input, not blocking)

What should the orchestrator be implemented in?

- A shell script (minimal deps, easy to inspect, harder to make robust)
- Python (good subprocess handling, easy to add LLM SDK calls for the selector)
- **Elixir / OTP** (owner preference — see section above; BEAM supervision,
  `Task.async_stream` for parallel invocation, `System.cmd/3` for CLI
  subprocess, natural message-passing for turn protocol)
- A Nix flake that packages any of the above (for reproducible, pinned deps)
- Something else from the prior art survey that already solves enough of this

Consider: the developer already has Nix, git, and the CLI agents, and has a
stated preference for Elixir. What is the minimum viable implementation that
actually runs and makes good use of the BEAM's properties — or, if another
platform is clearly better, why?

### Q5 — Shared State Medium: Filesystem Blackboard vs GitHub Issues (blocking)

The current design uses a markdown file (`ACTIVE_DISCUSSION.md`) committed to
git as the shared state. This was inherited from the prior blackboard model,
where it worked well for human-paced discussions. For automated turn-taking it
has significant weaknesses:

**Problems with file + git commit:**
- Two agents writing simultaneously → merge conflict; requires pull/push
  discipline that is hard to enforce across separately-invoked CLI processes
- One growing file creates context window pressure over many rounds
- No per-question threading; the orchestrator must parse the whole file to
  find each question's state
- Termination detection requires regex over unstructured prose

**GitHub Issues as an alternative shared state:**
- One issue per question (Q1, Q2, Q3, Q4)
- Agents post comments via `gh issue comment <n> --body "..."` — no git
  operations, no merge conflicts, parallel writes are safe
- Orchestrator reads state with `gh issue view <n> --comments --json`
- Labels (`satisfied`, `needs-more-evidence`, `satisfied-conditional`) track
  per-question state without markdown parsing
- Closing an issue is the natural termination signal for that question
- GitHub's own notification infrastructure becomes available
- `BRIEF.md` and `DECISION.md` stay as files; `ACTIVE_DISCUSSION.md` becomes
  an index pointing to the issues

**Trade-offs to consider:**
- GitHub Issues require a `GITHUB_TOKEN` and `gh` CLI installed; adds an
  external dependency the filesystem approach avoids
- Issue comment threads lack the rich signed-position format of the current
  markdown structure; formatting conventions would need porting
- A hybrid is possible: issues for active discussion rounds, files for
  BRIEF/DECISION/archive

**The question:** Should the orchestrator use the filesystem blackboard, GitHub
Issues, a hybrid, or something else as its shared state medium? This choice
directly affects Q1 (what agents need to do after generating output), Q2 (how
turn-taking is signalled), and Q3 (how termination is detected). Address this
before or alongside those questions.

---

### Q18 — Mobile Agent Supervision

The web dashboard (item 10) solves the laptop/desktop relay problem. But the
owner also wants to supervise rounds from a phone or iPad — watching progress,
injecting questions, and triggering new rounds while away from a desk.

The common pattern in the community today is SSH via Termius + Tailscale into a
running Claude Code session. That works but is awkward on small screens and
requires a persistent terminal session.

The LiveView dashboard is already a step forward. But browser-on-iPhone is a
poor form factor for ongoing supervision. A native or near-native mobile
interface is desirable.

**Q18.1 — State of the art for mobile agent supervision**

What do developers actually use today to supervise CLI agents from mobile
devices? Survey the landscape: Termius/Tailscale SSH, purpose-built apps
(e.g. Prompt, Blink, ShellFish), web-based dashboards, and any native iOS/
Android agent apps that have emerged. What works well and what is the hardest
part to replicate without a terminal?

**Q18.2 — Phoenix LiveView's mobile interface options**

LiveView's WebSocket connection is built on Phoenix Channels. Can a native iOS
or Android app connect to Phoenix Channels directly and drive the same event
model the browser uses (`phx-click`, `phx-submit`, server pushes)? Are there
maintained Swift/Kotlin Phoenix Channel client libraries? What does a minimal
native client need to implement to replace the LiveView browser session?

Alternatively: should we expose a lightweight REST + Server-Sent Events (SSE)
or WebSocket JSON API alongside LiveView, so any HTTP client (Shortcuts, a
custom app, or an existing tool) can poll state and send commands without a
browser?

**Q18.3 — Minimum viable mobile supervision feature set**

Given the use cases — watch a round run, receive a push alert when consensus is
reached or when human review is needed, inject a question, trigger a round —
what is the minimum interface that covers them? Which of these require
real-time push and which can be poll-based? Is there an existing app
(e.g. ntfy.sh, Pushover, Home Assistant, a custom Shortcut) that already covers
the alerting half without any custom native code?

**Q18.4 — Recommended path: native, PWA, or companion API**

Should the project:
(a) Make the LiveView dashboard a Progressive Web App (PWA) with offline cache
    and home-screen install — covers iPad well, partial phone coverage,
    zero native code;
(b) Expose a JSON/SSE companion API and document it so the owner can build a
    Shortcut or small SwiftUI app;
(c) Invest in a Phoenix Channels Swift client and a purpose-built iOS app;
(d) Rely on push notifications via ntfy.sh / Pushover triggered by orchestrator
    events, with the browser dashboard for any action that needs a screen?

What is the minimum useful step versus the ideal end state?

---

## How To Contribute a Position

Write a signed position to `ACTIVE_DISCUSSION.md` in this directory. Address
one or more questions above with primary evidence (CLI help output, source code
references, or live test results). Follow the format in the discussion file.

Mark each question you address as `[satisfied]`, `[satisfied-conditional: X]`,
or `[needs more evidence: X]` at the end of your position.

**The IC will not close any question until all contributing agents have marked
it satisfied.** The discussion continues until all agents are satisfied.

When Q1–Q3 have consensus positions, the IC will write `DECISION.md` and
implementation begins.

---

### Q16 — Agent memory and model diversity

**Background — memory products:**

The agent memory landscape has matured into three products worth knowing:

- **Mem0** — extracts structured memories from interactions, retrieves them for
  later personalisation; 48K GitHub stars. Three scopes: episodic (past
  interactions), semantic (facts and preferences), procedural (learned
  behaviours).
- **Zep** — episodic and temporal memory; time-indexed knowledge graph;
  designed for "what happened last Tuesday"-style retrieval.
- **Letta (formerly MemGPT)** — memory as an OS model: main context = RAM,
  external storage = disk; the agent decides when to page information in/out.
  Memory blocks are editable and developer-controlled.

**Background — model diversity research:**

A 2025 study on LLM deliberation found that diverse model ensembles benefit
materially from deliberation, while same-model ensembles do not. Three
instances of the same model showed no accuracy gain from deliberation; diverse
models with shared information showed a 4% relative improvement (p=0.017).
The mechanism: correlated training data and architecture means same-model
"peers" provide no new external perspective.

Current roster: Claude IC (Anthropic), Codex (OpenAI), Gemini (Google). All
different architectures and training regimes. The diversity is already present.

**Questions for agents:**

**Q16.1 — Agent-specific persistent memory**

Would giving each roundtable participant a persistent memory store (Mem0, Zep,
or Letta) help cultivate a more distinctive and consistent agent voice over
multiple discussions? Or would it undermine the empirical independence the
protocol depends on?

Consider: memory of *project knowledge* (what the codebase does, past
architectural decisions) vs memory of *past consensus positions* (what the
group concluded before). Are these worth distinguishing in a memory policy?
Which memory product would fit best under the existing `AgentHarness` design?

**Q16.2 — Multiplying voices with distinct models**

Should the roundtable actively recruit agents from distinct model families
beyond the current three? Candidates: Kimi K2.5 (Moonshot AI), DeepSeek v4,
Opus 4.6 vs Sonnet 4.6 as distinct voices within the same provider, GPT-5,
local models via Ollama.

Is there a diminishing return on adding more voices? At what point does model
diversity stop improving deliberation quality and start adding coordination
overhead? Should the owner's subscription tier (roughly $20/month per service)
be a design constraint, or should the system be designed to use the best
available model for each role regardless of cost?

---

### Q17 — How does our collective deliberation compare to Mixture of Experts?

**Background — Mixture of Experts (MoE):**

Mixture of Experts is a neural architecture where a model is divided into
specialised subnetworks ("experts"), with a learned gating/routing function
that selects which experts to activate per input token. Modern examples:

- **Mixtral 8×7B / 8×22B** (Mistral AI) — 8 experts per layer; top-2 active
  per token; full parameter count ~47B, active count ~13B. Dense performance
  from sparse activation.
- **DeepSeek-V3 / V4** — 256 fine-grained experts per layer, top-8 active;
  adds "shared experts" that always fire alongside the routed ones.
- **GPT-4, Gemini 1.5** — MoE architecture widely reported but not officially
  confirmed by vendors.

Key MoE properties:
- Routing is **automatic and sub-token**: the gating network, not a human or
  IC, decides which expert handles each token.
- Experts are **same-architecture, different-weights**: specialisation emerges
  from training, not from deliberate design.
- Combination is **weighted sum**: expert outputs are blended numerically, not
  synthesised by reasoning.
- Experts run **in parallel within a single forward pass**: no sequential
  rounds, no turn protocol.
- There is no **disagreement signal**: experts do not debate; the gating
  function does not detect or resolve conflicting outputs.

Our collective deliberation protocol differs on every one of these axes.

**Questions for agents:**

**Q17.1 — Where the analogy holds and where it breaks**

Both MoE and our protocol try to get better answers by routing to diverse
specialised perspectives. Where is that analogy tight, and where does it
break down? Specifically:

- MoE routing is learned/automatic; ours is rule-based (round-robin) or
  IC-directed. Which is more appropriate for design deliberation, and why?
- MoE combination is a weighted numerical sum; ours is a structured prose
  synthesis by the IC. What can prose synthesis do that a weighted sum cannot?
  What can a weighted sum do that prose synthesis cannot?
- MoE experts are same-architecture-different-weights. Our agents are
  different-architecture-different-training. Does that difference matter for
  the quality of the combined output?

**Q17.2 — What MoE gets right that we should borrow**

MoE has been studied extensively and deployed at scale. Are there design
insights from MoE research that should inform our protocol?

Consider:
- Load balancing (preventing over-reliance on one expert) — do we have an
  equivalent? Should we?
- "Expert collapse" (experts converging to the same function during training)
  — does the analogous failure mode occur in our protocol, and does the
  rotating skeptic role guard against it?
- "Shared experts" (always-on generalists alongside specialised routers) — is
  the IC playing this role, and is that the right design?
- Token-level vs question-level granularity — MoE routes at the token level;
  we route at the question level. Is there a finer-grained routing strategy
  that would improve our protocol?

**Q17.3 — What our protocol gets right that MoE cannot do**

MoE produces no audit trail, no disagreement signal, and no explicit
satisfaction condition. Our protocol produces all three. Where does the
sequential deliberation model generate value that a parallel weighted-sum
model structurally cannot?

Consider the hallucination correction loop, the citation verification round,
the `[needs more evidence]` signal, and the rotating skeptic role. Are any
of these implementable in a MoE architecture, and if not, why not?

**Q17.4 — Should the orchestrator learn from routing?**

MoE gating networks learn which experts are reliable for which input types.
Should our orchestrator track which agents have historically been most useful
on which question types (architecture, cost, security, API design) and use
that signal to weight turn order, extra rounds, or escalation decisions?

Is a learned routing policy worth the complexity, or does the simplicity of
round-robin + IC close have advantages that outweigh adaptive routing?

---

### Q15 — How does our consensus protocol compare to the YC interview protocol?

**Context:** Y Combinator's partner interviews assess founders using a
structured, time-bounded process: roughly 10 minutes, multiple partners
present, rapid-fire questions that probe conviction, clarity, and resilience
under pressure. After the interview, partners converge on a binary decision
(fund / pass) through discussion. The protocol is adversarial by design —
challenge the founder, see if they hold or fold.

Our satisfaction protocol is structurally different:
- Collaborative rather than adversarial
- Graduated output (`[satisfied]` / `[satisfied-conditional]` / `[needs more
  evidence]`) rather than binary
- Round-bounded rather than time-bounded
- IC synthesises rather than founder defends
- Convergence is explicit (all markers satisfied) rather than implicit
  (partners agree)

**Questions for agents:**

1. What does the YC protocol optimise for that ours does not — and vice versa?
2. Are there elements of the YC adversarial model we should borrow? For
   example: a designated "devil's advocate" agent whose role is to challenge
   rather than build consensus?
3. YC uses a binary outcome because they need a decision. We use graduated
   markers because we need shared understanding. Is there a case where a
   roundtable should produce a binary outcome instead?
4. YC partners share a rubric but apply independent judgment. Our agents share
   the satisfied protocol but also apply it independently. Where does that
   analogy break down?

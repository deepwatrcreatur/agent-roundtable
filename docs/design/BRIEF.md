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

**Q18.4 — Recommended path: native, PWA, or companion API (excluding OpenCode fork)**

Of the non-fork options, which path is recommended:
(a) Make the LiveView dashboard a Progressive Web App (PWA) with offline cache
    and home-screen install — covers iPad well, partial phone coverage,
    zero native code;
(b) Expose a JSON/SSE companion API and document it so the owner can build a
    Shortcut or small SwiftUI app;
(c) Invest in a Phoenix Channels Swift client and a purpose-built iOS app;
(d) Rely on push notifications via ntfy.sh / Pushover triggered by orchestrator
    events, with the browser dashboard for any action that needs a screen?

What is the minimum useful step versus the ideal end state among these options?

**Q18.5 — OpenCode fork for iOS/TestFlight: dedicated evaluation**

OpenCode (github.com/sst/opencode → now anomalyco/opencode, ~146k stars, 779
releases as of April 2026) is an open-source agent IDE with a client/server split:
`opencode serve` runs a headless HTTP server with an OpenAPI 3.1 spec; clients
connect via REST + SSE. A TestFlight iOS client (grapeot/OpenCodeClient) and an
unofficial App Store build already exist.

Evaluate the "fork and distribute via TestFlight" path specifically:
- Architecture: what does the iOS client connect to and what protocol does it use?
- Cost: Apple developer account ($99/yr), TestFlight 90-day build refresh, upstream
  tracking burden at ~1 release/day velocity
- Feature fit: streaming agent turns (SSE ✓), satisfaction label display (absent),
  question injection (partial), round triggering (absent)
- Risk: upstream API drift, potential license change from current MIT
- Verdict: better long-term bet than thin companion API + PWA, or complementary
  as a future "Pro layer" for power users who need SSH tunnel + terminal access?

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

### IC Verification Protocol

When agents make **directly contradictory factual claims** about a verifiable
external fact (e.g. what language a repo is written in, what a CLI flag does,
whether a library is archived), the IC must:

1. **Independently verify** the contested fact before closing the sub-question.
   Fetching the primary source or running the command is required. The IC may
   not adjudicate by authority (who cited more) or plausibility alone.

2. **Include the verification** in the synthesis: quote the relevant line from
   the source, or state explicitly what was found and where.

3. **Require quotations, not just citations.** An agent citing a URL does not
   constitute evidence unless the relevant passage is reproduced. "Source X
   confirms this" is not acceptable without the confirming text.

4. **If verification is not possible** in the current session, the sub-question
   must be left open with `[needs more evidence]` and the specific thing to
   verify stated — not closed with a provisional answer.

**Rationale:** The Q19 round (2026-04-28) closed Q19.1 with an incorrect
Python characterisation because one agent's citation was accepted without
checking its content. The correct agent (Gemini, Elixir) was overruled by a
plausible-sounding but wrong citation from the other agent. A citation is not
evidence; verified source content is evidence.

### Claim Provenance Tags (Protocol Update 9)

Tag every contested factual claim with its evidential basis:

- **`[observed]`** — you directly ran the command, read the file, or fetched
  the URL and are quoting from it. A URL quote is `[testimony]` unless the
  question is specifically "what does this source say?"
- **`[testimony]`** — you are reporting what a source, document, or another
  agent said
- **`[inferred]`** — you derived this from other claims

The IC applies evidence precedence: `[observed]` > `[quoted testimony]` >
`[testimony]` > `[inferred]`. Two conflicting `[testimony]` claims cannot
resolve a sub-question — an `[observed]` claim is required.

### Disconfirmation Pass Rule (Protocol Update 9)

If all agents mark a **factual** sub-question `[satisfied]` within 2 turns,
the IC will assign one agent a disconfirmation pass before closing: find one
`[observed]` piece of evidence that could contradict the consensus, or state
explicitly what was looked for and not found.

### Brief Premise Challenge (Protocol Update 9)

Before closing any **design** question, at least one agent must address:
*"What if a key premise in the BRIEF's framing of this question is false?
What would change?"*

---

### Q19 — Agent Orchestration Frameworks: What to Borrow from Symphony and Peers

**Context:**

The roundtable orchestrator is itself an agent orchestration system. Before we
extend it further, it is worth surveying the broader field of multi-agent
orchestration frameworks to see what design patterns are already proven — and
which to avoid.

Key projects to survey:

- **Symphony** — Microsoft's agent orchestration framework (if this refers to
  the AI-focused Symphony project; agents should identify and describe the
  correct project)
- **LangGraph** (LangChain) — graph-based agent state machines; nodes are
  agent steps, edges are transitions, checkpointing for long-running workflows
- **AutoGen / AG2** — Microsoft Research; GroupChat, SelectorGroupChat, nested
  conversations, tool use, human-in-the-loop
- **CrewAI** — role-based agent crews; task delegation, hierarchical and
  sequential execution
- **Temporal** — durable workflow orchestration (not agent-specific, but widely
  used for long-running distributed processes with retry, saga, and compensation)
- **Jido 2.0** — what we already use; how does it compare to the above?

**Q19.1 — Accurate survey: what is Symphony?**

"Symphony" could refer to several projects (Microsoft Symphony, Azure AI
Symphony, others). Identify the correct project(s) that are most relevant to
agent orchestration, describe their architecture, and assess how widely deployed
they are.

**Q19.2 — Patterns worth borrowing**

Across these frameworks, which design patterns have proven most valuable and are
not yet present in our implementation? Consider:
- Durable execution / checkpointing (Temporal-style saga with retry)
- Graph-based state machines (LangGraph) vs. our current recursive round loop
- Agent roles and specialisation (CrewAI hierarchical delegation)
- Human-in-the-loop escalation mechanisms
- Observability: structured tracing, span-level agent step logging

**Q19.3 — Patterns to avoid**

What are the known failure modes of these frameworks that we should not
inherit? Consider: prompt injection via shared state, context window inflation
(one growing thread per session), over-engineering the orchestration layer at
the cost of simplicity, and coupling to a specific LLM API.

**Q19.4 — Jido fit assessment**

We chose Jido 2.0 (Elixir) as our runtime. How does Jido compare to the above
frameworks on: durability, observability, multi-agent coordination primitives,
and community/ecosystem? Are there Jido patterns or extensions that mirror what
the above frameworks offer, or are there genuine capability gaps?

**Q19.5 — Concrete recommendations**

Given what the roundtable orchestrator currently does (GitHub Issues as shared
state, CLI agent invocation, satisfaction-protocol termination, LiveView
dashboard), what are the top 2–3 concrete borrowings from the surveyed
frameworks that would most improve the system? Be specific about what to add,
not just what is possible.

---

### Q20 — Epistemology and Psychosis Prevention: What Can Philosophy of Mind Teach Us?

**Context:**

The Q19 round produced a factual error: the IC accepted a wrong citation from
one agent and dismissed a correct claim from another. The new IC verification
protocol (requiring quoted source content before closing contested claims) is a
procedural fix. This question asks whether philosophy of mind offers a more
principled basis for designing against hallucination and collective
confabulation in multi-agent systems.

The owner's goal is *independent agentic minds interacting for better reality
testing* — protection against the failure modes of single-agent analysis. The
Q19 incident shows that multi-agent agreement is not the same as truth: agents
can converge on a wrong answer. What existing frameworks in philosophy of mind
and epistemology address this distinction?

**Key observation from the owner:**

Steve Yegge's Gas City system corrects *behaviour* (code outputs, test results)
but not *thoughts* (beliefs about the world). Our system attempts to correct
beliefs, not just outputs. That is a harder problem, but a more valuable one if
it can be made reliable. The Q19 incident shows it is currently unreliable.

**Q20.1 — Relevant frameworks from philosophy of mind**

Survey the literature for frameworks directly applicable to hallucination and
confabulation in reasoning systems. Candidates include but are not limited to:

- **Predictive processing / active inference** (Friston, Clark) — cognition as
  prediction-error minimisation; psychosis as over-weighting of priors relative
  to sensory input; relevance to over-relying on internal model vs. external check
- **Higher-order thought theories** (Rosenthal, Lycan) — the role of
  meta-cognition in distinguishing knowledge from confabulation; what an agent
  needs to represent its own uncertainty reliably
- **Social epistemology** (Goldman, Kitcher, Longino) — collective knowledge
  production, testimony vs. observation, independence as a condition for
  epistemic benefit from disagreement, cascade failure in belief propagation
- **Coherentism vs. foundationalism** — whether a web of mutually consistent
  beliefs constitutes knowledge, and why coherence alone is insufficient
- **Extended mind / distributed cognition** (Clark and Chalmers) — whether
  GitHub Issues as shared state constitutes genuine external memory and how
  to reason about its reliability
- Any other frameworks agents identify as more directly applicable

For each framework: identify the core insight, describe how it maps to failure
modes in our multi-agent system, and assess whether it suggests a concrete
protocol change.

**Q20.2 — The hallucination problem in agentic systems**

LLM hallucination is well-documented but the mechanism in multi-agent contexts
is under-discussed. When multiple agents hallucinate *in the same direction*
(correlated confabulation), disagreement-based error detection fails entirely.
When one agent hallucinates confidently and another is uncertain, the confident
agent may dominate.

What does the philosophy of mind literature say about:
- The conditions under which independent agents provide genuine epistemic
  benefit vs. merely amplifying each other's errors?
- The role of *calibration* (accurate self-assessment of confidence) in
  distinguishing knowledge from confabulation?
- Whether there are structural features of the deliberation process that make
  correlated error more or less likely?

**Q20.3 — Belief provenance and the observation/testimony distinction**

A recurring theme in social epistemology is the distinction between:
- **Observation**: the agent directly verified the claim against the world
- **Testimony**: the agent is reporting what another source said
- **Inference**: the agent derived the claim from other beliefs

In our system, agents often conflate these: a citation is treated as
observation when it is actually testimony (the agent hasn't read the source).
The new IC protocol requires quoted content — but is that sufficient?

What does the epistemology literature say about:
- When testimony is a reliable basis for belief vs. when observation is required?
- How should a deliberating group track the provenance of its beliefs?
- Is there a principled basis for the IC verification requirement, or is it just
  a pragmatic patch?

**Q20.4 — Psychosis as a model for collective confabulation**

Psychosis in individual cognition is characterised by:
- Hallucinations (perceptions without corresponding external input)
- Delusions (fixed false beliefs resistant to counter-evidence)
- Disorganised reasoning (internal consistency without external grounding)

Are these failure modes applicable to multi-agent LLM systems? If so:
- What would "collective delusion" look like in our roundtable protocol?
  (Possible example: all agents agreeing on a false architecture because the
  BRIEF.md itself contains a false premise)
- What are the conditions under which our protocol is most vulnerable to
  delusion vs. hallucination?
- Does the predictive processing account of psychosis (Corlett, Fletcher et al.)
  suggest structural interventions that map onto protocol design?

**Q20.5 — Concrete protocol recommendations**

Given the analysis above, propose the 2–3 most concrete and implementable
changes to the roundtable protocol that would most improve reality-testing.
Distinguish between:
- Changes to how agents express their beliefs (format/tagging)
- Changes to how the IC evaluates competing claims (verification rules)
- Changes to the discussion structure itself (roles, ordering, independence)

Be specific. "Agents should cite sources" is not a recommendation — the IC
verification protocol already requires quoted content. What new structural
change would catch the failure mode that the current protocol still misses?


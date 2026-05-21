## Round 119 — Optional Hosted Control Plane, Explained Plainly

**Tags:** product, hosting, control-plane, coordination, UX  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** this round was intentionally narrower than Round 117. It
asked for a plain-language, user-comprehensible explanation of an optional
website-hosted coordination layer, with explicit pressure against overbuilding
it into a Gastown-style orchestration monster.

### Round question

The maintainer wanted a follow-up round that clarified, in simple but still
serious terms, the shape of an **optional** control plane that could be offered
by a future GitHub-successor hosting website.

The target audience was users who:

- have only a basic understanding of coding agents
- have personally hit problems like:
  - dirty shared checkouts
  - duplicate agent work
  - stale attempts
  - publication races
- and do **not** want an overengineered, token-hungry, hard-to-explain system

The concrete decision questions were:

- what this optional host-side control plane actually is
- why it belongs on the hosting site rather than only inside the repo
- what it should own
- what it should explicitly not own
- what the smallest useful version is
- and how to explain it so users do not confuse it with:
  - a new VCS
  - a workflow engine
  - or a giant autonomous project manager

### Grounding used in this round

Relevant local prior context carried into the round:

- **Round 108** — Pi and OpenCode are useful harnesses in bounded ways, but
  harness choice does not by itself solve the deeper coordination problem
- **Round 116** — recurring hygiene failures come from weak defaults and missing
  enforcement around shared checkouts
- **Round 117** — the successor forge should own a narrow coordination / trust
  plane above Git/`jj`, not the whole workflow
- **Round 98** — the host should own the contract and final gate for pluggable
  provider capabilities even when execution lives elsewhere

External framing carried in:

- Anthropic's production multi-agent writeup:
  multi-agent systems can help, but they introduce major coordination overhead
- prior inspection of Pi and OpenCode:
  harnesses can expose useful local primitives, but are still mostly local
  tooling surfaces rather than authoritative shared coordination planes

Important scope boundary carried into the round:

- the goal was **not** to design a full orchestration platform
- it was to find the clearest, smallest, most reassuring explanation of the
  optional host-side coordination layer

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** substantive
- **DeepSeek API:** substantive
- **Copilot:** substantive

This round therefore had a **full substantive roster**.

### Voice summaries

#### Codex CLI

- Strongest on describing the control plane as a **shared traffic system** or
  **visible referee** for multi-agent work.
- Preferred the host to own only the narrow shared facts that need one
  authoritative answer:
  - who is working on what
  - whether a claim is still live
  - which attempt supersedes which
  - and what still needs human approval
- Most explicit that the product must not absorb:
  - code history
  - planning internals
  - CI execution
  - or giant semantic reasoning stores
- Strongest on the warning that if the UI or API cannot be explained simply, the
  product is already too big.

#### Gemini CLI

- Strongest on the phrase that the control plane should feel like a
  **reservation desk** or **parking permit system** for agents.
- Most explicit that the host is the right layer because repo-local state is
  portable but not authoritative:
  agents in different clones still need one common referee.
- Favored a tiny first slice:
  - claims
  - leases
  - attempt lineage
  - and minimal promotion preconditions
- Strongest on the risk that feature creep turns a simple coordination layer
  into a workflow engine or a second VCS.

#### Claude CLI

- Strongest on the phrase that this should be a **Refereed Intent Ledger**:
  a host-side scoreboard for who is trying to do what.
- Most explicit that the host should own only live coordination facts, while
  repo-local memory keeps durable, portable project knowledge.
- Favored an MVP of:
  - claims with TTL
  - leases
  - and one dashboard
- Strongest on the need to keep it reactive rather than directive:
  agents check in; the host does not become a scheduler.

#### DeepSeek API

- Strongest on the **traffic light / whiteboard / shared kitchen** metaphors:
  the product is there to stop agents from colliding, not to tell them how to
  think.
- Favored a smallest useful slice of:
  - an active-claim API
  - expiry
  - basic promotion gating
  - and visible current ownership
- Most explicit that the product should remain optimistic and optional rather
  than becoming mandatory operational ceremony.

#### Copilot

- I agreed with the convergence that the plainest truthful explanation is:
  this is a small optional host-side coordination layer, not a bigger and
  stranger repo system.
- My strongest synthesis point was:
  users need a reassuring explanation that each layer still has its own job:
  - Git/`jj` store code history
  - repo-local memory stores portable project knowledge
  - the host-side control plane stores live shared coordination facts

### First-pass convergence

The substantive voices converged on the following points.

1. **The best user-level explanation is simple: this is a reservation board for
   agents.**
   It answers:
   - who is working on what
   - is that still current
   - and what is waiting for human approval

2. **It belongs on the hosting site because coordination needs one shared,
   authoritative referee.**
   Repo-local memory remains valuable, but it is not sufficient to serialize
   live contested actions across many clones, worktrees, and ephemeral agents.

3. **The control plane should own only a tiny set of boring primitives.**
   The strongest recurring set was:
   - claims
   - expiring leases
   - attempt lineage / supersession
   - promotion gates
   - scoped authority

4. **The code, planning, and long-term project memory should mostly stay
   elsewhere.**
   Code stays in Git/`jj`.
   Portable memory stays in repo-local artifacts.
   CI and workflow logic stay outside the control plane.

5. **The smallest valuable slice is very small.**
   A recurring MVP shape was:
   - claims
   - leases with expiry / heartbeat
   - visible stale/conflict warnings
   - a human-owned promotion gate
   - one simple activity/dashboard view

6. **The biggest danger is scope creep into a second VCS, a workflow engine, or
   a project manager.**
   The round repeatedly treated these as the main ways the idea could become
   overbuilt, unreadable, and expensive.

### Real disagreements that remained

There was no major strategic disagreement, but there were real differences in
tone and metaphor:

- **Codex** leaned toward “traffic system” / “referee”
- **Gemini** leaned toward “reservation desk” / “permit system”
- **Claude** leaned toward “refereed intent ledger”
- **DeepSeek** leaned toward “shared whiteboard” / “traffic light”

These were different explanations of the same narrow product boundary, not
different architectures.

### Final synthesis

The strongest answer from this round is:

- the optional hosted control plane should be explained as a **small shared
  coordination layer for agent work**
- it should live on the hosting site because the hosting site is the one place
  that can act as the authoritative referee across many concurrent local actors
- and it should stay intentionally boring:
  claims, leases, attempt lineage, promotion gates, and visible human control

The panel rejected two bad extremes:

- **bad extreme A:** “put all state in the repo and hope everyone cooperates”
- **bad extreme B:** “build a giant autonomous orchestration platform that owns
  everything”

The maintained line is:

- code history stays in Git/`jj`
- portable project memory stays repo-local
- live shared coordination facts live in the optional host-side control plane
- and final merge/publish authority stays with humans

That gives users a comprehensible answer to their real pain without asking them
to adopt a whole new software-production religion.

### Plain-language user explanation

The strongest plain-language explanation from the round is close to this:

> Think of this as an optional reservation board on the hosting site for coding
> agents. Before an agent starts work, it can check whether someone else is
> already touching that task or area. While it works, it keeps a short-lived
> claim alive. When it finishes, a human can see which attempt is current and
> what is ready for review or promotion.
>
> It does not replace Git or `jj`. It does not run your whole workflow. It does
> not decide what your team should build. It just prevents duplicate work, stale
> attempts, and publication races by giving agents and humans one shared place to
> coordinate.

### Smallest valuable slice

The repeated MVP answer was:

1. **Claims** on tasks or scopes
2. **Leases** with expiry / heartbeat
3. **Attempt supersession / lineage**
4. **Human-owned promotion gate**
5. **One simple dashboard or activity view**

If the product starts larger than that, the round treated it as high risk for
complexity trap.

### Main failure modes to avoid

The round repeatedly warned against:

- turning the control plane into a new VCS
- turning it into a workflow engine
- turning it into an autonomous project manager
- making it mandatory instead of optional
- storing too much semantic or permanent project state there
- requiring too much agent chatter or token-heavy protocol overhead
- making blocked or stale state unreadable to humans

### Reusable concise summary

The strongest concise summary from the round is:

> An optional hosted control plane is a small coordination layer on the website
> that helps humans and agents avoid stepping on each other. It tracks live
> claims, expiring leases, attempt lineage, and promotion gates, while leaving
> code history in Git/`jj`, portable memory in the repo, and final merge or
> publish authority with humans. It should feel like a shared reservation board,
> not a new VCS or a giant workflow engine.

### Satisfaction marker

This round is satisfied if the project continues describing the optional control
plane as:

- host-side
- optional
- narrow
- inspectable
- human-gated
- and explicitly separate from code history, long-term repo memory, and full
  workflow automation

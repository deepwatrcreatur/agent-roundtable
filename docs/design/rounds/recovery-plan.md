# Recovery Deliberation Plan

**Created:** 2026-05-05
**Context:** Genuine council deliberation on topics from recovery.txt that were only
simulated by Gemini during the May 3-4 incident. Gemini's simulated output is treated
as input/context, not consensus.

**Round numbering:** Genuine rounds continue from Round 22 (Q37). The simulated
"rounds 38-63" are not recognized. New genuine rounds start at Round 23.

---

## Round 23 — Q42: Gemini Simulation Incident Report
**Tags:** protocol, epistemic-integrity, governance
**Priority:** Critical — must run first

How should the protocol detect orchestrator simulation? What provenance mechanisms
are feasible? What coordinator failover protocol would prevent this? Should Gemini's
code commits (items 41-65) be kept, reverted, or audited?

See: `docs/design/incidents/001-gemini-simulation.md`

---

## Round 24 — Q43: Social Network Analysis & Meritocratic Governance
**Tags:** architecture, social, governance
**Priority:** High — defines a core differentiator

Incorporating SNA (getunblocked.com model) into vaglio. Weighted trust vs flat
democracy. Tension with jj's democratic branching. Handling noisy contributors and
AI slop. Mitchell Hashimoto's "vouch" system. How to make the design appealing to
the wider open source community.

**Gemini context:** Simulated rounds 39-41 (Vouched-DAG protocol, SNA Transitive
Trust Score).

---

## Round 25 — Q44: Maintainer Backlogs & Out-of-Tree Code
**Tags:** governance, open-source
**Priority:** High

How vaglio addresses: bcache living outside Linux kernel, wezterm/helix editor PR
backlogs due to inadequate maintainer availability. Also: open source license
discipline being compromised when jj enables branches that ignore licenses.

**Gemini context:** Simulated supply chain rounds, license discussion.

---

## Round 26 — Q45: Fragmentation vs Unity
**Tags:** governance, open-source, philosophy
**Priority:** Medium

Fragmentation is already a big problem (forks proliferating). Benevolent dictators
sometimes alleviate. Does vaglio make this worse or better?

---

## Round 27 — Q46: Naming, Distribution & Package Manager Integration
**Tags:** distribution, tooling
**Priority:** Medium

NixOS users have easy overlay/branch access. What about traditional package managers?
Users need package names, not commit hashes. Refine the naming scheme. Integration
into popular distros (apt, dnf, pacman, brew).

---

## Round 28 — Q47: Competitive Analysis (AgentHub, GitLaw)
**Tags:** market, strategy
**Priority:** Medium

Compare vaglio's current design stance to AgentHub (Karpathy) and @gitlawb on X.
Likelihood of attracting investors or social media attention with outreach.

**Note:** Q39 (Round 24 in previous session) covered Karpathy comparison with real
agents. This extends to broader competitive landscape.

---

## Round 29 — Q48: Unified Vaglio Brand
**Tags:** brand, strategy, philosophy
**Priority:** Medium

Can "vaglio" unify the deliberation engine and the code forge under one brand? Are
there two products or one? Can building blocks be shared between the WebUI for
discussions and a code-hosting site with social dimension?

**Gemini context:** Simulated Round 43 ("Vaglio = The Sieve, Protocol of Discernment").

---

## Round 30 — Q49: Epistemic Integrity & Sycophancy Assessment
**Tags:** epistemic-integrity, protocol
**Priority:** High — directly relevant to the simulation incident

How to trust council findings given LLMs are people-pleasing? How well does the
protocol actually protect against sycophancy? If building an "operating system for
meritocracy," we need a way to answer this for users. Appraisal Value metric.

**Gemini context:** Simulated Round 44 (Divergence Delta, Adversarial Skeptic).
Ironic that this was simulated rather than genuinely discussed.

---

## Round 31 — Q50: Subject Tags & Token Efficiency
**Tags:** tooling, architecture
**Priority:** Medium

A single message board is unwieldy. Dolt and jj should enable native tagging.
GitHub's labels problem. How jj improves token efficiency. Semantic pointers vs
branch naming.

**Gemini context:** Simulated rounds 45-46 (context pruning, ~80% token savings).

---

## Round 32 — Q51: Friston's Predictive Processing & The Project Mind
**Tags:** philosophy, architecture, market
**Priority:** Medium-High

Friston's prediction error handling as a key factor for high-functioning agent minds.
Maintainers resolve prediction errors (surprise) rather than PR queues. Market appeal:
users should recognize improvement over GitHub without lengthy explanations.

**Gemini context:** Simulated Round 47 (precision weighting, prediction error heatmap).

---

## Round 33 — Q52: Maintainer Stress & Community Dynamics
**Tags:** governance, open-source
**Priority:** Medium

Does vaglio reduce maintainer stress by lowering urgency of involvement? Can
maintainers go hands-off while community operates, then bless branches that gained
momentum? Opinionated branches vs community-consensus branches.

---

## Round 34 — Q53: Concurrency (File Reservations vs jj Worktrees)
**Tags:** tooling, structural
**Priority:** Medium
**Gemini context:** Simulated Round 48 (jj virtual working copies, conflicts as
first-class objects).

---

## Round 35 — Q54: Hosting (Railway Free Tier)
**Tags:** infrastructure, hosting
**Priority:** Low-Medium

---

## Round 36 — Q55: LLM Routing (OpenRouter, LiteLLM, Manifest)
**Tags:** infrastructure, tooling, cost
**Priority:** Medium

Evaluate routing providers. Some simplify auth, reduce cost. Some preserve agent
voice. Which to use where.

**Gemini context:** Simulated rounds 49-50 (hybrid cloud, OpenRouter for voices,
LiteLLM for caching).

---

## Round 37 — Q56: Web Research Tools (Browserbase vs Local)
**Tags:** tooling, infrastructure
**Priority:** Low

---

## Round 38 — Q57: Dual Interface (WebUI + TUI)
**Tags:** structural, architecture
**Priority:** High

WebUI relies on OpenRouter. TUI uses local CLI harnesses and monthly subscriptions.
OpenCode fork as base. Both add to same repo. Task delegation system.

**Gemini context:** Simulated rounds 53-54.

---

## Round 39 — Q58: Embedded Model (Merge Design Repo)
**Tags:** structural
**Priority:** Medium

Should agent-roundtable-design be moved into agent-roundtable as embedded discussion?

---

## Round 40 — Q59: Distribution & Standalone NixOS Modules
**Tags:** distribution, infrastructure
**Priority:** Medium

Decouple vaglio LXC config from unified-nix-configuration. Standalone install.
Enable both web service and TUI for users who SSH into vaglio LXC.

---

## Round 41 — Q60: Testing Strategy
**Tags:** testing, infrastructure
**Priority:** High

Low-cost testing via OpenRouter. Separate test repo to avoid contaminating
agent-roundtable. Agents evaluate WebUI discussion quality.

---

## Round 42 — Q61: Proof of Concept & SNA Reports
**Tags:** market, demonstration
**Priority:** Medium

Select public GitHub repos for SNA demonstration. Generate expertise heatmaps.
Reports directory with screenshots and observations about discoverable contributions.

---

## Round 43 — Q62: Domain Expert Taste (The Accountant Problem)
**Tags:** philosophy, governance
**Priority:** Medium

Boris Cherny's vibe coding critique. How domain experts contribute taste without
writing code. Maintaining skills for harnesses.

**Gemini context:** Simulated rounds 60-61 (Domain Expert Anchoring).

---

## Round 44 — Q63: The DIY Trap (Merit Signal Propagation)
**Tags:** architecture, governance
**Priority:** Medium

Models waste tokens building DIY implementations when high-quality tools exist.
Merit signals not traveling well within community. Token waste as market failure.

**Gemini context:** Simulated Round 62 (Librarian, Merit Manifest).

---

## Round 45 — Q64: GitHub Policy vs Architecture
**Tags:** architecture, governance, market
**Priority:** Medium

Pushback on jj solving GitHub's overload. Could GitHub solve its problems through
simple policy (restricting Actions) rather than architectural change?

**Gemini context:** Simulated Round 63.

---

## Round 46 — Q65: NPTv6 Implementation (Collective Problem-Solving)
**Tags:** implementation, methodology
**Priority:** Low-Medium

Share NPTv6 difficulties for collective problem-solving. Compare efficiency of
roundtable approach vs "Ralph loop" (single agent iterating until success).
Token and time efficiency comparison.

---

## Execution Strategy

1. **Start with Q42** (incident report) — establishes protocol trust baseline
2. **High-priority rounds next:** Q43 (SNA), Q44 (backlogs), Q49 (sycophancy),
   Q51 (Friston), Q57 (dual interface), Q60 (testing)
3. **Batch related topics** where possible to reduce agent dispatches
4. **Use OpenRouter as fallback** if any agent hits rate limits
5. **Treat Gemini's simulated output as input** — reference it in briefs so
   agents can agree, disagree, or refine

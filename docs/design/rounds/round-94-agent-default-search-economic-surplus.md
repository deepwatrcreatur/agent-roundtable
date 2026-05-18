# Round 94 — Should Agents Default to Sourcegraph Semantic Search on GitHub?

**Status:** Closed  
**Tags:** market, strategy, product, tooling  
**Voices used:** Copilot synthesis, GitHub code-search grounding, Sourcegraph MCP/Deep Search grounding  
**Additional note:** this round is about the default search backend for agents
searching GitHub-hosted code, judged by economic surplus rather than by the UX
of a human search box

### Round question

The maintainer wanted a follow-up round on a narrower and more economic framing:

- if agents are using GitHub to find useful code, should their default search
  backend be Sourcegraph semantic search
- or is GitHub search already good enough for agents
- if Sourcegraph creates enough efficiency gain, should model providers be
  willing to pay for it as the default search API
- because agents reason semantically, should we expect their retrieval needs to
  differ from the needs of human users typing into a website search box

### External grounding used

GitHub's public search grounding used here:

- GitHub built Blackbird specifically for code search
- GitHub emphasizes speed, relevance, regex, symbol search, and tight
  integration with code view and navigation
- GitHub's stated design center is a strong default product experience on
  GitHub-hosted code at very large scale

Sourcegraph's public grounding used here:

- Sourcegraph MCP exposes programmatic search, file, navigation, and history
  operations for agentic systems
- Deep Search is explicitly an agentic loop over code search and code navigation
- Sourcegraph emphasizes natural-language questions, multi-step exploration, and
  inspectable source lists

### Relevant prior context

This round builds directly on:

- **Round 90** — Sourcegraph is stronger at broad semantic discovery, but the
  local system should differentiate above search
- **Round 91** — in a Bun-style migration audit, Sourcegraph wins the "find risky
  code" problem while local value begins after discovery
- **Round 93** — the successor forge should own native baseline search rather
  than fully outsourcing it

### First-pass convergence

The round converged on the following points.

1. **The right question for agents is not the same as the right question for
   humans.**
   Human search UX is about:
   - comfort
   - keyboard flow
   - visual scan quality
   - perceived relevance in a browser

   Agent search UX is more like:
   - probability of retrieving the right code with fewer tool calls
   - token cost saved downstream
   - latency across the whole task, not just the first query
   - reduction in failed plans or wrong-file edits

2. **That means Sourcegraph can be more valuable to agents than to humans even if
   humans are reasonably well served by GitHub search.**
   An agent may benefit disproportionately from:
   - better semantic recall on fuzzy queries
   - revision/history-aware retrieval
   - multi-step exploration with source tracking
   - cross-repo traversal from one question

3. **But "better for some hard queries" is not enough to justify universal
   default status.**
   For Sourcegraph to become the default search API for model providers, the net
   economic surplus would have to be convincingly positive after accounting for:
   - query cost
   - extra integration complexity
   - latency
   - provider dependency risk
   - the fact that many GitHub-native searches are already solved adequately by
     GitHub's own system

4. **So the likely answer is not universal default, but selective escalation.**
   A strong default strategy would be:
   - use GitHub-native search for cheap, fast, straightforward retrieval on
     GitHub-hosted code
   - escalate to Sourcegraph semantic/agentic retrieval when the query is broad,
     semantic, history-heavy, cross-repo, or repeatedly failing

### Economic-surplus framing

The round treated economic surplus as:

```text
value created by better retrieval
- direct search cost
- latency cost
- integration/operational cost
- dependency/lock-in cost
```

The value side includes:

- fewer wrong turns
- fewer wasted model tokens reading irrelevant files
- fewer retries and reformulations
- faster task completion
- fewer bad edits from misunderstanding code structure
- better performance on high-value tasks like migrations, audits, and unfamiliar
  codebase work

The cost side includes:

- per-query or subscription cost for Sourcegraph
- operational overhead
- more moving parts in agent runtime
- another vendor in the critical path
- possible duplication with GitHub-native retrieval that is already "good enough"

### When Sourcegraph likely creates enough surplus

The round treated Sourcegraph as more likely to justify paid default or frequent
use when:

1. **Tasks are high value and failure is expensive**
   Examples:
   - security investigation
   - large refactor
   - unfamiliar monorepo work
   - migration tracing
   - organization-wide API usage audits

2. **Queries are semantically fuzzy**
   Examples:
   - "where do we enforce this invariant"
   - "show similar ownership patterns"
   - "find the part that probably handles X"

3. **Cross-repo or history-aware reasoning matters**
   If the agent needs:
   - related code patterns
   - nearby diffs
   - commit history context
   - deeper code navigation
   Sourcegraph's agentic retrieval looks more valuable.

4. **The model provider or customer already has large enterprise economics**
   In those environments, a modest per-query premium can still be justified if
   it materially improves task success rate or reduces expensive human review.

### When GitHub search is probably already good enough

The round treated GitHub search as likely sufficient when:

1. **The code is fully on GitHub and scope is narrow**
   Example:
   - find a symbol
   - locate a known string
   - inspect a nearby file
   - search a small or medium repo

2. **The agent already has strong local context**
   If the agent knows the repository, path, subsystem, or symbol family, the
   marginal gain from a more semantic backend may be small.

3. **Latency and cost sensitivity dominate**
   For cheap, frequent, low-stakes lookups, GitHub-native search may produce
   better net surplus even if Sourcegraph is somewhat better on recall.

4. **The retrieval problem is not actually the bottleneck**
   If the real failure mode is poor planning, weak validation, or missing local
   decision memory, paying for better search alone may not help much.

### Why model providers would pay — and why they might not

The round's answer was:

- **yes, they would pay if the uplift is large and measurable**
- **no, they should not pay by default without evidence of that uplift**

The strongest reasons to pay are:

- better benchmarked task completion on code tasks
- lower token burn from fewer irrelevant file reads
- higher success on hard enterprise tasks
- better agent reputation with customers on unfamiliar codebases

The strongest reasons not to pay universally are:

- many easy searches are already handled well by GitHub
- model providers want to keep core tool chains cheap
- retrieval vendors in the default path create dependency risk
- gains may concentrate in the hardest 10-20% of searches rather than the median

### What agent-specific UX changes about the answer

The round strongly agreed that agent UX is not the same as human UX.

For agents, the important things are:

- APIs, not browser ergonomics
- source inspectability
- structured tool outputs
- scoped retrieval
- good behavior under follow-up and iterative refinement

This helps Sourcegraph because Deep Search and MCP are explicitly designed for
agentic use.

But it also helps GitHub more than one might first assume, because GitHub's
native search is already:

- fast
- code-aware
- symbol-capable
- integrated with code navigation on the host where the code lives

So the round rejected a simplistic inference:

- "agents think semantically"
- therefore
- "Sourcegraph must be the default"

That jump was treated as too quick.

### Recommended product stance

The round endorsed an adaptive policy rather than a single universal default.

#### Best default for most agent systems

- start with cheap/native retrieval on GitHub-hosted code
- escalate to Sourcegraph when:
  - retrieval confidence is low
  - the question is semantic/fuzzy
  - cross-repo reasoning is needed
  - history/diff context is central
  - the task is valuable enough that better retrieval likely pays for itself

#### Best default for premium enterprise agents

In premium enterprise settings, it may be rational to:

- provision Sourcegraph-backed retrieval by default for certain task classes
- keep GitHub-native retrieval as fallback or fast path
- optimize routing by measured task success, not ideology

### What not to claim

The round was especially firm that the project should **not** say:

- "agents should always default to Sourcegraph"
- "GitHub search is only for humans"
- "semantic search automatically creates enough surplus to justify paid default"
- "model providers will obviously pay if search feels smarter"

These claims were treated as insufficiently economic.

### What to say instead

The stronger language is:

- "For agents, the right metric is end-to-end task surplus, not search-box UX."
- "Sourcegraph may be worth paying for when it materially reduces retries,
  token burn, and failure on hard retrieval problems."
- "GitHub search is likely already good enough for many cheap, narrow, and
  GitHub-local lookups."
- "The best default is probably adaptive routing, not a single ideology-driven
  backend choice."

### One-sentence verdict

For agents searching GitHub-hosted code, Sourcegraph semantic search may produce
enough surplus to justify paid default use on hard, fuzzy, or high-value tasks,
but GitHub search is likely already good enough for many cheap and narrow
lookups, so the strongest strategy is adaptive escalation rather than making
Sourcegraph the universal default search API.

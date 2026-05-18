# Round 95 — Should the Code Host Help Drive Adaptive Escalation for Agent Search?

**Status:** Closed  
**Tags:** strategy, product, tooling, structural  
**Voices used:** Copilot synthesis, GitHub code-search grounding, Sourcegraph MCP grounding  
**Additional note:** this round is about whether the host itself should
participate in adaptive escalation for agent retrieval, not whether it should
fully own or hide that policy

### Round question

The maintainer wanted a follow-up to Round 94:

- does it make sense for the code host to integrate some part of the adaptive
  escalation algorithm
- can the host offer feedback or metrics based on its own knowledge of hosted
  code or query-processing behavior
- should those host-side signals influence whether an agent stays on native
  retrieval or escalates to a more expensive semantic/discovery layer

### External grounding used

GitHub's public search grounding used here:

- GitHub built Blackbird as a code-specific first-party engine
- GitHub's design center is tightly integrated, fast, large-scale search and
  navigation on hosted code
- GitHub's own rationale emphasizes that search and navigation are product-core,
  not incidental plumbing

Sourcegraph's public grounding used here:

- Sourcegraph MCP exposes code-search, file, navigation, and history tools to
  agentic systems
- Deep Search is explicitly an agentic, iterative retrieval loop rather than a
  single query box

### Relevant prior context

This round builds directly on:

- **Round 93** — the successor forge should own native baseline search rather
  than fully outsourcing the core substrate
- **Round 94** — adaptive escalation is stronger than a universal Sourcegraph
  default for agents on GitHub-hosted code

### First-pass convergence

The round converged on the following points.

1. **Yes, it does make sense for the host to participate in adaptive
   escalation — but mainly as a signal provider and local policy participant,
   not as an opaque supreme router.**

2. **The host often has information that outside retrieval layers do not have as
   cheaply.**
   Examples:
   - repository size and topology
   - branch/default-branch status
   - symbol index coverage
   - query result count and dispersion
   - whether results cluster tightly in one subtree or scatter broadly
   - whether query terms match symbols, paths, commits, or only text fragments
   - whether prior follow-up queries on the same task are converging or flailing

3. **Those signals are genuinely useful for deciding whether escalation is worth
   paying for.**
   If the host can already tell that:
   - the query matched a symbol exactly
   - results are tightly scoped
   - navigation confidence is high
   then escalation is probably unnecessary.

   If the host instead sees:
   - poor result concentration
   - repeated reformulation
   - broad cross-repo scatter
   - no strong symbol/path anchors
   then semantic or agentic escalation becomes more plausible.

4. **But the host should not hide the policy logic entirely.**
   Adaptive escalation should remain inspectable. Otherwise the system risks:
   - covert cost inflation
   - hard-to-debug routing behavior
   - hidden favoritism toward or against certain providers
   - loss of operator trust

### Why host assistance makes sense

The round treated host assistance as sensible for three reasons.

#### 1. The host already observes cheap, local retrieval signals

Before any expensive escalation, the host can often compute:

- exact symbol hit vs weak text hit
- result count
- result entropy / concentration
- subtree locality
- repository count touched
- branch/index coverage
- whether code navigation is available for the hit set

These are natural inputs to an escalation decision.

#### 2. The host can help preserve economic surplus

Round 94 argued that the right metric is end-to-end surplus. Host-side metrics
can help protect that surplus by avoiding unnecessary paid escalation.

The host can say, in effect:

- "native search confidence is high; stay local"
- "native search is noisy and broad; escalation is likely worth it"

That is economically useful if it reduces both:

- wasted premium retrieval calls
- wasted downstream model tokens on poor native results

#### 3. The host has code-topology context

A forge or code host understands hosted structure such as:

- repositories
- ownership boundaries
- branch defaults
- symbol indices
- code navigation coverage
- recent change surfaces

That means it can often provide a better first-pass routing hint than a generic
agent runtime acting blind.

### What role the host should play

The round recommended a bounded role.

#### The host should do

- expose retrieval-quality hints
- expose scoped confidence metrics
- expose whether a query is likely symbol/path/local or semantic/broad
- expose whether native navigation already covers the likely answer surface
- expose whether the query has already failed or broadened repeatedly in the
  current session

#### The host should not do by default

- secretly route every hard query to a paid third party
- make provider choice impossible to inspect
- collapse all escalation policy into private host heuristics
- force customers to use one premium retrieval vendor

### Suggested host-side signals

The round would endorse host-visible metrics such as:

1. **Result concentration**
   - do results cluster in one repo/path or scatter across many

2. **Symbol/path confidence**
   - exact symbol or path match vs weak textual match

3. **Query reformulation pressure**
   - repeated query edits or failed follow-ups in the same task/session

4. **Coverage confidence**
   - does the host have code navigation / symbol information for the candidate
     results

5. **Cross-repo breadth**
   - is the likely answer contained locally or spread broadly across the estate

6. **History relevance**
   - is the question likely to require commit/diff exploration rather than just
     present-state file search

7. **Task-value hints**
   - optional task metadata from the caller such as:
     - low-stakes lookup
     - refactor planning
     - audit
     - migration
     - security investigation

### Recommended interface shape

The round preferred an explicit host-assisted interface over hidden behavior.

Example conceptual contract:

```json
{
  "native_confidence": 0.81,
  "result_concentration": "high",
  "cross_repo_breadth": "low",
  "symbol_match": true,
  "history_relevance": "low",
  "escalation_hint": "stay_native"
}
```

Or:

```json
{
  "native_confidence": 0.24,
  "result_concentration": "low",
  "cross_repo_breadth": "high",
  "symbol_match": false,
  "history_relevance": "high",
  "query_reformulations": 3,
  "escalation_hint": "semantic_escalation_likely_worth_it"
}
```

The important point is that the host emits guidance, not a secret decree.

### Product implications

The round saw three product options.

#### Option A — Host-only routing

The host makes escalation decisions internally.

The round viewed this as too opaque unless very carefully surfaced.

#### Option B — Agent-only routing

The host returns only raw search results; the agent decides everything.

The round viewed this as too blind and wasteful because it ignores cheap
host-side signals.

#### Option C — Host-assisted adaptive routing

The host returns:

- native results
- quality/confidence hints
- suggested escalation class

Then the agent/runtime/operator chooses whether to escalate.

This was the preferred answer.

### Where this helps most

The round treated host-assisted escalation as especially useful when:

- the code host already has strong native indexing and navigation
- premium retrieval is meaningfully more expensive
- many queries are easy and should stay local
- some queries are expensive failures unless escalated
- operators want measurable routing logic rather than faith-based defaults

### Risks and cautions

The round emphasized several risks.

1. **Metric gaming**
   If escalation policy is tied to vendor economics, providers may be tempted to
   shape metrics in self-serving ways.

2. **Opacity**
   If agents cannot inspect why escalation happened, debugging and trust suffer.

3. **Lock-in**
   If the host exposes hints only for one premium retrieval path, the ecosystem
   becomes less open.

4. **False precision**
   Confidence metrics can be useful without being magical. The system should
   avoid pretending they are perfect.

### What not to claim

The round was especially firm that the project should **not** say:

- "the host should secretly decide all escalation"
- "agent runtimes do not need visibility into routing"
- "host-side metrics are enough to replace benchmarking"
- "adaptive escalation should be vendor-specific from the start"

### What to say instead

The stronger language is:

- "The host should contribute cheap local signals to escalation."
- "Adaptive routing is strongest when host hints remain inspectable and
  overridable."
- "Native search, host-assisted confidence, and premium semantic escalation
  should compose rather than collapse into one opaque tier."

### One-sentence verdict

Yes — it makes sense for the code host to integrate part of adaptive escalation,
but mainly by exposing inspectable retrieval-quality signals and escalation
hints; the best design is host-assisted routing with visible policy and agent or
operator override, not a hidden host-side decision monopoly.

# Round 90 — Sourcegraph Deep Search, Semantic Code Understanding, and `jj` Lineage as Differentiation

**Status:** Closed  
**Tags:** market, strategy, tooling, structural  
**Voices used:** Copilot synthesis, Sourcegraph product/docs grounding, local repo grounding  
**Additional note:** this round was framed as a competitive-analysis exercise, not
as a claim that the local system already has a shipped moat or a superior search
product

### Round question

The maintainer wanted a round on whether Sourcegraph's Deep Search / semantic
code-understanding product leaves room for a differentiated offer based on local
ideas about `jj` lineage, supersession, decision memory, and outcome-linked
agent work.

The narrower questions were:

- what exactly Sourcegraph is selling to enterprise users
- where that product is already strong
- whether `jj`-native lineage has useful commercial application for companies
  whose active codebases are already internally filtered for quality
- how the project could compete by offering meaningful enhancements rather than
  merely adjacent rhetoric

### External grounding used

Sourcegraph currently markets Deep Search as:

- an **agentic AI search tool** for natural-language questions over codebases
- a way to help teams onboard and understand complex, rapidly evolving codebases
- a system that searches across repositories, files, commits, diffs, and code
  navigation surfaces
- a product that shows the searches performed and files read so answers remain
  inspectable
- a semantic search layer that finds code by meaning and developer intent rather
  than exact string overlap

Important official framing used here:

- "never build blind again"
- "comprehensive answers for complex codebases"
- "leverage powerful agentic tools"
- "empower more than just software engineers"

### Relevant prior context

This round built directly on:

- **Round 58** — git continuity at the edge, `jj` truth in the core
- **Round 63** — embedded design memory should be bounded and wired close to code
- **Round 65** — the current `jj` advantage is real but narrow, strongest in
  rewrite-heavy local work and bounded retrieval
- **Round 67** — the only plausible moat is in a decision / correction loop, not
  raw hosting
- **Round 68** — non-exported trust signals matter only if tied to measurable
  operational efficiency
- **Round 74** — the repo-native knowledge base is explicit records plus lineage,
  not inferred graph magic
- **Round 87** — predictions can be assessed against later graph outcomes
- **Round 89** — markdown should stay canonical, while structured derived indices
  and board-side operational state carry machine-readable enforcement/query needs

### First-pass convergence

The round converged on the following points.

1. **Sourcegraph is strong where the local system should not overclaim.**
   Its product is already well pitched for:
   - semantic discovery over unfamiliar code
   - whole-codebase natural-language understanding
   - agentic exploration without requiring project-specific governance metadata
   - quick onboarding and cross-functional code understanding

2. **The local system should not claim to beat Sourcegraph at semantic search.**
   That would be an incredible and currently unsupported claim. The repo's own
   earlier rounds already warned against turning `jj` or lineage ideas into
   ideology or inflated superiority claims.

3. **The useful differentiation is not "find code by meaning" but "recover why
   this code ended up shaped this way."**
   The strongest local value is around:
   - explicit supersession
   - rejected alternatives
   - accepted constraints
   - prediction versus later outcome
   - repair and rejection history
   - organizational memory near the code

4. **This matters most for quality-filtered internal codebases under agentic
   change pressure.**
   If a company already trusts the rough quality of its main codebase, the next
   problem is often not discovery alone but:
   - avoiding repeated mistakes
   - teaching agents local architectural taste
   - preserving institutional reasons for constraints
   - reducing regressions introduced by well-meaning changes

5. **The honest product angle is complementary to Sourcegraph, not symmetrical
   with it.**
   Sourcegraph helps answer:
   - where is the code
   - how does it work
   - where are similar patterns

   A `jj`-lineage-aware system could instead help answer:
   - what replaced this
   - what was rejected and why
   - what constraints are still current here
   - what predictions about this subsystem later proved wrong
   - what should an agent know before proposing a change here

6. **The strongest commercial story is operational, not ideological.**
   The pitch should be:
   - fewer repeated regressions
   - faster repair cycles
   - less time re-explaining local rules
   - better routing of agent work using local precedent
   not:
   - "everyone should adopt `jj`"
   - "graphs beat embeddings"
   - "we have a better code search engine"

### Where Sourcegraph is stronger

The round treated Sourcegraph as stronger on:

- broad semantic discovery over large unfamiliar code estates
- mature natural-language search UX
- low-friction adoption because it works without a richer governance substrate
- enterprise-ready positioning around onboarding and knowledge access

This is exactly why the local system should avoid claiming to replace Sourcegraph
on its home turf.

### Where `jj` lineage can add differentiated value

The strongest differentiated surfaces were:

1. **Lineage as outcome evidence**
   Not just "where is similar code," but:
   - what this replaced
   - which alternatives were rejected
   - which incident or fix record caused the current constraint

2. **Explicit prediction calibration**
   Link:
   - prediction
   - proposed change
   - merge / supersession / revert / maintenance burden
   so a system learns which local judgments held up in which subsystems.

3. **Rejection-reason corpus**
   Agents and humans can ask:
   - why were similar proposals rejected here before
   - which architectural rules repeatedly caused rejection
   - what local concern is likely to be triggered again

4. **Institutional memory through turnover**
   The value is not that the code can be searched, but that local rationale stays
   legible after team changes instead of dissolving into Slack, tacit maintainer
   memory, or stale PR comments.

### What not to claim

The round was especially firm that the project should **not** say:

- "`jj` is fundamentally better for code understanding"
- "our graph is superior to embeddings"
- "teams should adopt `jj` to do semantic search properly"
- "we beat Sourcegraph at search"
- "the moat is already here"

These were treated as credibility-destroying claims.

### What to say instead

The stronger commercial language is:

- "We capture decision context that code hosting loses."
- "We help agents respect the constraints your team already discovered."
- "We link proposal history to later outcomes."
- "We preserve organizational memory around why code is shaped the way it is."
- "Semantic search finds the code; lineage-aware memory explains the accepted and
  rejected paths around it."

### Concrete product enhancements the round would endorse

1. **Bounded-subtree constraint query**
   Let an agent ask:
   - what constraints apply to `path/auth`
   - what incidents/fixes are active here
   - what was superseded recently

2. **Current guidance / replacement query**
   - what is the current decision on X
   - what replaced Y and why

3. **Proposal-history retrieval**
   - show similar prior proposals
   - show rejection reasons
   - show related maintainer objections and outcome notes

4. **Prediction-to-outcome calibration**
   Use the Round 87 protocol so subsystem-local judgment can be assessed against
   later outcomes rather than against popularity.

5. **Organization-specific agent routing**
   Not a global reputation system, but a local operational signal:
   which kinds of changes and which reasoning patterns have actually worked in
   this environment before.

### Best-fit customer profile

The round implicitly targeted companies that:

- already have substantial code search/discovery needs handled reasonably well
- rely heavily on agents or expect to
- suffer from repeated agent or newcomer mistakes against local architectural
  constraints
- have enough process maturity to benefit from explicit decision memory and
  rejection records

### One-sentence verdict

The local system should not compete with Sourcegraph on generic semantic code
search; its credible differentiator is lineage-aware decision memory around code
change — supersession, rejection reasons, constraints, and outcome history —
pitched as operational reliability for agent-heavy teams rather than as VCS
ideology or search-engine superiority.

### Addendum — what the sales pitch looks like if the goal is integration

The maintainer asked for the complementary case more directly: if Sourcegraph is
already selling code search and agentic code understanding, what is the pitch to
Sourcegraph itself, and what is the pitch to a company deciding whether to buy
one or both products?

The round's answer is that **direct integration does make sense, but mainly as a
companion layer rather than as a tight product merger**.

Why:

- Sourcegraph now exposes official API and MCP surfaces for search, code
  navigation, history/diff search, file reads, and Deep Search access.
- That means the missing piece is not transport or tool access. The missing piece
  is a different kind of memory: accepted constraints, supersession chains,
  rejection reasons, prediction/outcome records, and "what should an agent know
  before changing this subsystem?"
- Those are adjacent to Sourcegraph's search value, but not identical to it.

So the most credible pitch is:

1. **Pitch to Sourcegraph**
   "Your search and code-intelligence product helps users find and understand the
   code. We add a post-search memory layer that helps agents and engineers avoid
   repeating already-rejected moves, recover active local constraints, and route
   changes with more awareness of prior outcomes."

   The complementarity claim is:
   - Sourcegraph increases retrieval power
   - the lineage-aware layer increases decision quality after retrieval
   - together they reduce time spent rediscovering local architecture and reduce
     repeated bad proposals from agents or newcomers

   In other words, Sourcegraph can stay the exploration substrate while the local
   system becomes a decision-memory and change-governance companion.

2. **Pitch to the subscribing company**
   "If you only need discovery and code understanding, Sourcegraph may already be
   enough. If your real pain is that people or agents keep proposing changes that
   violate local constraints, repeat rejected ideas, or lose the reasoning behind
   accepted architecture, the lineage-aware layer is additive rather than
   duplicative."

   The company-level value of buying both is:
   - Sourcegraph answers: where is the code, how does it work, where are similar
     patterns, what changed
   - the lineage-aware layer answers: what replaced this, what was rejected here,
     which constraint is still active, which prior predictions held up, and what
     local precedent should shape the next change

### Does direct integration actually make product sense?

The round's answer is **yes, but mostly as loose-to-moderate integration rather
than deep in-product fusion**.

The strongest fit is when:

- the customer already runs Sourcegraph or wants its code-search/discovery value
- the customer is becoming more agent-heavy
- the real pain has shifted from "finding code" to "making good changes in the
  presence of local history and constraints"

The weaker fit is a claim that the lineage-aware system should be embedded deep
inside Sourcegraph's core UX or replace Sourcegraph-native search experiences.
That is not necessary for value, and it would create unnecessary go-to-market
dependency.

So the practical recommendation is:

- **yes to integration**
- **no to a story that requires Sourcegraph to stop being a search-first company**
- **yes to a joint workflow where Sourcegraph remains the discovery plane and the
  lineage-aware system becomes the decision-memory plane**

### Concrete integration work the round would sketch

The round would sketch the integration in phases.

1. **Sourcegraph-as-context-provider**
   A local agent or UI asks Sourcegraph MCP / API for:
   - relevant repos/files
   - semantic search results
   - commit/diff history
   - Deep Search answers and conversation URLs

   Then the lineage-aware layer attaches:
   - active subsystem constraints
   - superseded alternatives
   - linked incident/fix records
   - similar rejected proposals
   - prediction/outcome history for that surface

   This is the lowest-risk and most immediate integration shape.

2. **Scoped handoff from search to decision memory**
   Add an action such as:
   - "open with lineage context"
   - "show accepted/rejected history for this path"
   - "prepare agent brief for this file/subtree"

   The output should be a compact brief keyed by repo + path/subtree + revision,
   not a vague cross-repo essay.

3. **Deep Search evidence ingestion**
   When Deep Search produces a useful answer, store a structured pointer to:
   - the conversation URL
   - the Sourcegraph searches used
   - the files read
   - the user question
   - the local work item / decision / prediction it informed

   This matters because otherwise a good search session disappears as transient
   chat instead of becoming durable organizational memory.

4. **Pre-change agent briefing**
   Before an agent edits code, call both systems:
   - Sourcegraph supplies code understanding and nearby change history
   - the lineage-aware layer supplies local warnings, active constraints,
     supersession chains, and "do not repeat this rejected move" context

   This is probably the highest near-term value surface because it addresses the
   real cost center: bad or repetitive proposed changes.

5. **Post-change outcome linking**
   After a change is proposed or merged, write back a local record linking:
   - proposal / work item
   - Sourcegraph search or Deep Search context used
   - the actual code change
   - later outcome signals such as merge, revert, supersession, maintenance cost,
     or incident linkage

   This is where the complement becomes compounding rather than one-off: search
   sessions become part of a learnable decision/outcome corpus.

### Concrete implementation surfaces

If the project wanted to prototype this seriously, the first concrete work could
look like:

- a small adapter that calls Sourcegraph MCP endpoints for:
  - `nls_search`
  - `keyword_search`
  - `read_file`
  - `commit_search`
  - `diff_search`
  - Deep Search endpoint access where available
- a local normalization layer that converts Sourcegraph outputs into canonical
  evidence records with:
  - `repo`
  - `revision`
  - `path_scope`
  - `sourcegraph_query`
  - `sourcegraph_conversation_url`
  - `files_read`
  - `related_work_item`
  - `related_decision`
  - `related_prediction`
- a "subtree brief" generator that joins Sourcegraph discovery with local
  rounds/decisions/incidents/fixes/work-item lineage
- agent-facing prompt/tool surfaces like:
  - `brief_subsystem_for_change`
  - `show_rejected_precedents`
  - `show_current_constraints`
  - `link_search_session_to_outcome`

The round would especially avoid a first version that tries to fully synchronize
all Sourcegraph state into a new shadow index. That is too ambitious and misses
the point. The first useful version is a thin integration layer with explicit
links and durable records.

### Commercial summary of the addendum

The best integration pitch is not:

- "we replace Sourcegraph"
- "search is solved, now buy our graph"
- "Sourcegraph should become a `jj` company"

It is:

- "Sourcegraph gives your agents better code retrieval"
- "the lineage-aware layer gives those agents better judgment about what to do
  next"
- "together they reduce rediscovery, repeated mistakes, and loss of local
  architectural memory"

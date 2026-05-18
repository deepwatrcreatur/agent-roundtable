# Round 96 — Vertical Integration, Build-vs-Buy, and Sourcegraph Hold-Up Risk

**Status:** Closed  
**Tags:** market, strategy, product, acquisition  
**Voices used:** Copilot synthesis, GitHub code-search grounding, Sourcegraph positioning grounding  
**Additional note:** this round focused on whether vertical integration is the
practical answer to Sourcegraph hold-up risk, and whether Sourcegraph itself
would be broadly worth buying for a code-hosting platform

### Round question

The maintainer wanted a follow-up round on the implications of the prior
Sourcegraph discussions:

- does vertical integration largely solve the hold-up risk from depending on
  Sourcegraph
- is semantic search non-proprietary enough that a host can simply build it
  independently
- if not, is buying Sourcegraph a plausible answer
- are Sourcegraph's intellectual property, product, and other assets actually
  broadly useful to a code-hosting site, or mostly aligned to Sourcegraph's
  enterprise code-intelligence market

### External grounding used

GitHub's public grounding used here:

- GitHub explicitly chose to build Blackbird in-house because search was viewed
  as strategic, code-specific, and scale-sensitive
- GitHub's published rationale implies that strong platforms often internalize
  search rather than accept long-run dependency on external search vendors

Sourcegraph's public grounding used here:

- Sourcegraph positions itself as a code-intelligence platform rather than just
  a narrow semantic-search API
- its strongest fit is large, complex, multi-code-host, enterprise-style code
  estates
- its surface includes universal code search, code navigation, Deep Search, and
  enterprise integrations beyond a single forge's native use case

### Relevant prior context

This round builds directly on:

- **Round 90** — Sourcegraph is stronger at semantic discovery, but local
  differentiation lives above search
- **Round 93** — the successor forge should own native baseline search and avoid
  making Sourcegraph the canonical substrate
- **Round 94** — paid Sourcegraph use may be justified selectively by
  economic-surplus gains, not as a universal default
- **Round 95** — host-assisted adaptive escalation is preferable to opaque
  routing or universal dependence

### First-pass convergence

The round converged on the following points.

1. **Yes, vertical integration is the long-run structural answer to hold-up risk
   if search is truly core.**
   If a code-hosting platform depends on an external retrieval vendor for a
   critical product surface, it inherits:
   - pricing risk
   - roadmap risk
   - licensing risk
   - dependency risk in a user-facing core loop

   Owning a native search capability is the cleanest long-run answer.

2. **Semantic search is not especially proprietary as a concept.**
   The round rejected any implication that "semantic code search" is such a
   singular invention that a capable platform cannot reproduce it over time.
   The concept is broader than any one vendor.

3. **But "can be built" is not the same as "is cheap to build well."**
   Even if the idea is not uniquely proprietary, execution still matters:
   - indexing quality
   - code-navigation quality
   - query latency
   - repository-scale operations
   - permissions handling
   - product integration

   So the round rejected two extremes:
   - "Sourcegraph has a permanent unassailable moat"
   - "semantic search is commodity and therefore trivial"

4. **Buying Sourcegraph is not obviously the best answer just because hold-up is
   annoying.**
   Acquisition only makes sense if the buyer wants a large fraction of
   Sourcegraph's broader enterprise code-intelligence assets, go-to-market, and
   customer relationships — not just a generic semantic-search capability.

### Is vertical integration the solution?

The round's answer was **mostly yes in the long run, but not necessarily on day
one**.

If the code host expects search to be:

- core to its user loop
- core to agent workflows
- core to platform learning
- core to permissions/trust boundaries

then vertical integration is the cleanest strategic position.

That does not forbid:

- transitional partnerships
- optional integrations
- premium augmentation layers
- migration bridges while native capability matures

But the long-run strategic logic still points toward owning the baseline.

### Is semantic search too non-proprietary to fear Sourcegraph hold-up?

The round's answer was **yes and no**.

#### Yes

- the concept is not mystical
- the relevant techniques are not unimaginable to other strong teams
- GitHub's own Blackbird story shows a major platform can build search in-house

#### No

- quality still takes time, talent, and iteration
- operational maturity and product integration matter
- enterprise features and cross-host support are real work
- "good enough to demo" is different from "good enough to anchor product"

So the correct conclusion is:

- Sourcegraph's hold-up power is bounded
- but not zero in the short/medium term if a platform has no credible native path

### Would buying Sourcegraph make sense?

The round treated this as **possible but highly conditional**.

Buying Sourcegraph might make sense if the acquirer specifically wants:

- a mature enterprise code-intelligence product
- cross-host and hybrid-environment capability
- an installed enterprise customer base
- search/navigation/intelligence talent and product know-how
- agentic search workflows that go beyond a simple forge-native baseline

Buying Sourcegraph makes less sense if the acquirer mainly wants:

- "semantic search" in the abstract
- a narrow fix for partner hold-up
- a simple feature parity story for GitHub-native hosted code

In that narrower case, building internally may be cleaner than absorbing a large
enterprise-oriented company with broader product assumptions.

### Are Sourcegraph's assets broadly useful to a code host?

The round concluded that they are **partly useful, but not universally so**.

#### Likely useful assets

- search and code-intelligence know-how
- enterprise integrations
- cross-host retrieval architecture
- agentic retrieval/product ideas
- customer relationships in enterprise code-intelligence budgets

#### Potentially awkward assets

- go-to-market tuned for standalone enterprise tooling
- product surfaces optimized for multi-system estates rather than one host's
  deeply integrated UX
- operational assumptions that fit a code-intelligence vendor better than a
  forge-first platform
- org and product complexity beyond what a host may need for its default search
  layer

So the round rejected the simplistic view:

- "if you need semantic search, buy Sourcegraph"

Instead:

- Sourcegraph may be valuable to buy if you want the enterprise code-intelligence
  business and capabilities
- it is less obviously the right purchase if you only want to eliminate a narrow
  dependency in a host-native product

### Strategic options the round considered

#### Option A — Build natively

Pros:

- removes hold-up risk
- aligns search with host UX and permissions
- preserves product learning
- cleaner long-run platform story

Cons:

- slower path
- higher upfront engineering cost
- risk of weaker capability in the interim

#### Option B — Integrate Sourcegraph, then build over time

Pros:

- faster time to value
- can serve hard enterprise use cases early
- preserves optionality

Cons:

- partner dependency remains during the transition
- UX fragmentation risk
- governance around escalation/vendor choice gets more complex

#### Option C — Acquire Sourcegraph

Pros:

- talent, product, and enterprise footprint arrive at once
- can shorten time to mature capability
- potentially converts dependency into ownership

Cons:

- expensive
- integration risk
- acquired assets may be broader than needed
- may pull the host toward enterprise-product complexity it did not actually want

The round treated **Option B with a long-run bias toward A** as the most
plausible generic strategy.

### What not to claim

The round was especially firm that the project should **not** say:

- "Sourcegraph has no real leverage because semantic search is easy"
- "acquiring Sourcegraph is obviously the right answer"
- "a host can safely ignore build-vs-buy because concepts are non-proprietary"
- "Sourcegraph's enterprise assets automatically translate into forge advantage"

### What to say instead

The stronger language is:

- "Vertical integration is the cleanest long-run answer if search is core."
- "Semantic search is reproducible in principle, but difficult enough in practice
  that transition strategy still matters."
- "Buying Sourcegraph only makes sense if the buyer wants enterprise
  code-intelligence capabilities broadly, not just a narrow search feature."
- "Sourcegraph's hold-up power is real in the short term, but bounded by the
  host's ability to build or selectively integrate alternatives."

### One-sentence verdict

Vertical integration is the strongest long-run answer to Sourcegraph hold-up
risk because search is too core to leave permanently external, but semantic
search is not so proprietary that a serious code host must remain dependent
forever; acquiring Sourcegraph only makes sense if the buyer actually wants its
broader enterprise code-intelligence assets, not merely the abstract idea of
semantic search.

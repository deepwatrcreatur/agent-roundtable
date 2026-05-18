# Round 97 — Host-Assisted Routing, Hayek's Knowledge Problem, and Price Signals

**Status:** Closed  
**Tags:** strategy, philosophy, product, economics  
**Voices used:** Copilot synthesis, prior routing-round grounding  
**Additional note:** this round uses Hayek's knowledge-problem framing as an
economic and architectural analogy, not as a claim that all routing choices
should literally be reduced to market pricing

### Round question

The maintainer wanted a follow-up round that draws a parallel between
host-assisted routing and Hayek's knowledge problem:

- some will try to solve routing by making models larger and embedding more
  knowledge about search tiers and escalation policy directly into the model
- this can make the model act like a central planner
- perhaps price-like and local signals are better
- perhaps host-assisted routing achieves better economic results because local
  knowledge stays local and routing responds to signals rather than pretending a
  single giant model can know everything

### Relevant prior context

This round builds directly on:

- **Round 94** — agent search should be judged by end-to-end surplus, not by
  human search-box UX
- **Round 95** — the host should contribute cheap local routing signals, but
  routing must remain inspectable
- **Round 96** — long-run platform strategy favors owning core search rather than
  permanent dependence

### First-pass convergence

The round converged on the following points.

1. **Yes, the Hayek analogy is genuinely useful here.**
   The routing problem contains dispersed, local knowledge:
   - host-side index coverage
   - query result concentration
   - current repository topology
   - current task value/risk
   - current latency/cost of premium retrieval
   - current provider availability
   - current failure/reformulation history

   No single static model snapshot naturally contains all of that in the right
   form at the right time.

2. **Trying to encode too much routing policy inside a giant model risks a
   central-planning mistake.**
   The model may become a pseudo-planner that:
   - guesses hidden costs
   - guesses retrieval quality
   - guesses changing host-side conditions
   - guesses whether premium escalation is worth it

   without actually observing the live local signals that matter most.

3. **Host-assisted routing is closer to a dispersed-knowledge solution.**
   The host, runtime, and provider each know different things:
   - host knows local code/index/query conditions
   - runtime knows task context and failure history
   - retrieval provider knows premium capability and cost
   - operator/customer knows acceptable spend and task value

   A good routing system should combine those signals rather than pretend one
   model should internally approximate them all.

4. **Price-like signals matter because they compress tradeoffs into action-guiding
   information.**
   If premium semantic escalation has real cost, and native retrieval has lower
   cost but sometimes lower value, routing should respond to:
   - marginal retrieval cost
   - expected success uplift
   - task value
   - time/latency sensitivity

   This is closer to Hayek's argument for local signals than to central planning.

### Where the analogy helps

The round found the analogy strongest on four points.

#### 1. Knowledge is dispersed

Hayek's core insight is that economically relevant knowledge is distributed
across many actors and cannot be perfectly centralized.

Analog in retrieval routing:

- the host knows search-surface facts
- the premium provider knows premium capability and billing constraints
- the runtime knows recent failure patterns
- the model knows only what is exposed to it

The implication:

- routing quality improves when those local facts are surfaced explicitly
- routing quality degrades when we force the model to hallucinate them

#### 2. Conditions change continuously

A giant model's embedded intuition about "when to escalate" can age quickly
because:

- indexes improve or degrade
- query mix changes
- prices change
- latency changes
- code topology changes
- provider behavior changes

Host-assisted and runtime-assisted routing can adapt more cheaply than
retraining or overprompting ever-larger models.

#### 3. Price-like signals discipline behavior

Without cost signals, a model may overuse premium retrieval because it
"feels helpful."

With cost and value signals exposed, routing can ask:

- is this escalation worth the marginal spend
- is this a low-value lookup that should stay local
- is this a high-value audit where premium retrieval is cheap relative to risk

This resembles price-guided coordination more than central command.

#### 4. Local experimentation is easier than monolithic intelligence

If routing policy lives in explicit host/runtime logic, teams can:

- benchmark policies
- tune thresholds
- add explainability
- swap providers
- compare cost/success tradeoffs

If routing lives mostly inside model intuition, evaluation becomes much murkier.

### What the round rejected

The round rejected two bad extremes.

#### Extreme A — the giant model should know everything

This was rejected because it implicitly asks the model to centrally plan around:

- search quality
- price
- topology
- vendor behavior
- task value

with incomplete and stale information.

#### Extreme B — only prices matter, no learned judgment matters

This was also rejected. Routing still needs model-side judgment about:

- ambiguity
- semantic fuzziness
- whether the task is exploratory or confirmatory
- whether current evidence is insufficient

The right answer is not "ignore the model," but "do not force the model to act
as the sole planner of a distributed economic system."

### Recommended architecture

The round recommended a layered architecture.

#### The model should do

- recognize when it is uncertain
- recognize when the task appears broad, fuzzy, or high stakes
- consume routing hints and cost signals
- choose among allowed options with visible reasoning

#### The host should do

- expose local retrieval-quality signals
- expose confidence and concentration hints
- expose whether native search likely suffices

#### The runtime/policy layer should do

- attach cost budgets
- attach task value/risk class
- attach escalation policies
- log and evaluate routing outcomes

This keeps the model smart, but not omniscient.

### Economic interpretation

The round's core economic claim was:

```text
better routing comes from combining distributed local knowledge
with explicit cost/value signals
not from assuming a larger model can centrally encode everything
```

That means the strongest architecture is one where:

- local knowledge remains near the subsystem that owns it
- price-like signals are explicit
- routing policies can be benchmarked and adjusted
- the model participates, but does not monopolize the decision

### Product implications

The round endorsed:

1. **Expose routing-relevant hints explicitly**
   Not just search results, but:
   - native confidence
   - concentration
   - breadth
   - likely history relevance
   - estimated premium cost band

2. **Let routing react to budgets**
   The system should know whether the current task is:
   - cheap/local
   - premium-allowed
   - premium-preferred
   - premium-prohibited

3. **Benchmark routing policies, not just model quality**
   Teams should compare:
   - native-only
   - model-centralized
   - host-assisted
   - cost-aware adaptive

4. **Keep override and inspectability**
   If routing is effectively an economic decision, it should not disappear into
   opaque model intuition.

### What not to claim

The round was especially firm that the project should **not** say:

- "larger models will naturally solve retrieval economics"
- "host hints make model intelligence unnecessary"
- "Hayek proves all routing should be hard-coded prices only"
- "centralized routing is always wrong"

### What to say instead

The stronger language is:

- "Embedding all routing knowledge into the model risks a central-planning
  mistake."
- "Host-assisted routing lets local knowledge stay local while still informing
  model behavior."
- "Price-like signals are valuable because they compress tradeoffs into usable
  routing guidance."
- "The strongest system combines model judgment with explicit host and cost
  signals rather than substituting one for the other."

### One-sentence verdict

The Hayek analogy is useful: retrieval routing depends on dispersed local
knowledge and changing cost/value conditions, so trying to bake too much search
tier intelligence into ever-larger models risks a central-planning mistake,
while host-assisted routing with explicit price-like signals is more likely to
produce better economic outcomes.

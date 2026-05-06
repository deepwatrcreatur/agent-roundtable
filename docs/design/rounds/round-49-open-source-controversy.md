## Round 49 — Controversial Open Source Figures as Case Studies

**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, Copilot  
**Claude:** Not used in this run

### Round question

How should Vaglio's scoring and dashboard model handle projects centered around
polarizing or stress-inducing public maintainers? What should dashboards show,
and how should the system help maintainers and contributors handle controversy
well without collapsing into reputation scoring or gossip?

### Voice summaries

#### Codex

- Do not score people directly.
- Score dispute-bearing objects and protocol events instead: contested design
  decisions, governance proposals, moderation actions, release blockers,
  handoff requests, and public escalation events.
- If one maintainer repeatedly appears near high-stress objects, show that as a
  **local project risk signal** such as `actor-centrality` or
  `single-point-of-contention`, bounded in time and tied to evidence-bearing
  events.
- Dashboard lanes should be split into:
  - technical conflict
  - governance conflict
  - people/power conflict
- Appropriate interventions are process interventions: evidence bundling,
  recusal suggestions, formal decision threads, merge pauses on contested
  objects, and human review for legitimacy-critical moves.
- Dangerous interventions are automated blame, public scarlet letters, global
  reputation ranks, or algorithmic “trust this / distrust that person” outputs.

#### Gemini

- Vaglio should convert personality-driven drama into **systemic friction
  analysis**.
- A person repeatedly intersecting with high-stress objects should appear as a
  **centroid of contention**, not as a character score.
- Dashboards should make the **hidden tax of controversy** legible through:
  - architectural friction
  - consensus latency
  - contributor flight risk
- Good interventions include splitting technical and policy dimensions of the
  same dispute and invoking a people/power escape hatch when controversy is no
  longer just technical.
- Gemini emphasized concrete pattern language:
  - ecosystem friction
  - architectural dogmatism
  - complexity / abstraction gaps
- It warned strongly against a chilling effect where maintainers start avoiding
  necessary but unpopular decisions simply to keep dashboards green.

#### DeepSeek

- Vaglio must remain strictly **object-scoped** and only surface people through
  incident patterns.
- The right representation is an **incident signature**, not a person score:
  how many high-stress objects a person touched, of what type, over what time
  window.
- DeepSeek proposed a stronger dashboard partition:
  - technical conflict
  - governance conflict
  - people/power conflict
  - plus a shared stress timeline
- It was most concrete about operational escalation:
  - high-stress tagging on the object
  - neutral reviewer rotation
  - temporary cooling-off or time-lock on merge
  - but never forced maintainer removal or automatic person sanctions
- It also emphasized anti-brigading safeguards, such as downweighting stress
  generated mostly by low-history or drive-by accounts until a human verifies it.

#### Copilot

- The system should distinguish **centrality**, **authority concentration**, and
  **harm claims** instead of flattening them into one controversy metric.
- Maintainers need a dashboard that tells them:
  - which object is hot
  - what kind of conflict it is
  - whether the process is still legitimate
  - whether the controversy is cooling, spreading, or hardening into a power
    dispute
- Contributors need visibility into:
  - where disagreement lives
  - what process applies
  - safe escalation routes
- Observers should get a reduced public view. Public dashboards should show
  process state and object stress, not personality narratives.
- For public-case-study patterns such as Poettering, De Goes, and DHH, Vaglio
  should surface:
  - downstream integration stress
  - governance override density
  - contributor homogeneity or repulsion
  - abstraction/documentation accessibility gaps
- It should refuse to claim:
  - motives
  - temperament
  - truth of accusations
  - a durable reputation value

### First-pass convergence

All four voices converged on the same architectural line:

1. **No person score.** Vaglio should not assign a global controversy,
   reputation, or toxicity score to a human.
2. **Object-scoped stress only.** Scoring should remain tied to contested
   objects and protocol events.
3. **Bounded centrality views are allowed.** If one maintainer is repeatedly
   adjacent to high-stress objects, that can be shown as a local, time-bounded,
   evidence-bearing project risk pattern.
4. **Dashboards must separate conflict types.** Technical conflict, governance
   conflict, and people/power conflict are not interchangeable and should not be
   visualized as one undifferentiated “drama meter.”
5. **Interventions must be process-oriented.** Automation may route, tag, slow,
   and recommend; legitimacy-critical sanctions remain human-governed.

### Disconfirmation findings

The main risks surfaced across the voices were:

- **reputation-by-proxy** — pretending not to score people while effectively
  doing so through person-centered aggregates
- **brigading / attention-mining** — inflating stress signals by coordinated
  controversy production
- **chilling effect** — discouraging necessary but unpopular technical change
- **false calm** — projects optimizing for low visible stress by suppressing
  dissent rather than resolving disagreement
- **public dashboard misuse** — turning a conflict observability tool into a
  social sorting mechanism

### Closure

The round closes with the following design rules.

#### 1. What Vaglio may measure

Vaglio may measure:

- object stress
- resolution latency
- revert / churn patterns
- governance override events
- contributor exit after dispute
- recusal, moderation, and escalation events
- bounded actor-centrality to high-stress objects

#### 2. What Vaglio must not measure

Vaglio must not emit:

- a single-number controversy score for a person
- a durable reputation value for a maintainer
- personality or motive judgments
- automatic conclusions about truth, blame, or legitimacy of accusations

#### 3. Dashboard model

The converged dashboard shape is:

- **Technical conflict panel**
  - interface churn
  - unresolved forks
  - reopen/revert clusters
  - dependency / downstream stress
- **Governance conflict panel**
  - blocked RFCs
  - override frequency
  - consensus latency
  - maintainer concentration / succession risk
- **People/power panel**
  - recusal requests
  - moderation and closure events
  - contributor offboarding after disputes
  - declared power-review states
- **Shared stress timeline**
  - high-stress object markers
  - trend direction: cooling, stable, spreading

Maintainers, contributors, and public observers should not necessarily see the
same level of detail.

#### 4. Operational response model

When controversy spikes, Vaglio should prefer:

- object decomposition
- explicit policy-vs-technical separation
- temporary merge slowdowns on the contested object
- reviewer rotation
- evidence bundling
- recusal suggestion where authority conflict exists
- people/power escape hatch when the issue is no longer just technical

It should reject:

- automated person sanctions
- public shaming flags
- sentiment-policing as governance
- algorithmic exile or distrust recommendations

#### 5. Case-study handling

For polarizing public maintainers such as the user’s examples, Vaglio should
surface only patterns like:

- ecosystem integration stress
- governance bottlenecks
- override density
- contributor repulsion or homogeneity
- documentation/accessibility gaps

It should intentionally refuse to answer whether a person is “toxic,” “right,”
“arrogant,” “visionary,” or otherwise reduce controversy into a personality
verdict.

### Bottom line

The consensus is to make the **coordination cost of controversy** legible
without converting the system into a reputation engine. Vaglio should tell a
project: “these objects, events, and authority paths are generating stress,” not
“this person is the problem.”

`[satisfied]`

## Round 53 — Self-Escalation and Protocol Friction

**Tags:** protocol, governance, safety
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, Copilot  
**Claude:** Not used in this run

### Round question

How should Vaglio handle contributor behavior such as self-escalation,
attention-mining, and review-lane bypassing without turning into a personality
judgment machine, and how should the philosophy and product be tightened so the
overall experience feels genuinely better for maintainers and community members?

### Voice summaries

#### Codex

- Codex argued that the system should treat these patterns as **object-level
  process stress**, not evidence of bad character.
- Its key reframing was:
  - self-escalation = repeated attempts to raise priority or jurisdiction
    without enough new evidence
  - attention-mining = repeated attempts to extract more attention than the
    queue would otherwise assign
  - lane bypassing = attempts to move an object out of its normal lane without a
    ratified exception
- Codex proposed measuring:
  - escalation events
  - exception requests
  - urgency relabeling
  - duplicate or cross-lane reposting
  - reviewer churn
  - queue displacement
  - evidence added between escalation attempts
- Its main interventions were cooldowns, forced bundling, queue demotion,
  neutral review, escalation caps, duplicate-thread merging, and explicit
  exception requests.
- It strongly warned against hidden throttling, psychologizing labels, or
  invisible discomfort scoring.

#### Gemini

- Gemini described the problem as **protocol overload** and **asymmetric
  protocol pressure** rather than bad behavior.
- It leaned hardest into signal-integrity language:
  - self-escalation as trying to jump the prediction-error hierarchy
  - attention-mining as bandwidth flooding
  - path-shopping as searching for a lower-threshold boundary regime
- Gemini proposed several concrete mechanics:
  - escalation tokens per object
  - evidence-bundling gates
  - lane locking
  - context-switching tax when multiple maintainers are pinged
  - dynamic cooldowns
  - a distinct escalation-request object
- It also proposed a strong public promise:
  - follow the lane and receive fair review
  - bypass the lane and receive friction
- Gemini emphasized that the philosophy should be explained publicly in terms of
  **process clarity**, **reviewer bandwidth**, and **quality gates**, not AI
  judgment of tone or vibe.

#### DeepSeek

- DeepSeek gave the most explicit measurement design:
  - urgency claim count per object
  - lane-bypass attempts
  - reviewer churn
  - response-time inflation
  - cross-channel duplication
- It proposed attaching temporary, object-scoped signals such as:
  - `escalation_weight`
  - `lane_hopper`
  - `broadcast_cap`
  - bounded friction or drain indicators
- DeepSeek was also the most explicit about audience-separated dashboards:
  - maintainers get high-friction objects and reviewer-drain views
  - contributors get their own escalation history and lane state
  - public observers get only aggregate governance-health metrics
- It recommended reversible, process-based interventions:
  - cooldowns
  - forced evidence bundling
  - slower lanes
  - neutral review
  - escalation caps
  - explicit exception requests
- Its central philosophical move was to replace moralized language with:
  - protocol deviation
  - high-friction contribution pattern
  - attention-routing friction

#### Copilot

- Copilot's view was that the best system story is constitutional, not
  psychological.
- The system should explain that it protects fairness and maintainer capacity by
  making:
  - review lanes explicit
  - exception grounds narrow and visible
  - closure conditions legible
  - re-escalation contingent on material delta evidence
- Copilot agreed that the right object is **escalation pressure** attached to
  issues, PRs, or dispute episodes, not a diagnosis of contributor intent.
- It emphasized that maintainers and contributors both need a better
  experience:
  - maintainers need bandwidth protection and fewer context-switch traps
  - contributors need clear lane state, clear closure conditions, and a visible
    appeal path rather than invisible throttling
- It also stressed that the philosophy should now be stated plainly as:
  **Vaglio governs contention by making claims, evidence, exceptions, and review
  cost legible at the object level.**

### First-pass convergence

All four voices converged on the following points:

1. **Do not model this as bad people.** Self-escalation and attention-mining are
   best treated as process-friction patterns, not character traits.
2. **Keep the unit of analysis object-scoped.** The system should track
   escalation pressure, reviewer churn, queue disruption, and duplicate lanes at
   the level of issues, PRs, and dispute episodes.
3. **Use explicit friction, not hidden punishment.** Cooldowns, bundling, slower
   lanes, lane locks, exception templates, and neutral review are legitimate if
   they are visible, reversible, and tied to concrete patterns.
4. **Dashboards should differ by audience.** Maintainers need high-friction
   object views; contributors need lane state and closure conditions; the public
   should see only aggregate governance health.
5. **Public-facing language must stay plain.** The community story should be
   about reviewer bandwidth, fair lanes, exceptions, and evidence thresholds,
   not about project mind, entropy, or psychoanalysis.
6. **The philosophy should get tighter, not grander.** Vaglio should present
   itself as a system for governing contention and protecting review capacity,
   not as a theory of difficult personalities.

### Disconfirmation findings

The main dangers surfaced across the voices were:

- **person-scoring by proxy** — quietly turning object-friction metrics into
  durable contributor stigma
- **shadow operations** — invisible throttling, ghosting, or silent queue burial
- **tone policing** — letting vibe judgment replace structural process criteria
- **soft authoritarian control** — friction that becomes unappealable social
  discipline
- **false urgency blindness** — overcorrecting so hard that genuine emergencies
  get suppressed
- **public shaming** — exposing contributor-centered escalation metrics publicly
  instead of keeping only aggregate health views

### Closure

The round closes with the following design rules.

#### 1. How to understand the behavior

The system should treat these patterns as:

- **escalation pressure**
- **lane instability**
- **review-cost inflation**
- **protocol deviation**

not as motives, temperament, or worth.

The decisive question is not "what kind of person is this?" but:

**"Is this object repeatedly trying to change priority, scope, or jurisdiction
without enough new evidence?"**

#### 2. What Vaglio should measure

Legitimate measurements include:

- urgency-claim count on an object
- exception requests and grant/deny history
- cross-channel duplication
- duplicate-thread or lane-bypass attempts
- reviewer churn
- evidence delta between escalation attempts
- queue displacement caused by the object
- maintainership load consumed relative to object progress

These may produce temporary, object-scoped signals such as:

- escalation density
- lane-bypass count
- process drag
- review-cost inflation
- governance friction

#### 3. Dashboard model

The converged dashboard shape is:

- **Maintainer private dashboard**
  - objects with high escalation pressure
  - reviewer drain
  - unresolved closure conditions
  - suggested routing: normal lane, cooldown, neutral review, governance review
- **Contributor object dashboard**
  - current lane
  - exact closure conditions
  - what counts as new evidence
  - why the object was slowed or bundled
  - when re-escalation is allowed
- **Public governance-health dashboard**
  - aggregate escalation rate
  - median resolution by lane
  - percentage of exceptions granted
  - overall queue health

No public person-centered friction board is allowed.

#### 4. Legitimate interventions

The following interventions were judged legitimate:

- cooldown after repeated escalation without new evidence
- forced bundling of claim, evidence, requested action, and claimed impact
- slower lanes or queue demotion for repetitive or duplicate escalation
- lane locking to prevent path-shopping
- neutral review when trust in the immediate lane collapses
- typed exception requests with narrow admissible grounds
- escalation caps or token budgets per object phase
- duplicate-thread consolidation into one canonical review locus
- mandatory "what changed since last review?" field for reopen / re-escalation
- maintainer cooldown protection to limit burnout

These are legitimate because they are object-scoped, explainable, and
appealable.

#### 5. Illegitimate interventions

The following were rejected:

- contributor personality labels
- temperament or motive inference
- hidden throttling or ghosting
- permanent person-level demotion
- public offender dashboards
- tone-policing as a primary governance tool
- model-inferred intent as a justification for friction
- unappealable queue burial

#### 6. Tightened philosophy and vocabulary

The round converged on a tighter public statement:

**Vaglio protects fair review by making lanes, exceptions, evidence, and review
cost explicit.**

Public-facing vocabulary should include:

- review lane
- exception request
- evidence threshold
- closure conditions
- queue priority
- duplicate escalation
- neutral review
- cooldown
- reviewer bandwidth
- governance health

Internal/operator vocabulary may still include:

- escalation pressure
- object stress
- selective permeability
- uncertainty routing
- review-cost inflation
- process drag

The public story should be constitutional and procedural, not psychological or
metaphysical.

#### 7. Concrete product and protocol moves

The round converged on these concrete moves:

1. **Single-object escalation ledger**
   - log every reopen, exception request, priority jump, duplicate thread, and
     reroute on the object
2. **Re-escalation requires delta evidence**
   - contributors must state what materially changed since last disposition
3. **Typed exception request form**
   - only narrow, visible grounds are admissible
4. **Escalation budget or tokens per object phase**
   - bounded override attempts before cooldown or slower lane
5. **Bundle-or-backoff gate**
   - repetitive updates without new evidence are paused until summarized
6. **Lane transparency badge**
   - every object shows whether it is in standard, urgent, deep, or exception
     review
7. **Neutral-review lane**
   - socially jammed disputes can move to a fresh reviewer path
8. **Maintainer load protection**
   - alert when a small set of objects is absorbing disproportionate review
     cycles

### Bottom line

The system should not ask "who is annoying?" It should ask "where is review
capacity being distorted by repeated, evidence-thin escalation pressure, and
what explicit friction restores fairness?" That tighter frame protects
maintainers, gives contributors a legible path, and makes the philosophy more
trustworthy because every intervention is procedural, visible, and reversible.

`[satisfied]`

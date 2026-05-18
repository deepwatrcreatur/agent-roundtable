# Round 87 — `jj` Graph Evidence for Prediction Calibration

**Status:** Closed  
**Tags:** tooling, structural, epistemic-integrity  
**Voices used:** Copilot synthesis, local repo grounding, focused exploration memo  
**Additional note:** this round connects the recent `jj` protocol work to the
new vouch-calibration work and asks how predictions should be updated as graph
activity unfolds

### Round question

The maintainer wanted a round on:

- how measures of judgment/taste should be updated as activity is recorded on the
  `jj` graph
- how prediction and interpretation can be linked to later graph evidence
- how community reaction, merges, supersessions, reversions, and adoption should
  affect confidence in earlier vouches
- how to do this without sliding into person-level reputation scoring

### Relevant prior context

This round built directly on:

- **Round 47** — claim-scoped vouches, object-scoped stress, and governance-first
  interpretation
- **Round 50** — promises-versus-outcomes, object-scoped merit, and the dashboard
  model with calibration and dispute lanes
- **Round 55** — anti-brigading, socially coupled updating, and the separation of
  evidence from coalition signal
- **Round 68** — non-exported trust signals should be local, routing-oriented, and
  strongly bounded
- **Round 74** — the repo-native knowledge base should be grounded in explicit
  records and supersession rather than hidden memory
- **Round 85** — `jj` should be used with explicit path, supersession, conflict,
  and delta metadata
- **Round 86** — "good taste" is too prestige-prone; only narrow, recent,
  domain-specific, claim-scoped calibration is defensible

### Local grounding

The repo already treats `jj` as a provenance-rich change graph rather than a
mere commit log:

- `change_id` is the durable reference for evolving work
- descriptions already support fields like `Supersedes:`, `Path:`,
  `Related-Round:`, and `Decision-Needed:`
- conflicts can be preserved as durable review state rather than hidden
- `HumanAnchor` already stores claim-scoped vouches, though not yet with outcome
  linkage

The round asked what must be added so these change records can support later
calibration of predictive judgment.

### First-pass convergence

The round converged on the following points.

1. **The `jj` graph is a legitimate outcome surface, not a popularity surface.**
   Merges, supersessions, reversions, conflict resolution, maintenance churn, and
   cross-context adoption are meaningful because they describe what happened to an
   object over time. Comment velocity, raw visibility, and social reaction by
   themselves are not equivalent evidence.

2. **Predictions must be made legible before they can be judged.**
   A system cannot assess foresight if earlier claims were vague. Prediction-like
   vouches need explicit fields for:
   - what was expected
   - what risks were named
   - what subsystem or object type was in scope
   - when the prediction should expire

3. **Graph events should update prediction calibration by comparing promises to
   outcomes.**
   The important question is not "did people like this branch?" but:
   - did it merge
   - did it hold up
   - was it later superseded
   - was it reverted
   - did the named failure modes occur
   - did maintenance burden stay within what was implied

4. **The system must distinguish predictive, confirmatory, and coalitional
   vouches.**
   This follows directly from Round 86:
   - **predictive** vouches arrive before wide recognition and include explicit
     basis
   - **confirmatory** vouches arrive later but still add independent reasons
   - **coalitional** vouches mostly echo visible approval without new basis
   Only the first class should strongly influence anticipatory calibration.

5. **Vouch updates must be evidence-linked.**
   If someone changes a verdict after visibility or consensus shifts, the update
   should only count as meaningful if tied to new evidence: a benchmark, a test,
   an addressed objection, a precedent, or a concrete field outcome. Otherwise it
   should be treated as possible cascade participation rather than refined
   judgment.

6. **All aggregation must remain local, domain-scoped, decaying, and
   non-prestige-bearing.**
   The round remained firm that no global taste score, public top-predictor list,
   or portable reputation layer is acceptable. The only allowed aggregation is a
   bounded routing signal such as recent prediction accuracy on a specific
   subsystem and claim type.

### Legitimate graph evidence

The strongest graph events for calibration were:

- **merge/adoption**
- **explicit supersession**
- **reversion or rollback**
- **conflict state with deliberate resolution**
- **maintenance follow-up and regression burden**
- **replication or adoption across independent contexts**

These are legitimate because they are object/process outcomes, not social
standing signals.

### Illegitimate proxies

The round rejected using the `jj` graph as a backdoor person-ranking system
through proxies like:

- commit volume
- first-to-comment timing by itself
- follower or watcher relationships
- comment verbosity
- like/upvote velocity
- early bookmark creation without basis

These are too vulnerable to visibility effects, coalition behavior, and gaming.

### What metadata is needed

The round favored extending current `jj` description practice with explicit
prediction-bearing fields such as:

- `Prediction-ID:`
- `Scope:`
- `Risk-Class:`
- `Expected-Properties:`
- `Expected-Failure-Modes:`
- `Vouch-Basis:`
- `Vouch-Expiry:`

And explicit outcome-linking fields on later graph events such as:

- `Outcome-Link:`
- `Outcome-Verdict:`
- `Outcome-Notes:`
- `Calibration-Delta:`

This was treated as a natural extension of the existing `Supersedes:` / `Path:`
/ `Related-Round:` protocol rather than a new architecture.

### Data model direction

The round favored a three-part model:

1. **predictions**
   what was claimed, by whom, for what subsystem/object type, with expiry

2. **vouches**
   who vouched, when, on what basis, and in which class
   (`predictive`, `confirmatory`, `coalitional`)

3. **graph outcomes**
   what later happened on the graph and how that outcome bears on the earlier
   prediction

This makes calibration auditable and keeps the center of gravity on explicit
object history rather than latent social inference.

### Surface design

The round drew a line between legitimate and illegitimate surfaces.

Legitimate:

- change-level provenance cards showing which predictions were later verified or
  violated
- internal subsystem calibration views with recent-window, claim-type-scoped
  accuracy and visible sample size
- reviewer-routing assistance based on narrow, recent domain calibration
- object stress/dispute views that show how many strong objections remain and what
  basis they rest on

Illegitimate:

- person leaderboards
- exported trust scores
- cross-project portability
- prestige badges
- opaque de-boosting or hidden reputation adjustments

### Concrete recommendation now

1. Extend `docs/JJ_GUIDE.md` with prediction-bearing metadata conventions.
2. Extend `HumanAnchor` or adjacent schema with:
   - prediction IDs
   - vouch class
   - basis detail
   - expiry
   - linked outcome verdicts
3. Require evidence links for strong vouch updates after consensus shifts.
4. Treat merges, supersessions, reversions, and maintenance burden as the main
   outcome surfaces for calibration.
5. Keep any aggregate calibration internal, recent-windowed, subsystem-scoped,
   and sample-size-visible.

### One-sentence verdict

The `jj` graph should be used as an object-level evidence trail for testing
whether explicit predictions held up over time, with calibration updating through
linked outcomes and strong anti-cascade safeguards — not as a hidden machine for
scoring people by popularity, volume, or prestige.

# `jj` High-Velocity Ingest Contract

**Status:** Drafted from Rounds 60 and 120
**Purpose:** Define how Vaglio should absorb high-rate agent change traffic
without making raw write velocity the canonical control plane or allowing the
review/gate surfaces to stall under load.

---

## 1. Boundary

This note answers a narrow question:

> How should Vaglio ingest many agent-originated `jj` changes quickly while
> keeping governance, review, and promotion semantics stable?

It does **not** define:

- the final hosted backend substrate
- a complete `jj` remote protocol
- release or publish authority
- a requirement that every raw agent write immediately becomes expensive CI work

The goal is a layered ingest model where:

- `jj` remains the inner-loop execution/change substrate
- governance objects remain authoritative above raw change traffic
- expensive evaluation is triggered only after a change gains enough local
  signal to justify it

---

## 2. Design stance

The project should treat high-velocity ingest as a **traffic-shaping** problem,
not as proof that raw branch/commit throughput should own the whole product
architecture.

The layered stance is:

1. use `jj`-native change semantics for agent-local authoring and conflict
   handling
2. keep Git-compatible transport and backend portability honest at the outer
   boundary
3. separate cheap ingest from expensive review, test, and promotion work

That preserves the `jj` inner-loop advantage without forcing every raw change to
immediately contend for the same expensive control-plane resources.

---

## 3. Three ingest layers

### 3.1 Raw agent traffic layer

This is the highest-rate layer.

It contains:

- ephemeral `jj` changes
- retries and abandoned attempts
- intermediate machine-generated states
- conflict-heavy or low-confidence drafts

Requirements:

- writes must stay cheap
- deduplication must be possible
- failures here must not stall the board or promotion surfaces

### 3.2 Vouched candidate layer

This layer contains changes that gained enough basis to be worth durable review.

Typical signals:

- explicit vouch or no-objection basis
- board claim/attempt linkage
- successful scoped local checks
- evidence attachments from Sourcegraph, reports, or prior rounds

This is the first layer where richer indexing and review routing are justified.

### 3.3 Promotion-ready layer

This layer contains changes that have survived the sieve and are now eligible
for:

- stronger CI/test spend
- human review concentration
- release/publish gate evaluation

The important rule is that only a minority of raw ingest should reach this
layer.

---

## 4. Emergent storage split

The storage model should distinguish between **traffic capture** and
**governance-grade signal**.

### 4.1 Storage classes

| Class | Contents | Retention posture | Canonicality |
|---|---|---|---|
| `raw_attempt_ingest` | ephemeral `jj` changes, retries, abandoned drafts, burst traffic metadata | compactable / degradable | not canonical governance truth |
| `candidate_signal` | vouches, scoped checks, lineage evidence, board links, report links | medium-lived, queryable | part of durable review context |
| `promotion_record` | decisions, objections, approvals, release gates, final attempt outcomes | durable | canonical governance truth |

### 4.2 Why this split matters

Without this split, the system is forced into one of two bad outcomes:

- treat all raw traffic as first-class truth and drown the review layer
- or discard too much raw traffic and lose replay/explanation ability

The correct posture is:

- preserve enough raw ingest for replay and debugging
- elevate only signal-bearing subsets into durable governance-facing views

This is the intended meaning of an **Emergent Storage** layer: raw machine
traffic can exist, but only some of it "emerges" into the durable, queryable
surfaces used for judgment and routing.

---

## 5. Sieve-first evaluation model

Traditional webhook CI assumes that every incoming change deserves immediate
testing and expensive execution. That is a poor fit for high-volume agent
traffic.

Vaglio should instead use a sieve-first model.

### 5.1 Stages

| Stage | Purpose | Cheap? | Trigger for next stage |
|---|---|---|---|
| `ingest` | accept raw `jj` attempt/change metadata | yes | change is linked to a live claim/attempt |
| `local sieve` | run low-cost invariant checks, path/policy checks, dedupe, conflict classification | yes | passes basic integrity and relevance filters |
| `social / evidentiary sieve` | require vouch basis, board relevance, or linked evidence | moderate | accumulates enough basis to justify expensive spend |
| `expensive evaluation` | deeper tests, hosted analysis, stronger CI, replay checks | no | passes gate thresholds |
| `promotion gate` | human and policy decision | no | explicit approval / release action |

### 5.2 Admission rule

Expensive test or hosted analysis work should begin **after** a change crosses
an explicit threshold, not merely because a raw write exists.

Possible threshold signals:

- explicit board claim and attempt linkage
- positive vouch basis from a scoped actor
- accumulated evidence links
- policy-driven risk routing
- survival through local invariant checks

This turns "social momentum" into a narrow governance concept rather than a
vague popularity contest.

---

## 6. Concurrency and stall avoidance

The ingest layer must be engineered so that burst traffic does not seize the
same scarce resources used by the review/control plane.

### 6.1 Shared resources that must not be saturated by raw ingest

- board read model refresh
- lease and claim mutation path
- expensive test/external-analysis workers
- durable promotion record writes
- operator-facing browse surfaces

### 6.2 Rules

- raw ingest must be append-friendly and tolerant of deferred indexing
- review/promotion tables must remain writable even during burst traffic
- expensive jobs must be admission-controlled behind the sieve
- duplicate or superseded raw attempts should compact cheaply

### 6.3 Practical implication

If the system must choose between:

- perfect freshness of every raw ingest projection
- or responsiveness of board/review/gate surfaces

it should preserve the board/review/gate surfaces first.

---

## 7. `jj` colocated mode posture

`jj` colocated mode is appropriate for the inner loop when:

- agents need local change-graph semantics
- conflict states should remain first-class
- ephemeral attempts are frequent

But colocated mode alone is not the scalability story.

The scalability story is:

- `jj` for cheap local authoring and graph manipulation
- explicit ingest separation between raw attempts and durable signal
- backend/provider acceleration as an optional performance tier, not the sole
  correctness path

That matches the broader backend portability stance from Round 120.

---

## 8. Benchmark contract

The benchmark goal should be treated as an operational contract, not as a
marketing number.

### 8.1 Target scenario

Evaluate whether the system can tolerate **1,000+ agent-originated change
events per minute** without making the control plane unusable.

### 8.2 Required benchmark dimensions

| Dimension | What to measure |
|---|---|
| raw ingest throughput | accepted change/attempt events per minute |
| board freshness | delay before claim/attempt surfaces reflect relevant signal |
| expensive-job admission | rate at which expensive evaluation work is triggered |
| compaction/replay cost | cost to reconstruct a subset of raw ingest after burst load |
| contention profile | lock waits / queue depth on shared resources |

### 8.3 Success criteria

The benchmark should count as a pass only if:

- raw ingest continues at target rate
- board and gate surfaces remain responsive
- expensive work remains admission-controlled
- replay of a chosen attempt subset remains possible

It is **not** enough to prove only that a write sink can absorb 1,000 events per
minute while the human-facing control plane becomes unusable.

---

## 9. Recommended implementation sequence

1. define the ingest classes and lifecycle transitions explicitly
2. store raw attempt-ingest metadata separately from promotion-grade records
3. add local-sieve classification before any expensive evaluation dispatch
4. expose queue-depth / stall metrics for the board and gate surfaces
5. run synthetic burst benchmarks before promising high-rate hosted operation

---

## 10. Final synthesis

The right answer is not "test every write" and not "ignore raw traffic."

It is:

- cheap `jj`-native inner-loop authoring
- clear separation between raw ingest and durable governance signal
- sieve-first escalation into expensive analysis and promotion
- benchmarked protection of board/gate responsiveness under burst traffic

That is the minimal contract required for Vaglio to benefit from high agent
velocity without becoming structurally owned by it.

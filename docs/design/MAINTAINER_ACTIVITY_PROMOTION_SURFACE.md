# Maintainer Activity and Promotion Surface

**Status:** Drafted from Round 117  
**Purpose:** Define the smallest maintainer-facing surface that makes agent
activity legible, reviewable, and governable without requiring operators to
learn the full lease / attempt protocol first.

---

## 1. Product goal

The maintainer-facing surface should answer one practical question:

> What is happening in this repo right now, and what needs a human decision?

This surface is not a workflow console for specialists.

It is a forge-native activity layer that lets ordinary maintainers:

- see active agent work
- see who currently owns a resource or task
- notice stalled or conflicting work
- understand whether a change is still draft, ready for review, or eligible for
  promotion
- keep merge / publish authority visibly human

The intended feel is “slightly smarter forge activity view,” not “Kubernetes
dashboard for coding agents.”

---

## 2. Design boundary

This surface sits above canonical governance and board state.

It should read from:

- `Claim`
- `Lease`
- `Attempt`
- `ReviewState`
- `PromotionGate`
- `AuthorityScope`

It may use board read-model projections for calm default rendering, but it
should not invent new authority of its own.

The surface owns:

- repo-level summarization
- calm maintainer copy
- progressive disclosure
- human decision affordances

It does **not** own:

- executor scheduling
- runtime orchestration
- hidden auto-promotion
- policy bypass

---

## 3. Default maintainer view

The smallest useful default is one repo-level page with five sections.

### 3.1 Activity strip

A compact top strip summarizing:

- active claims
- active leases
- running attempts
- gated items
- promotion-ready items

This should feel similar to a forge’s existing issue/PR counters rather than a
new monitoring dashboard.

### 3.2 Current work lane

A short list of currently active work items showing:

- title
- owner
- resource scope
- current attempt state
- freshness

This is the “what is being worked on now” view.

### 3.3 Needs attention lane

A lane for items that deserve maintainer review because they are:

- blocked on a human gate
- stale
- in resource contention
- superseded or conflicted
- waiting for promotion/release judgment

This is the default inbox of intent.

### 3.4 Promotion queue

A list of candidate outputs that have crossed from draft execution into proposed
work and now require human merge/publish authority.

Each entry should show:

- proposed outcome
- originating attempt
- current review state
- risk or trust level
- promotion gate type

### 3.5 Recent lineage feed

A compact append-only history slice showing:

- claim created
- lease acquired or transferred
- attempt started
- human gate opened
- review resolved
- promotion accepted or rejected
- supersession

This gives maintainers recent context without forcing them into raw event logs.

---

## 4. Card model

Each maintainer-visible card should expose a calm, forge-familiar summary.

Minimum default fields:

| Field | Meaning |
|---|---|
| `title` | Human-readable work summary |
| `owner` | Human or agent currently responsible |
| `scope` | Repo / branch / live-resource target |
| `state` | Draft, proposed, gated, reviewed, promoted, failed |
| `freshness` | Fresh, stale, expired, superseded |
| `next_signal` | What most likely needs to happen next |
| `evidence` | Linked reports, board detail, analysis surface, discussion round |

Expanded detail should reveal:

- active claim
- active lease if any
- current attempt lineage
- review state
- promotion gate state
- supersession chain
- authority scope / why this maintainer is being asked

---

## 5. User-facing state model

The surface should translate protocol objects into a maintainer-legible state
model.

### 5.1 Draft work

Work is in progress, still exploratory, and not yet asking for merge/publish
authority.

Maps to:

- active `Claim`
- active or recent `Attempt`
- possibly active `Lease`
- no satisfied promotion gate yet

Default copy:

- `In progress`
- `Agent-owned draft work`

### 5.2 Proposed work

An attempt has produced something concrete enough to review.

Maps to:

- current successful or reviewable `Attempt`
- `ReviewState = proposed`
- optional open `PromotionGate`

Default copy:

- `Ready for review`
- `Proposed output awaiting maintainer judgment`

### 5.3 Reviewed work

A maintainer or delegated reviewer has inspected the proposal, but it has not
yet crossed the final promotion boundary.

Maps to:

- `ReviewState = reviewed`
- `PromotionGate = pending` or equivalent

Default copy:

- `Reviewed`
- `Awaiting promotion decision`

### 5.4 Promoted or publishable work

The proposal has cleared its explicit human boundary and is now eligible for
merge, release, or deploy.

Maps to:

- resolved `PromotionGate`
- positive `ReviewState`

Default copy:

- `Approved for merge`
- `Approved for publish`

### 5.5 Closed with issue

The work is no longer current but remains important because it failed,
conflicted, or was superseded.

Maps to:

- failed `Attempt`
- expired `Lease`
- rejected review
- explicit supersession

Default copy:

- `Needs follow-up`
- `Superseded`
- `Promotion rejected`

---

## 6. Maintainer interactions

The surface should expose a very small set of human actions.

### 6.1 Approve or reject promotion

Allowed only when:

- a proposal has reached a promotion boundary
- the viewer has the required authority scope

This must remain the explicit human authority step.

### 6.2 Request clarification or retry

Used when the proposal is not ready, but the right move is more work rather
than a terminal rejection.

This should open or update a human gate rather than hiding the decision in free
text.

### 6.3 Inspect ownership and contention

Maintainers should be able to answer:

- who owns this claim
- which agent/runtime holds the mutation lease
- whether another attempt superseded this one
- whether the resource scope is contested

This is inspection first, not manual lease micromanagement.

### 6.4 Override or reclaim

This should exist, but stay in progressive disclosure.

Examples:

- force-expire stale lease
- reassign claim
- mark attempt superseded
- dismiss stale promotion request

These are operator-grade actions, not the default maintainer path.

---

## 7. Progressive disclosure model

The surface should have three disclosure layers.

### Layer 1 — Calm default

Visible by default:

- counts
- short cards
- promotion queue
- recent meaningful events

### Layer 2 — Evidence and lineage

Visible on expansion:

- related reports
- board detail
- attempt summaries
- supersession lineage
- claim/lease ownership detail

### Layer 3 — Coordination internals

Visible only when requested:

- lease TTL and renewal detail
- low-level attempt events
- authority-scope reasoning
- resource contention metadata
- manual override controls

This keeps ordinary maintainers from needing to think in protocol objects first.

---

## 8. Forge-native alignment

The surface should reuse familiar forge concepts rather than inventing parallel
ones.

| Forge concept | Maintainer surface translation |
|---|---|
| Issue / work item | Claim-backed task card |
| Pull request / proposed patch | Promotion-ready proposal |
| Reviewer request | Human gate or review state |
| Branch protection / release rule | Promotion gate |
| Activity feed | Attempt / review / promotion lineage |

The mental model should be:

- “agents are producing draft and proposed work inside the same repo reality I
  already understand”

not:

- “I now need to operate a separate orchestration platform.”

---

## 9. Relationship to existing surfaces

This design should compose with existing `agent-roundtable` surfaces.

### Board

The current `/board` remains the execution-oriented operator surface.

It is strongest for:

- lane state
- runtime ownership
- stuck work
- evidence links

### Forgejo shell / reports

The `/forgejo-shell` and `/forgejo-shell/reports` surfaces remain evidence and
analysis views.

They are strongest for:

- repo analysis
- sampled evidence
- stress/heat reports
- public demo narratives

### Maintainer activity / promotion surface

This new surface should sit above both:

- calmer than `/board`
- more governance-oriented than `/forgejo-shell`
- explicitly centered on “what needs my review or authority?”

---

## 10. Recommended first implementation slice

The smallest valuable implementation is:

1. repo-level activity header
2. `Current work` lane
3. `Needs attention` lane
4. `Promotion queue`
5. selected-card detail with:
   - owner
   - scope
   - review state
   - promotion gate
   - evidence links

This first slice should be read-mostly.

Do **not** begin with:

- full workflow authoring
- arbitrary override forms
- executor control panels
- hidden auto-promotion

Those belong later, if ever.

---

## 11. Success criteria

This surface is successful when an ordinary maintainer can:

- tell what agents are actively doing in a repo
- tell whether anything is blocked or stale
- tell what is waiting for human review or promotion
- understand the minimum lineage behind a proposal
- keep human merge/publish authority explicit

without first learning claim/lease internals, local daemon design, or executor
contracts.

---

## 12. Summary

The correct maintainer-facing surface is not a general orchestration console.

It is a calm repo-level activity and promotion view that:

- summarizes active claims, leases, attempts, and blocked work
- distinguishes draft, proposed, reviewed, and promoted states
- preserves human promotion authority
- exposes deeper coordination detail only on demand

That is the smallest product slice that makes cooperative agent work legible
and governable for maintainers without asking them to become workflow experts.

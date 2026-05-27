# Maintainer Activity and Promotion Surface

**Status:** Drafted from Round 117
**Purpose:** Design the smallest maintainer-facing UX that makes cooperative
agent work legible and governable without requiring operators to become
orchestration experts.

---

## 1. Principle

**The forge should feel like a slightly smarter GitHub, not an orchestration
console for specialists.**

Round 117 converged on the line that maintainers need visibility into agent
coordination state, but the UX must map to familiar forge concepts (issues,
PRs, activity feeds, branch protection) rather than inventing a separate
orchestration dashboard.

The strongest UX metaphor from the round was DeepSeek's "inbox of intent":
maintainers see what agents are trying to do, what is blocked, and what needs
their attention — not worktree paths, lease TTLs, or DAG nodes.

---

## 2. Progressive Disclosure Model

The activity surface uses the same progressive disclosure strategy as the
publishing UX (item 88):

| Maintainer stage | What they see | What is hidden |
|---|---|---|
| **Solo + one agent** | "Agent is working on issue #42 → PR ready for review" | Claims, leases, attempt lineage |
| **Small team + agents** | Activity feed showing who owns what, what is blocked, what needs review | Lease TTLs, contention classes, capability profiles |
| **Growing team** | Full coordination detail: claims, leases, conflicts, supersession history | Nothing — all detail is available |

Day-one maintainers never need to learn what a claim or lease is. They see
familiar objects: issues being worked on, PRs awaiting review, and a clear
indication of who (human or agent) currently owns each piece of work.

---

## 3. Core Views

### 3.1 Activity feed

The primary surface is a repo-level activity feed that shows coordination
events in familiar language:

| Event type | What the maintainer sees |
|---|---|
| Claim created | "Agent X started working on issue #42" |
| Attempt started | "Agent X began implementation (attempt 2)" |
| Attempt completed | "Agent X opened PR #87 for review" |
| Attempt failed | "Agent X's attempt on issue #42 failed — see logs" |
| Attempt superseded | "Agent Y took over issue #42 from Agent X" |
| Blocked | "Issue #42 is blocked — Agent X waiting on lease for host:staging" |
| Awaiting review | "PR #87 is ready for your review" |
| Promotion requested | "PR #87 passed all gates — merge when ready" |

The feed uses natural language, not protocol terminology. "Claim created"
is the internal event; "started working on" is what the maintainer reads.

### 3.2 Ownership view

A single-page view showing current ownership across the repo:

| Column | Description |
|---|---|
| Work item | Issue or task being worked on |
| Owner | Human or agent currently responsible |
| Status | Draft / in progress / blocked / awaiting review / approved |
| Current attempt | Which attempt number, with link to logs |
| Blocked by | What is preventing progress (if anything) |
| Time active | How long the current attempt has been running |

This view answers the question every maintainer asks: "who is working on what
right now?"

### 3.3 Promotion queue

Items awaiting human decision, ordered by readiness:

| Column | Description |
|---|---|
| PR / artifact | The thing awaiting promotion |
| Gate status | Pass / warn / fail summary from the release gate |
| Reviews | Review approvals present or missing |
| Agent | Which agent produced the work |
| Awaiting since | How long this has been waiting for human action |

The promotion queue makes human merge/promotion authority explicit and visible,
not buried in notification noise.

### 3.4 Conflict / contention view

Available when multiple agents or humans compete for the same resource:

| Column | Description |
|---|---|
| Resource | What is contended (issue, branch, host, publish target) |
| Current holder | Who holds the claim or lease |
| Waiting | Who is queued or blocked |
| Contention type | Duplicate task vs. resource conflict vs. promotion collision |
| Suggested action | Release, takeover, split, or wait |

This view surfaces the coordination failures that the claim/lease protocol
is designed to prevent, so maintainers can intervene when automation cannot
resolve the contention.

---

## 4. Maintainer Interactions

### 4.1 Approve or reject promotion

The primary maintainer action is the same as today: review a PR and merge or
reject it. The promotion surface adds:

- Gate evaluation summary inline with the PR
- Clear indication of which agent produced the work and under what authority
- One-click merge when all gates pass and reviews are complete

No new ceremony is required beyond what maintainers already do.

### 4.2 Ownership visibility

Maintainers can see who currently owns a task/resource without digging through
agent logs:

- Issue sidebar shows current claim holder
- Branch list shows active leases
- PR shows which agent session produced it and which capability profile was used

### 4.3 Stale and conflicting claims

The forge surfaces stale claims proactively:

| Signal | What the maintainer sees |
|---|---|
| Claim with no attempt activity for > threshold | "Issue #42 claimed by Agent X but no progress in 2 hours" |
| Expired lease | "Agent X's access to host:staging expired — release or reassign?" |
| Duplicate claims | "Both Agent X and Agent Y claimed issue #42 — resolve conflict" |
| Superseded attempt | "Agent Y's work supersedes Agent X's earlier attempt" |

Maintainers can release stale claims, approve takeovers, or reassign work
with familiar issue-management gestures (reassign, close, reopen).

### 4.4 Supersession lineage

When an attempt supersedes a prior attempt, the maintainer can see:

- What the prior attempt produced
- Why it was superseded (failed, timed out, manually reassigned, better result)
- Whether any artifacts from the prior attempt were preserved
- The full chain of attempts for a given work item

This lineage is presented as a timeline, not a graph visualization — familiar
to anyone who has used PR conversation history.

---

## 5. Mapping to Familiar Forge Concepts

The activity surface deliberately avoids new UI paradigms:

| Coordination concept | Forge equivalent |
|---|---|
| Claim | Issue assignment |
| Lease | Branch protection / environment lock |
| Attempt | PR or commit series |
| ReviewState | PR review status |
| Promotion gate | Required status check + merge rules |
| Supersession | "Closes #X" / linked PRs |
| Conflict | Merge conflict indicator / competing PRs |

Maintainers who already understand GitHub's model can use the activity surface
without learning new vocabulary. The coordination protocol adds precision and
enforcement underneath, but the surface layer speaks the same language.

---

## 6. Work State Progression

The activity surface clearly distinguishes four work states, matching the
acceptance criteria:

| State | Meaning | Visual indicator |
|---|---|---|
| **Draft / attempt** | Agent is actively working, not yet proposing | Gray / in-progress indicator |
| **Proposed** | PR created, awaiting review | Yellow / review-requested indicator |
| **Reviewed** | Human has approved, gates evaluated | Green / approved indicator |
| **Promoted / published** | Merged to protected branch or published | Blue / merged indicator |

Each transition requires explicit action — either automated (gate pass) or
human (review approval, merge). No state transition is implicit.

---

## 7. Notification Strategy

The activity surface feeds into the existing notification system rather than
creating a parallel one:

| Event | Notification | Channel |
|---|---|---|
| PR ready for review | Standard review request | Existing notification preferences |
| Claim stale | Mention in issue | Issue notification |
| Conflict detected | Comment on affected issue/PR | PR notification |
| Gate failure | Status check failure | Existing CI notification |
| Promotion available | Review request with gate summary | Review notification |

Maintainers do not need to subscribe to a new notification source or monitor
a separate dashboard. The coordination state flows through channels they
already watch.

---

## 8. What the Surface Does NOT Include

To avoid becoming an orchestration console:

- No DAG visualization of agent task dependencies
- No real-time agent log streaming in the main UI
- No agent configuration or profile management in the activity view
- No lease TTL tuning in the maintainer surface
- No compute resource monitoring

These capabilities exist in admin/advanced views for teams that need them,
but they never appear in the default maintainer path.

---

## 9. Relationship to Prior Design

- **Round 117** — established that the maintainer UX should be a "calm
  activity/promotion surface" that maps to familiar forge concepts
- **Claim/lease protocol** — the coordination primitives that this surface
  makes legible
- **Agent capability boundaries (item 90)** — agent identity that appears in
  the ownership and attribution columns
- **Publishing UX (item 88)** — the progressive disclosure model reused here
- **Release gate (item 83)** — gate evaluation results surfaced in the
  promotion queue

# `jj` Virtual Working Copies Contract

**Status:** Drafted from Rounds 48 and 134
**Purpose:** Define the isolated-mutation contract for multi-agent code work so
parallel attempts can proceed without turning file reservations or shared
checkouts into correctness bottlenecks.

---

## 1. Boundary

This note answers a narrow question:

> What execution contract should Vaglio enforce so multiple agents can work on
> overlapping code areas concurrently without unsafe shared writes?

It does **not** require one specific materialization mechanism today.

The contract is about:

- private writable mutation spaces
- explicit merge-back/promotion steps
- conflict collection into governance/stress surfaces
- alignment with claims, attempts, and leases

It is **not** primarily about:

- giant-monorepo VFS materialization
- filesystem optimization as the first answer
- replacing claims/leases with file locks

---

## 2. Maintained architectural line

Rounds 48 and 134 converge on the same principle:

- file reservations are useful as **intent metadata**
- but isolated mutation namespaces are the real correctness boundary

So the maintained posture is:

1. agents should mutate code in private working copies by default
2. merge-back into accepted history is an explicit promotion step
3. reservations, tags, and claims help route/schedule work but do not substitute
   for isolation

This is why the contract is called **virtual working copies** rather than
simply "reservation protocol."

---

## 3. Abstraction, not mechanism

A **virtual working copy** is an isolated writable namespace associated with one
attempt lineage.

Possible implementations:

- `jj` named working copies
- disposable Git worktrees
- `dmux`-managed isolated mutation directories
- future snapshot/subvolume-backed workspaces

The product should care about the contract first:

- one attempt gets one private writable namespace
- the namespace has explicit lineage and scope metadata
- promotion back to shared accepted history is deliberate and reviewable

This keeps the board/runtime model stable even if the underlying workspace
materialization mechanism changes over time.

---

## 4. Core objects

### 4.1 `VirtualWorkingCopy`

Minimum shape:

| Field | Meaning |
|---|---|
| `id` | Stable workspace ID |
| `claim_ref` | Parent claim |
| `attempt_ref` | Attempt currently using the workspace |
| `repo_ref` | Repo anchor |
| `base_change_ref` | Accepted head / base change used to create it |
| `workspace_ref` | Backend-specific workspace handle (`jj` working-copy name, worktree path, etc.) |
| `scope_paths` | Declared or observed path scope |
| `state` | `provisioning`, `active`, `rebasing`, `blocked_conflict`, `ready_for_promotion`, `abandoned`, `merged` |
| `created_at` | Creation time |
| `updated_at` | Last mutation |

### 4.2 `ConflictCollectorEvent`

Minimum shape:

| Field | Meaning |
|---|---|
| `id` | Stable event ID |
| `workspace_ref` | Related virtual working copy |
| `attempt_ref` | Attempt that produced the event |
| `conflict_type` | `textual`, `structural`, `policy`, `silent_invariant`, `rebase_overlap` |
| `object_scope` | Path / subsystem / target object in stress |
| `summary` | Human-readable explanation |
| `evidence_refs` | Logs, diffs, failing checks, linked reports |
| `recorded_at` | Event timestamp |

The conflict collector is append-only evidence, not a hidden runtime side
channel.

---

## 5. Lifecycle

### 5.1 Provision

When the board starts an attempt that needs code mutation:

- create a `VirtualWorkingCopy`
- anchor it to the current accepted base
- attach it to the attempt lineage

The default should be **private writable namespace first**, not "edit in the
shared checkout unless reminded otherwise."

### 5.2 Mutate

While active:

- the agent edits only inside the virtual working copy
- reservations/tags may warn about overlap
- claims/leases govern ownership and shared-resource mutation outside the local
  workspace itself

### 5.3 Rebase / refresh

Before promotion, the attempt should rebase or refresh against current accepted
head.

This is where stale-success risk is surfaced:

- a locally successful attempt may now overlap architecturally with newer
  accepted work
- revalidation must happen on current accepted history, not only on the stale
  base

### 5.4 Promote or arbitrate

If the refreshed workspace remains valid:

- mark it `ready_for_promotion`
- route it through review/promotion gates

If it fails due to substantive overlap:

- record conflict-collector events
- route to arbitration rather than "first success wins"

---

## 6. Reservations are advisory, not correctness locks

Reservations still matter, but only as scheduling/intent hints.

They may answer:

- who expects to touch this subtree
- whether another agent should avoid duplicate work
- whether overlap deserves early coordination

They must **not** be treated as:

- the sole concurrency primitive
- a replacement for isolated mutation spaces
- a reason to mutate shared checkout state directly

This preserves branch-parallelism while reducing accidental thrash.

---

## 7. Conflict collector

The conflict collector exists so conflicts become first-class governance inputs
rather than private agent pain.

### 7.1 Conflict classes

| Class | Meaning |
|---|---|
| `textual` | direct merge/rebase conflict in changed content |
| `structural` | overlapping architectural changes that cannot safely coexist |
| `policy` | overlap with repo constraints, gates, or declared invariants |
| `silent_invariant` | code builds/merges but violates a higher-level invariant |
| `rebase_overlap` | a stale-success candidate discovered only after refresh on accepted head |

### 7.2 Why silent conflicts matter

The system should not treat "merged cleanly" as "compatible."

Some conflicts are silent at the text level but loud at the invariant level:

- tests pass locally on stale base but fail after refresh
- two changes each look valid alone but jointly violate an architectural rule
- one attempt invalidates the rationale or assumptions of another

Those should be surfaced as **structural stress**, not hidden as generic CI
noise.

---

## 8. UI / stress-surface consequence

Virtual working copies are not only a local runtime trick. They feed the board
and stress surfaces.

At minimum, the UI should be able to show:

- active private mutation namespaces by claim/attempt
- overlap or reservation hints by path/subsystem
- conflict-collector events
- stale-success / rebase-overlap warnings
- promotion-ready versus arbitration-bound attempts

This is the intended meaning of the item’s acceptance criterion that conflicts
become visible as **Structural Stress** points.

---

## 9. Relationship to claims and leases

Virtual working copies integrate with the existing control-plane model:

- `Claim`
  - owns the logical task
- `Attempt`
  - owns one concrete execution run
- `VirtualWorkingCopy`
  - owns the private writable mutation namespace for that attempt
- `Lease`
  - only required when the attempt also mutates a contested shared resource
    beyond its private code workspace

Examples:

- editing code in a private workspace:
  - claim required
  - attempt required
  - virtual working copy required
  - no live-resource lease necessarily required
- deploying from the resulting change:
  - claim required
  - attempt required
  - virtual working copy may already exist
  - host/publish lease required

This preserves the important distinction between local code isolation and shared
resource mutation authority.

---

## 10. Current implementation posture

The current local direction after Round 134 remains:

- wrapper-first isolated mutation workspaces
- read-mostly shared checkout
- preflight guardrails
- optional filesystem/snapshot enhancements later

So this note should **not** be read as "pivot to build a VFS layer now."

It is a contract that:

- can be satisfied initially by disposable isolated workspaces
- remains compatible with future `jj` named working-copy maturity
- keeps the board/runtime model stable across those mechanism choices

---

## 11. Recommended implementation sequence

1. make isolated mutation the default for code-changing attempts
2. persist `VirtualWorkingCopy` metadata alongside attempt lineage
3. record conflict-collector events during rebase/refresh and invariant failure
4. surface structural stress on the board/web UI
5. only then experiment with more advanced workspace materialization mechanisms

---

## 12. Final synthesis

The right answer to multi-agent code collision is not stronger file locking and
not a premature VFS bet.

It is:

- private virtual working copies per attempt
- explicit merge-back and refresh on accepted head
- conflict collection as durable governance evidence
- reservations as advisory scheduling hints
- claims and leases kept distinct from local workspace isolation

That is the minimum contract that lets agents work in parallel on overlapping
subtrees without turning shared checkout state into the bottleneck or the
correctness boundary.

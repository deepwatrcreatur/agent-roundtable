# Autonomous Agent Task Queue Contract

**Status:** Drafted from Rounds 62, 70, and 121
**Purpose:** Define the complete shape of the autonomous task-queue layer that
sits between discussion output and durable execution, using the now-landed board,
daemon, workflow, and executor slices as one coherent contract.

---

## 1. Boundary

This note answers a narrow question:

> What does it mean for agent work to proceed autonomously without human
> turn-taking, while still keeping durable lineage, leases, and human gates
> explicit?

The queue layer owns:

- dispatchable work-item state
- attempt lineage
- local or external runtime claiming
- machine-readable retry / timeout / gate policy
- progress/failure event history

It does **not** own:

- long-horizon governance memory
- final release/promotion authority
- broad agent reputation
- hidden interactive operator babysitting

The queue is therefore a bounded execution-control surface, not a freeform
chat-orchestration loop.

---

## 2. Why this exists

The original item correctly identified the pain:

- work should not require human turn-taking between every agent step
- local CLI agents should keep running productively when the operator is not
  manually driving each turn
- failure should be durable and inspectable rather than "stuck in bash"

The project later decomposed that into specific contracts instead of one giant
implementation blob.

This note makes the decomposition explicit.

---

## 3. Canonical queue objects

The autonomous queue now resolves into four main layers:

1. **Board work item**
   - the logical queued task
2. **Attempt lineage**
   - append-only execution history for that task
3. **Daemon / executor runtime**
   - the thing that actually performs the work
4. **Human gate / promotion checkpoint**
   - explicit pause or approval when autonomy should stop

Those layers are distinct on purpose.

---

## 4. Queue semantics

### 4.1 `WorkItem`

The queue’s primary record is the board `work_item`.

It answers:

- what needs to be done
- against which repo/ref/resource scope
- with what policy constraints
- under what contention/lease expectations

This replaces the old vague "Task schema" idea with the concrete board schema
already implemented.

### 4.2 `Attempt`

Autonomy does not mean mutating the same row forever.

Every concrete run is an append-only `Attempt` with:

- start/finish
- runtime identity
- result class
- artifacts/events
- optional supersession

This is what makes retries, rewind, and replay durable instead of ad hoc.

### 4.3 `WorkflowDefinition`

Task policy is data, not hidden runtime behavior.

The queue relies on workflow definitions for:

- retry defaults
- timeout policy
- runtime requirements
- gate behavior
- resume policy

This is the concrete realization of the earlier "Task Watcher" intuition:
autonomy is policy-driven, not hard-coded shell glue.

### 4.4 `Runtime`

Autonomy requires a runtime that can:

- advertise capability
- claim work
- renew leases
- emit progress/failure events
- request structured human input when needed

That is the role of the local daemon contract and, later, controlled executor
providers.

---

## 5. Dispatch model

The queue should operate under a pull/claim model rather than implicit push or
tab babysitting.

### 5.1 Claiming

A compatible idle runtime:

- polls for work
- claims a work item
- receives attempt/job context
- starts execution under lease

### 5.2 Runtime matching

Dispatch should consider:

- required runtime labels/tools
- agent profile availability
- resource contention class
- workflow policy
- branch/workspace access

This is more precise than "assign the next task to an idle local agent."

### 5.3 Autonomy stop conditions

Autonomy should stop when:

- the attempt fails terminally
- a human gate is requested
- a lease expires or is revoked
- the work is superseded
- policy denies continuation

That gives bounded autonomy instead of silent drift.

---

## 6. Rewind and failure semantics

The old item’s "Rewind protocol" is now better expressed as structured attempt
failure plus append-only lineage.

### 6.1 What rewind should mean

Rewind should not mean "erase the failed run."

It should mean:

- classify the failure
- preserve the failed attempt record
- restore runtime/workspace safety as required
- create a new attempt or requeue according to policy

### 6.2 Failure classes

Minimum useful classes include:

- `input_error`
- `tool_error`
- `runtime_disconnect`
- `timeout`
- `policy_denied`
- `lease_revoked`
- `superseded`
- `unknown_error`

These are already encoded in the daemon/executor direction and make the queue
machine-usable.

### 6.3 "Stuck in bash" as a queue smell

The queue contract treats interactive stalls as design bugs, not operator
expected behavior.

The fix is:

- structured event emission
- timeout policy
- explicit human gates
- machine-usable failure classes

not "watch the terminal more closely."

---

## 7. Human gate model

Autonomy is not all-or-nothing.

The queue should support bounded pause points:

- approval needed
- clarification needed
- risk acknowledgment needed
- merge/promotion review needed

This is how the system avoids collapsing either into:

- full manual babysitting
- or unsafe blind automation

---

## 8. Relationship to later implementation slices

The original umbrella is now concretely realized by later items:

| Original queue concern | Concrete landing place |
|---|---|
| Task schema | `73-board-work-item-schema.md` / `BOARD_EXECUTION_MODEL.md` |
| Task watcher / claiming | `74-local-daemon-lease-contract.md` / `LOCAL_DAEMON_CONTRACT.md` |
| Queue policy / retry / timeout | `75-lightweight-workflow-definitions.md` |
| External controlled runner path | `95-buildkite-compatible-controlled-executor.md` |
| Browseable queue/operator surface | `96-board-kanban-read-model.md` and `97-browseable-board-surface.md` |

So item 57 should now be read as the umbrella that was decomposed and then
realized, not as a still-missing monolith.

---

## 9. Current product shape

The maintained queue shape is:

- discussion emits structured directives
- board stores dispatchable work items
- runtimes/daemons claim compatible work
- attempts and events are append-only
- workflow policy drives retry/timeouts/gates
- humans intervene only at explicit checkpoints

That is the concrete answer to "autonomous task delegation" in this project.

---

## 10. Final synthesis

The autonomous task queue is no longer a speculative future subsystem.

Its contract now exists as:

- board work-item schema
- local daemon lease/event contract
- workflow-as-data policy
- controlled executor/provider boundary
- browseable board surface

What remains for future work is iterative refinement of runtime matching,
capability routing, and richer operator flows, not invention of the queue model
from scratch.

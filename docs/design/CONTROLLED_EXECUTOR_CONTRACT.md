# Controlled Executor Contract

**Status:** Drafted from Round 121  
**Purpose:** Define the narrow execution-provider contract that lets the
control plane keep authority over claims, leases, attempts, and promotion while
delegating compute to local runners or Buildkite-like external executors.

---

## 1. Boundary

The control plane should remain authoritative for:

- claims
- leases
- attempt lineage
- scoped credentials
- trust-tier decisions
- promotion and publish authority

The executor should remain responsible for:

- job launch
- sandboxed command execution
- heartbeat / liveness reporting
- log and artifact return
- attestation return

This contract exists to keep orchestration authority separate from execution
runtime.

---

## 2. Why "Buildkite-compatible" matters

The intent is not to clone one provider API exactly.

The intent is to preserve the useful shape of a Buildkite-like worker model:

- the control plane dispatches work
- executors pull or receive runnable jobs
- executors do not define promotion meaning
- job completion returns evidence, not authority

That shape is compatible with:

- local homelab runners
- workstation-bound daemon executors
- future hosted execution pools
- existing CI systems used as controlled workers

---

## 3. Control-plane owned objects

The executor must treat the following as upstream authority, not local state it
may redefine:

- `Claim`
- `Lease`
- `Attempt`
- `ReviewState`
- `PromotionGate`
- `AuthorityScope`
- `DecisionRecord`

The executor may cache or mirror some of this state for performance, but it
must not become the only place where that meaning exists.

---

## 4. Required job envelope

Every runnable job issued to an executor should include a bounded envelope.

Minimum fields:

| Field | Meaning |
|---|---|
| `job_id` | Stable executor job ID |
| `attempt_ref` | Canonical attempt ID |
| `claim_ref` | Canonical claim ID |
| `lease_ref` | Active execution lease |
| `workflow_ref` | Optional workflow policy bundle |
| `repo_ref` | Repo target |
| `revision_hint` | Branch/ref/commit context to materialize |
| `task_type` | `code_change`, `review`, `benchmark`, etc. |
| `input_payload` | Structured task input |
| `credential_bundle_ref` | Short-lived scoped credential handle |
| `artifact_policy` | Upload/retention rules |
| `timeout_policy` | Soft/hard timeout expectations |
| `attestation_policy` | Required attestation shape |
| `return_contract` | Expected terminal outputs |

The job envelope is what makes an executor replaceable without moving
governance meaning into provider YAML.

---

## 5. Required executor operations

The controlled executor contract should expose a small set of semantic
operations.

| Operation | Purpose |
|---|---|
| `accept_job` | Confirm the executor accepted a specific lease-backed job |
| `start_job` | Report actual execution start |
| `heartbeat_job` | Renew liveness and carry progress metadata |
| `append_job_log` | Stream structured log/progress slices |
| `append_job_artifact` | Register output bundles, patches, reports, or test logs |
| `return_attestation` | Return execution attestation/evidence summary |
| `request_gate` | Ask the control plane for structured human or policy input |
| `finish_job` | Report terminal success with outputs |
| `fail_job` | Report terminal failure with machine-usable class |
| `abort_job` | Acknowledge cancellation or lease revocation |

The exact transport can vary. The semantic boundary should not.

---

## 6. Lease and authority semantics

### 6.1 Job execution requires a live lease

Executors must treat `lease_ref` as a hard precondition for mutation work.

If the lease:

- expires
- is revoked
- is superseded
- loses required authority scope

then the executor must stop mutating and report the interruption.

### 6.2 Executors do not mint authority

Executors must not be able to:

- promote a release
- publish an artifact
- mark trust-tier transitions as authoritative
- override a supersession decision
- approve their own human gate

They may request those actions; they do not own their meaning.

---

## 7. Credential model

The executor should receive short-lived, scope-bounded credentials rather than
ambient long-lived secrets.

Minimum principles:

- credentials are issued per job or attempt
- credentials are tied to claim/lease context
- publish-capable credentials are separate from read/build credentials
- credentials are revocable when a lease is superseded or cancelled

This allows existing CI providers to execute useful work without inheriting
full release authority.

---

## 8. Artifact and attestation return

Executors should return evidence, not only a pass/fail bit.

Minimum return classes:

- structured logs
- patch / diff bundle
- test and benchmark outputs
- artifact references
- execution attestation
- compact terminal summary

The control plane should decide how that evidence affects:

- trust tier
- review surface
- promotion gates
- publish readiness

---

## 9. Failure model

Executors must return structured failure classes that the control plane can use
for retry and governance semantics.

Minimum classes:

| Failure class | Meaning |
|---|---|
| `input_error` | Job envelope invalid or missing required context |
| `executor_error` | Runner or wrapper failure |
| `runtime_disconnect` | Lost worker during execution |
| `timeout` | Soft/hard timeout exceeded |
| `policy_denied` | Scope or credential rule prevented action |
| `lease_revoked` | Live authority was withdrawn |
| `superseded` | Newer attempt invalidated current run |
| `unknown_error` | Failure could not be classified |

These are executor reports. The control plane remains responsible for deciding
whether retry, cancellation, or human review follows.

---

## 10. Human and policy gates

Executors must support a structured pause model rather than open-ended
interactive drift.

Typical reasons:

- missing clarification
- risky write boundary
- promotion boundary reached
- conflicting branch or artifact state
- unavailable credential scope

The executor may request a gate and pause. It must not silently keep going past
a boundary that belongs to a human or the control plane.

---

## 11. Compatibility tiers

The contract should support three practical executor classes.

### 11.1 Local daemon executor

- strongest fit for subscription-backed CLI agents
- direct lease renewal
- rich local tool access

### 11.2 Buildkite-like external worker

- remote worker or agent accepts a lease-backed job
- host control plane still owns claim/attempt/promotion meaning
- useful for fast adoption in existing CI ecosystems

### 11.3 Future hosted execution provider

- managed pool under the same contract
- may offer richer telemetry or autoscaling
- still subordinate to control-plane authority

---

## 12. Graceful degradation

When advanced executor features are absent, the contract should degrade without
losing governance meaning.

| Missing feature | Required fallback |
|---|---|
| live log streaming | upload logs at checkpoints or terminal state |
| attestation richness | return minimal verifiable completion metadata |
| interactive gate callback | pause and wait for poll-based resume |
| artifact push channel | return artifact manifest with retrievable locations |

What must not degrade:

- lease enforcement
- attempt lineage
- authority boundaries
- promotion meaning

---

## 13. Relationship to adjacent contracts

This contract sits between:

- `BOARD_EXECUTION_MODEL.md`
- `LOCAL_DAEMON_CONTRACT.md`
- backend/provider integration contracts

The board defines the durable execution state model.
The daemon contract defines one local runtime implementation path.
This controlled executor contract defines the portable execution-provider edge
that lets either a local daemon or a Buildkite-like worker plug in without
becoming sovereign.

---

## 14. Non-goals

This contract does not attempt to:

- reimplement a generic workflow engine
- standardize every CI vendor API
- move publish authority into the executor
- collapse the control plane into job YAML

Its job is narrower:

- define the first portable executor boundary
- keep execution providers replaceable
- preserve control-plane authority above runtime choice

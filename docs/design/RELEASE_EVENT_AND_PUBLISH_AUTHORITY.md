# Release Event and Publish Authority Separation

**Status:** Drafted from Round 99
**Purpose:** Separate build execution, publish authority, and final release
promotion so a compromised CI job cannot implicitly publish as the trusted
project identity.

---

## 1. Problem

In the current GitHub/npm model, the same automation surface that evaluates a
change also implicitly inherits publish authority. A compromised CI workflow can
produce cryptographically valid, signed artifacts that are malicious — because
provenance records build identity, not approval or promotion context.

The Mini Shai-Hulud analysis (Round 99) showed this is not a hypothetical:
provenance-as-build-identity is necessary but not sufficient.

---

## 2. Three Distinct Primitives

The host must treat build, publish, and promotion as three separate things:

| Primitive | What it is | Who controls it |
|---|---|---|
| **Build execution** | Running CI jobs, tests, analysis | Workflow definition + trigger rules |
| **Publish authority** | Permission to push artifacts to a registry | Host-brokered, short-lived credentials |
| **Release promotion** | Decision that a build result becomes a named release | Explicit approval chain + gate evaluation |

### 2.1 Build execution

- Build jobs run in ephemeral, trust-tiered execution contexts (see item 86)
- Build success is evidence, not authority
- A passing build does not imply release eligibility

### 2.2 Publish authority

- Publish credentials are never available to ordinary build execution
- The host brokers short-lived, narrowly-scoped publish tokens only after:
  - a release event is explicitly created
  - the release gate passes (see release gate design note)
  - the approval chain is satisfied
- Publish tokens are scoped to:
  - specific package names
  - specific registries
  - specific version ranges
  - a time window

### 2.3 Release promotion

- A release is a first-class host object, not a side effect of a tag push or
  workflow completion
- Release creation requires an explicit promotion action by an authorized
  identity
- The release object records:
  - the reviewed change(s) it packages
  - the build artifacts it includes
  - the approval chain that authorized it
  - the gate evaluation result
  - the publish manifest (what goes where)

---

## 3. Release Event Structure

| Field | Type | Description |
|---|---|---|
| `release_id` | string | Host-assigned unique identifier |
| `repo` | string | Repository identity |
| `version` | string | Semantic version or release tag |
| `revision` | string | Git revision being released |
| `change_ids` | string[] | Reviewed change identities included |
| `build_artifacts` | object[] | Build outputs with content hashes |
| `gate_result` | object | Analysis gate evaluation summary |
| `approval_chain` | object[] | Ordered list of approvals |
| `publish_manifest` | object[] | Target registries and package names |
| `promoted_by` | string | Identity that triggered promotion |
| `promoted_at` | timestamp | When promotion occurred |

---

## 4. Approval Chain

A release approval chain records who approved what and in what capacity:

| Field | Type | Description |
|---|---|---|
| `approver` | string | Identity |
| `role` | enum | `code_reviewer`, `release_manager`, `security_reviewer` |
| `approved_at` | timestamp | When approval was granted |
| `scope` | string | What was approved (e.g. "code changes", "security findings") |

The host enforces minimum approval requirements per repo policy:

```yaml
release_policy:
  required_approvals:
    - role: code_reviewer
      count: 1
    - role: release_manager
      count: 1
  # Optional: require security review for releases with waived findings
  conditional_approvals:
    - condition: has_waived_findings
      role: security_reviewer
      count: 1
```

---

## 5. Provenance Enhancement

Release provenance must include approval and promotion context in addition to
build identity:

| Provenance layer | What it records |
|---|---|
| Build provenance | Builder identity, inputs, outputs, environment (SLSA v1.0) |
| Review provenance | Who reviewed what, when, with what verdict |
| Gate provenance | Which analysis findings existed, how they were resolved |
| Approval provenance | The approval chain with roles and timestamps |
| Promotion provenance | Who promoted, when, and the publish manifest |

This layered provenance allows downstream consumers to verify not just "was this
built correctly?" but "was this reviewed, gated, approved, and intentionally
released?"

---

## 6. jj Lineage Contribution

Immutable `jj` change identities strengthen release binding:

- each release pins to specific reviewed change IDs, not just a mutable branch tip
- lineage provides precise rollback targets when a release is later revoked
- change-level provenance survives rebase, unlike commit-level provenance

---

## 7. Relationship to Prior Design

- **Round 99** — established the three-way separation
- **Release gate (item 83)** — the gate evaluation that feeds into release decisions
- **Trust tiers (item 86)** — build execution trust context
- **SLSA attestation (item 61)** — build-layer provenance
- **Quarantine/revocation (item 85)** — what happens when a released artifact
  is later found to be compromised

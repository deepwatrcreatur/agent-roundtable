# Hosted Analysis Provider Contract

**Status:** Drafted from Round 98
**Purpose:** Define the host-owned contract by which first-party, self-hosted,
and third-party analysis engines submit findings, experiments, and verdicts
into the forge's canonical memory and review surface.

---

## 1. Boundary

The **host** owns:

- canonical finding storage and lineage
- reviewer UX and decision records
- release-gate policy enforcement
- waiver / exception provenance
- evidence schema normalization

The **provider** owns:

- analysis execution (scheduling, compute, tooling)
- domain-specific detection methodology
- experiment and reproducer design
- confidence calibration for its own output

This contract exists so the host can ingest evidence from any provider class
without granting providers authority over the canonical truth surface.

---

## 2. Provider Classes

| Class | Description | Trust model |
|---|---|---|
| First-party hosted | Analysis engines operated by the forge itself | Highest implicit trust; still subject to the same evidence schema |
| Self-hosted | Customer-operated engines running against their own repos | Identity established via forge-issued tokens; evidence treated as external |
| Third-party marketplace | External specialist providers (e.g. UB-hunting, license compliance) | Identity via registered provider credentials; evidence normalized on ingest |

All three classes emit the same normalized artifact schema. Trust differences
affect **policy weight**, not schema shape.

---

## 3. Normalized Finding Schema

Every provider submission must include the following normalized artifact:

### 3.1 Required fields

| Field | Type | Description |
|---|---|---|
| `finding_id` | string | Provider-assigned unique identifier |
| `provider_id` | string | Registered provider identity |
| `repo` | string | Repository identifier (owner/name or forge-native ID) |
| `revision` | string | Git revision (commit SHA) the finding applies to |
| `path_scope` | string[] | File paths or glob patterns bounding the finding |
| `category` | string | Finding category from the host taxonomy (see 3.3) |
| `severity` | enum | `critical`, `high`, `medium`, `low`, `informational` |
| `confidence` | float | Provider's self-assessed confidence (0.0 - 1.0) |
| `title` | string | One-line human-readable summary |
| `description` | string | Detailed finding description |
| `evidence` | object | Structured evidence payload (see 3.2) |

### 3.2 Evidence payload

The `evidence` object must contain at least:

| Field | Type | Description |
|---|---|---|
| `tool` | string | Tool or engine that produced the finding |
| `tool_version` | string | Exact version of the tool |
| `runtime_config` | object | Configuration used for this analysis run |
| `raw_output` | string? | Optional raw tool output for audit replay |
| `reproducer` | object? | Optional reproducer metadata (see 3.4) |

### 3.3 Host taxonomy

The host defines and maintains the canonical finding taxonomy. Providers map
their native categories into the host taxonomy on submission. The host may
reject or quarantine findings with unmapped categories.

Initial taxonomy roots:

- `unsafe-code` — direct use of unsafe constructs
- `undefined-behavior` — potential UB regardless of unsafe markers
- `memory-safety` — memory corruption, use-after-free, buffer overflow
- `supply-chain` — dependency integrity, provenance, tampering
- `license-compliance` — license compatibility and attribution
- `secret-exposure` — credentials, keys, tokens in source
- `configuration` — misconfigurations with security impact
- `custom` — provider-defined categories (require host registration)

### 3.4 Reproducer metadata

When a finding includes a reproducer:

| Field | Type | Description |
|---|---|---|
| `reproducer_type` | enum | `test_case`, `script`, `miri_invocation`, `fuzzer_input`, `manual_steps` |
| `entrypoint` | string | Command or path to run the reproducer |
| `expected_outcome` | string | What the reproducer demonstrates |
| `environment` | object | Required runtime environment (toolchain, OS, deps) |

---

## 4. Supplementary Artifact Types

Beyond findings, providers may submit:

### 4.1 Experiment records

| Field | Type | Description |
|---|---|---|
| `experiment_id` | string | Provider-assigned unique identifier |
| `finding_ids` | string[] | Findings this experiment investigates |
| `method` | string | Description of the experimental method |
| `outcome` | enum | `confirmed`, `refuted`, `inconclusive`, `partial` |
| `evidence` | object | Same evidence schema as findings |

### 4.2 Remediation proposals

| Field | Type | Description |
|---|---|---|
| `proposal_id` | string | Provider-assigned unique identifier |
| `finding_ids` | string[] | Findings this proposal addresses |
| `approach` | string | Description of the proposed fix |
| `patch` | string? | Optional unified diff |
| `verification` | object? | How the fix was verified (test results, re-analysis) |

### 4.3 Verification outcomes

| Field | Type | Description |
|---|---|---|
| `verification_id` | string | Provider-assigned unique identifier |
| `target_type` | enum | `finding`, `remediation`, `experiment` |
| `target_id` | string | ID of the artifact being verified |
| `result` | enum | `verified`, `failed`, `partial`, `superseded` |
| `evidence` | object | Same evidence schema as findings |

---

## 5. Provider Identity and Provenance

### 5.1 Provider registration

Every provider must be registered with the host before submitting findings.
Registration establishes:

- provider identity and credentials
- permitted analysis categories
- permitted target repositories
- submission rate limits
- provenance expectations

### 5.2 Submission provenance

Every submission must include:

| Field | Type | Description |
|---|---|---|
| `submitted_at` | timestamp | ISO 8601 submission time |
| `provider_id` | string | Registered provider identity |
| `provider_signature` | string? | Optional cryptographic signature over the payload |
| `attestation` | object? | Optional SLSA-style attestation (see 5.3) |

### 5.3 Attestation expectations

For providers at the `attested` trust tier:

- submissions must include a signed attestation linking the finding to:
  - the specific tool invocation that produced it
  - the exact revision analyzed
  - the runtime environment
- the attestation format should align with SLSA provenance v1.0 where possible
- the host verifies attestation signatures but does not trust attestation
  content as ground truth (it is evidence, not verdict)

### 5.4 Replay expectations

Providers should include enough metadata for the host or a third party to
**replay** the analysis:

- tool identity and version
- configuration used
- input revision
- environment requirements

The host does not guarantee replay, but missing replay metadata reduces the
provider's effective trust weight in policy decisions.

---

## 6. Attachment Model

Provider results attach to the forge's canonical object graph at these points:

| Attachment point | How |
|---|---|
| Repository | `repo` field — findings are always scoped to a repo |
| Revision | `revision` field — findings pin to a specific commit |
| Branch / PR | Host-side enrichment — the host links revision to active branches or PRs |
| Path scope | `path_scope` field — narrows the finding to specific files |
| Prior findings | `related_finding_ids` field — explicit cross-reference |
| Waivers / suppressions | Host-side — the host manages waiver records, not the provider |
| Later outcomes | Host-side — the host links findings to subsequent incidents or regressions |

Providers submit **evidence**. The host manages **context, decisions, and
memory**.

---

## 7. Ingestion Pipeline

### 7.1 Submission

Providers submit findings via the host API. The host:

1. Validates the submission schema
2. Verifies provider identity and permissions
3. Normalizes category mappings against the host taxonomy
4. Checks for duplicate or superseded findings
5. Stores the normalized artifact in canonical memory
6. Links the finding to the relevant revision, branch, and path context
7. Triggers any policy evaluations or gate checks

### 7.2 Rejection

The host may reject submissions for:

- invalid schema
- unregistered provider
- unmapped categories (unless `custom` is permitted)
- exceeded rate limits
- revisions not present in the target repo

Rejected submissions receive a structured error response with the rejection
reason.

### 7.3 Quarantine

Findings that pass schema validation but have provenance or trust concerns
are quarantined rather than rejected:

- missing attestation from an attested-tier provider
- anomalously high submission volume
- findings on revisions not yet merged to a protected branch

Quarantined findings are visible to repo maintainers but do not trigger
automated policy gates until reviewed.

---

## 8. What This Contract Does Not Cover

- **Release-gate policy** — covered in the companion release-gate design note
- **Provider marketplace economics** — pricing, billing, competition rules
- **Specific tool integrations** — Miri, Clippy, Semgrep, etc. are implementation
  details behind this contract
- **Host-side reviewer UX** — how findings are presented to humans

---

## 9. Relationship to Prior Design

- **Round 98** — established that the host owns the control plane and providers
  contribute evidence, not authority
- **Round 71/76/77** — established that repo skills are narrow adapters, not
  full analysis engines
- **SLSA provenance** — attestation expectations align with SLSA v1.0 where
  possible
- **Sourcegraph integration (Round 90)** — lineage-aware memory enriches
  provider findings with cross-repo context

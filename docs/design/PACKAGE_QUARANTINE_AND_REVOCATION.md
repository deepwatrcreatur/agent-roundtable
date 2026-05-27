# Package Quarantine and Revocation Graph

**Status:** Drafted from Round 99
**Purpose:** Design the host-and-ecosystem coordination layer for rapidly
quarantining, revoking, and tracing malicious package releases once a trusted
pipeline or publisher has been compromised.

---

## 1. Dual-Layer Responsibility

Round 99 established that both the host and the package ecosystem have mandatory
roles in containment. Neither layer alone is sufficient:

| Layer | Responsibility |
|---|---|
| **Host (forge)** | Detect suspicious releases, quarantine at source, provide lineage and blast-radius data |
| **Ecosystem (registries, package managers)** | Act on quarantine signals, propagate revocations, protect downstream consumers |

---

## 2. Quarantine Model

### 2.1 Quarantine triggers

The host may quarantine a release when:

- a publisher credential is known or suspected compromised
- a release gate was bypassed or retroactively found deficient
- a downstream incident is traced back to the release
- automated analysis flags anomalous release content
- a maintainer or security team requests quarantine

### 2.2 Quarantine states

| State | Meaning | Visibility |
|---|---|---|
| `active` | Normal release, no concerns | Fully visible and installable |
| `quarantined` | Under investigation, not yet confirmed malicious | Visible with warning; new installs blocked by default |
| `revoked` | Confirmed malicious or critically compromised | Visible for forensic/audit purposes only; all installs blocked |
| `superseded` | Replaced by a clean release | Visible with pointer to replacement; new installs redirected |

### 2.3 Quarantine record

| Field | Type | Description |
|---|---|---|
| `quarantine_id` | string | Host-assigned unique identifier |
| `release_id` | string | The release being quarantined |
| `reason` | string | Why quarantine was initiated |
| `initiated_by` | string | Identity that triggered quarantine |
| `initiated_at` | timestamp | When quarantine began |
| `state` | enum | Current quarantine state |
| `evidence` | object[] | Supporting evidence chain |

---

## 3. Revocation Graph

### 3.1 Graph structure

The revocation graph links:

```
compromised_credential
  → affected_releases[]
    → affected_packages[]
      → downstream_dependents[]
        → affected_environments[]
```

Each node in the graph carries:

- the revocation/quarantine record
- timestamps for when the compromise window opened and closed
- the specific versions affected
- whether a clean replacement exists

### 3.2 Blast-radius mapping

The host provides blast-radius views:

| View | What it shows |
|---|---|
| **Publisher blast radius** | All releases from a compromised publisher within the compromise window |
| **Package blast radius** | All downstream packages that depend on affected versions |
| **Temporal blast radius** | Timeline of when affected versions were available and how many installs occurred |
| **Environment blast radius** | Known deployment environments consuming affected packages (opt-in telemetry) |

### 3.3 jj lineage contribution

Immutable `jj` change identities improve blast-radius precision:

- exact change-level rollback targets, not just "revert to previous tag"
- lineage shows whether a revoked release's changes were cherry-picked elsewhere
- change evolution history helps identify whether the compromised content was
  introduced intentionally or as a side effect

---

## 4. Downstream Notification

### 4.1 Notification channels

The host publishes quarantine and revocation events through:

| Channel | Audience | Latency |
|---|---|---|
| Webhook | Registry operators, CI systems | Real-time |
| API | Package managers, security scanners | Polling or streaming |
| Advisory feed | Human maintainers, security teams | Near real-time |
| Registry integration | npm, crates.io, PyPI, etc. | Depends on registry cooperation |

### 4.2 Notification payload

| Field | Type | Description |
|---|---|---|
| `event_type` | enum | `quarantined`, `revoked`, `superseded`, `cleared` |
| `release_id` | string | Affected release |
| `package` | string | Package name |
| `affected_versions` | string[] | Version ranges affected |
| `replacement` | object? | Clean replacement release if available |
| `advisory_url` | string | Link to full advisory with blast-radius data |

---

## 5. Rollback Guidance

When a release is quarantined or revoked, the host provides:

- **Safe rollback target** — the last known-good version before the compromise
  window
- **Replacement release** — if a clean release has been published
- **Pinning guidance** — recommended lockfile or version constraint changes
- **Verification steps** — how to confirm a local environment is not affected

---

## 6. Forensic Preservation

Quarantined and revoked releases are **not deleted**. They are:

- marked as quarantined/revoked in all metadata
- blocked from new installations
- preserved in storage for forensic and audit purposes
- linked to the incident record and evidence chain

Hard deletion is a separate, higher-authority action that requires:

- explicit legal or compliance justification
- dual authorization
- a durable record that the deletion occurred and why

---

## 7. Registry Cooperation Model

The host cannot unilaterally control third-party registries, but can:

- publish machine-readable quarantine/revocation feeds
- participate in shared advisory databases (e.g. OSV, GHSA)
- provide signed attestations of quarantine decisions
- offer API endpoints for registries to verify release status

The design assumes cooperative registries, not authoritative control over them.

---

## 8. Relationship to Prior Design

- **Round 99** — established the dual-layer responsibility model
- **Release event (item 84)** — the release primitive being quarantined
- **Release gate (item 83)** — the gate that should have caught the issue
- **Trust tiers (item 86)** — how the compromise entered the trusted path
- **Provider contract (item 82)** — analysis providers that may detect the issue

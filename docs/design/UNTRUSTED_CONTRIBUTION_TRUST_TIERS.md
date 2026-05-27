# Untrusted Contribution Trust Tiers

**Status:** Drafted from Round 100
**Purpose:** Define the trust-tier model for execution contexts so untrusted
contributions cannot casually cross into protected caches, secrets, trusted
runners, or publish-capable release contexts.

---

## 1. Principle

**Zero secrets, zero privileged tokens, zero publish capability, and no parent
cache access for untrusted contribution paths.**

Trust transitions must be explicit, visible promotion events with a policy
decision — not implicit consequences of a job completing.

---

## 2. Trust Tiers

| Tier | Name | Description |
|---|---|---|
| 0 | **Untrusted** | External contributions (fork PRs, first-time contributors) |
| 1 | **Reviewed** | Contributions approved by a maintainer but not release-eligible |
| 2 | **Protected** | Merged to a protected branch; eligible for release preparation |
| 3 | **Release** | Explicitly promoted to release context with publish authority |

### 2.1 Tier 0 — Untrusted

Execution context for fork-originated PRs and unapproved contributions.

| Resource | Access |
|---|---|
| Parent/project secrets | None |
| OIDC / workload identity | None (or untrusted-scoped only) |
| Caches | Isolated; no read from or write to higher-tier caches |
| Runners | Ephemeral, unprivileged; no long-lived or trusted runners |
| Protected environments | None |
| Registries | Read-only public access only |
| Publish authority | None |

### 2.2 Tier 1 — Reviewed

Execution context after maintainer approval but before merge to a protected
branch.

| Resource | Access |
|---|---|
| Secrets | Limited CI secrets (test credentials, not publish tokens) |
| OIDC / workload identity | CI-scoped identity (not release-scoped) |
| Caches | Branch-scoped read/write; no write to protected-branch caches |
| Runners | Standard CI runners |
| Protected environments | None |
| Registries | Read-only |
| Publish authority | None |

### 2.3 Tier 2 — Protected

Execution context on protected branches (main, release/*).

| Resource | Access |
|---|---|
| Secrets | Full CI secrets; no publish tokens |
| OIDC / workload identity | Protected-branch-scoped identity |
| Caches | Protected-branch-scoped read/write |
| Runners | Standard or trusted CI runners |
| Protected environments | Staging, pre-production |
| Registries | Read-only |
| Publish authority | None (requires explicit promotion to Tier 3) |

### 2.4 Tier 3 — Release

Execution context for publishing artifacts to registries.

| Resource | Access |
|---|---|
| Secrets | Publish tokens (short-lived, host-brokered) |
| OIDC / workload identity | Release-scoped identity |
| Caches | Inherited from Tier 2 (read-only in release context) |
| Runners | Trusted, audited release runners |
| Protected environments | Production registries |
| Registries | Write access (scoped to specific packages and versions) |
| Publish authority | Yes — host-brokered, time-limited |

---

## 3. Tier Transitions

### 3.1 Transition rules

| From | To | Required |
|---|---|---|
| Tier 0 → Tier 1 | Maintainer approval of the contribution |
| Tier 1 → Tier 2 | Merge to a protected branch (requires passing CI + review) |
| Tier 2 → Tier 3 | Explicit release promotion event (see item 84) |

### 3.2 Transition properties

- Each transition is an **explicit, auditable event**, not an implicit side effect
- Transitions are **one-way within a workflow run** — a job cannot escalate its
  own tier
- The host records the transition with:
  - who authorized it
  - when
  - what policy was evaluated
  - what gate results existed at the time

### 3.3 What transitions are NOT

- A passing CI job does not promote Tier 0 to Tier 1
- Merging does not promote Tier 2 to Tier 3
- A tag push does not imply release authority
- Workflow success is evidence, not authorization

---

## 4. Default Posture

The host default is **deny-by-default at every tier boundary**:

- new repos start with Tier 0/1/2 only (no Tier 3 until explicitly configured)
- fork PRs start at Tier 0 with no exceptions
- secrets are never available at Tier 0, even if the workflow YAML requests them
- cache isolation between tiers is enforced, not advisory

Teams that want broader sharing must explicitly opt in (see item 87 for cache
specifics).

---

## 5. Relationship to Prior Design

- **Round 100** — established that the structural lesson is trust-transition
  architecture, not provider brand choice
- **Release event (item 84)** — the Tier 2 → Tier 3 promotion mechanism
- **Cache boundaries (item 87)** — cache isolation as a per-tier default
- **Release gate (item 83)** — gate evaluation feeds Tier 2 → Tier 3 decisions
- **Publishing UX (item 88)** — making tiers invisible to ordinary developers

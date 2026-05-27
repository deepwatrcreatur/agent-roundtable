# Zero-Config Trusted Publishing UX

**Status:** Drafted from Round 102
**Purpose:** Design the smallest possible trusted-publishing workflow so
ordinary maintainers get the benefits of release-authority separation without
learning a large new security surface.

---

## 1. Principle

**Mandatory in architecture, optional in day-one operator complexity.**

The security properties described in items 82-87 (trust tiers, cache isolation,
release gates, publish authority separation) must be structurally present. But
the user-facing complexity must scale with the project, not with the security
model.

Round 102 used npm's recent security tightening backlash as evidence: security
retrofits experienced as migration toil, token churn, or unfamiliar ceremony
are interpreted as friction even when the threat model is correct.

---

## 2. Progressive Disclosure Model

| Project stage | What the maintainer sees | What the host manages silently |
|---|---|---|
| **Solo maintainer, first package** | "Push a tag → package appears in the registry" | Trust tiers, ephemeral publish tokens, basic analysis gate, cache isolation |
| **Small team** | "Merge to main → release draft appears → click publish" | Approval chain (single required reviewer), gate evaluation, scoped credentials |
| **Growing team** | Configurable policy: who can publish, required reviews, analysis thresholds | Full tier model, branch-specific rules, waiver flows |
| **Large org** | Full policy surface: custom gates, provider marketplace, audit requirements | Everything explicit and auditable |

### 2.1 Day-one experience

For a solo maintainer publishing their first package:

1. **Connect repo to registry** — one-time setup, no token management
2. **Push a tag** (or click "create release" in the UI)
3. **Package appears in the registry**

Behind the scenes, the host:

- creates a release event
- evaluates the default analysis gate (block only critical/secret-exposure)
- brokers a short-lived, narrowly-scoped publish token
- publishes on behalf of the maintainer
- records full provenance

The maintainer never sees a publish token, never writes policy YAML, and
never learns what a trust tier is.

### 2.2 Growing into complexity

When a project needs more:

- **Add a required reviewer:** one config line, not a new workflow architecture
- **Tighten the gate:** change `blocking_severity` from `critical` to `high`
- **Enable a marketplace analyzer:** toggle a provider in the UI
- **Add branch-specific rules:** add a `branch_rules` section

Each step is incremental. No step requires understanding the full model.

---

## 3. What the Host Manages Automatically

| Concern | Host default | User action required |
|---|---|---|
| Publish tokens | Short-lived, host-brokered | None |
| Trust tiers | Enforced by default | None (until custom policy is needed) |
| Cache isolation | Branch-scoped by default | None |
| Analysis gate | Critical + secret-exposure blocking | None |
| Release provenance | Recorded automatically | None |
| Fork PR isolation | Tier 0 by default | None |

### 3.1 No token management

The host never exposes long-lived publish tokens to users. All publish
credentials are:

- host-brokered
- short-lived (minutes, not months)
- scoped to specific packages and versions
- revocable instantly

This eliminates the single largest DX pain point in npm's security model.

### 3.2 No workflow YAML security

Users never write trust-tier logic in workflow definitions. The host enforces
tiers based on:

- PR origin (fork vs. same-repo)
- branch protection status
- explicit release promotion events

Workflow YAML is for build logic, not security policy.

---

## 4. Migration Path

For projects currently using GitHub Actions + npm publish tokens:

### 4.1 Day-one import

- Import the repo
- The host infers a default release workflow from existing tag/release patterns
- Existing CI workflows continue to run for build/test
- Publish authority moves to the host (old tokens can be revoked)

### 4.2 Gradual adoption

- Start with host-managed publish (tag → release → publish)
- Add analysis providers when ready
- Tighten policy incrementally
- Never require a full re-architecture before shipping

### 4.3 What is NOT required on day one

- Understanding trust tiers
- Writing cache policy
- Configuring analysis gates
- Managing provider integrations
- Learning a new release workflow

---

## 5. Escape Hatches

For advanced users who need full control:

- **Custom release workflows** — define multi-step approval chains
- **Manual publish tokens** — available but discouraged, with warnings
- **Custom gate policy** — full YAML policy surface
- **Provider configuration** — per-provider trust weighting and scope
- **Cache sharing overrides** — explicit opt-in with audit trail

Escape hatches are always available but never required.

---

## 6. Anti-Patterns to Avoid

Based on npm's experience (Round 102):

| Anti-pattern | Why it fails |
|---|---|
| Requiring MFA setup before first publish | Blocks adoption at the moment of highest motivation |
| Mandatory token rotation schedules | Creates churn without proportional security benefit for small projects |
| Policy-before-publish | Requiring policy configuration before the first release ships |
| Enterprise ceremony for solo maintainers | Treating all projects as enterprise-scale security targets |
| Fragmented knob surfaces | Multiple independent settings that must be coordinated correctly |

---

## 7. Relationship to Prior Design

- **Round 102** — established that the forge must never require understanding
  trust tiers before shipping a first package
- **Trust tiers (item 86)** — the tier model that this UX hides from simple cases
- **Release event (item 84)** — the release primitive that this UX simplifies
- **Release gate (item 83)** — the gate that runs silently for simple projects
- **Cache boundaries (item 87)** — cache policy that is invisible by default

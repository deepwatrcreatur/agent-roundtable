# Agent Capability and Promotion Boundaries

**Status:** Drafted from Round 117
**Purpose:** Define the host-native authority model for coding agents so agent
identities are scoped, auditable, and unable to casually cross from ordinary
code work into publish-capable or high-sensitivity operations.

---

## 1. Principle

**Agent authority must be scoped, short-lived, and structurally unable to
self-escalate.**

An agent working on a bug fix should not hold — and should not be able to
acquire — publish tokens, deployment credentials, or promotion authority. The
forge enforces this structurally, not by trusting agents to self-limit.

Round 117 converged on the line that agents need forge-native identity and
capability profiles so that blast radius is bounded by design, not by hope.

---

## 2. Agent Identity

### 2.1 Identity model

Each agent session receives a forge-issued identity that is:

| Property | Description |
|---|---|
| **Scoped** | Bound to a specific repo, org, or project — not a global token |
| **Attributed** | Linked to the human or automation that authorized the session |
| **Short-lived** | Expires with the session or a bounded TTL, not months-long |
| **Auditable** | All actions taken under the identity are recorded in attempt lineage |

### 2.2 Identity fields

| Field | Description |
|---|---|
| `agent_id` | Forge-assigned session identity |
| `owning_user` | Human or service account that authorized this agent |
| `owning_org` | Org context (determines available repos and resources) |
| `session_created_at` | When the identity was issued |
| `session_expires_at` | Hard expiry (not renewable beyond a maximum window) |
| `capability_profile_ref` | Which capability profile governs this session |

### 2.3 What agent identity is NOT

- It is not a long-lived API token
- It is not a personal access token shared across agents
- It is not an implicit consequence of running in a CI environment
- It is not inherited from the user's full account permissions

---

## 3. Capability Profiles

A capability profile defines what an agent session is permitted to do. Profiles
are defined at the repo or org level and assigned at session creation.

### 3.1 Authority classes

The forge distinguishes three authority classes, ordered by sensitivity:

| Class | Description | Examples |
|---|---|---|
| **Code mutation** | Create branches, write code, push commits | Bug fixes, feature work, refactoring |
| **Review / propose** | Create PRs, request reviews, update review state | Proposing changes for human review |
| **Promotion / publish** | Merge to protected branches, trigger releases, publish artifacts | Release management, deployment |

These classes are **not automatically composable**. An agent with code mutation
authority does not implicitly gain review or promotion authority.

### 3.2 Capability profile fields

| Field | Description |
|---|---|
| `profile_id` | Stable profile identifier |
| `name` | Human-readable name (e.g., "contributor", "reviewer", "release-agent") |
| `authority_classes` | Which authority classes are granted |
| `repo_scope` | Which repos this profile applies to (`*`, specific repos, or patterns) |
| `path_scope` | Optional path restrictions within repos |
| `resource_scope` | Which shared resources (leases) the agent may acquire |
| `max_session_ttl` | Maximum session duration |
| `requires_human_approval` | Whether actions require human co-approval |

### 3.3 Default profiles

The forge ships sensible defaults:

| Profile | Authority | Typical use |
|---|---|---|
| `contributor` | Code mutation only | Most agent coding work |
| `reviewer` | Code mutation + review/propose | Agents that can create and update PRs |
| `release-agent` | Code mutation + review + promotion | Trusted release automation (rare, tightly scoped) |

New agent sessions default to `contributor` unless explicitly configured
otherwise. This means agents can write code but cannot merge, publish, or
promote without explicit grant.

---

## 4. Authority Separation

### 4.1 Structural enforcement

The forge enforces authority boundaries at the API level, not as advisory
policy:

- An agent with `contributor` profile cannot call merge or publish endpoints
- An agent with `reviewer` profile cannot call promotion or publish endpoints
- Capability checks happen at the forge, not in the agent runtime

This is the same structural enforcement pattern as trust tiers (item 86):
the boundary is in the host, not in the client.

### 4.2 No self-escalation

An agent session cannot:

- Upgrade its own capability profile
- Extend its own session TTL beyond the maximum
- Acquire a lease on a resource outside its `resource_scope`
- Create a new agent session with broader authority than its own

Escalation requires human action: a user with appropriate permissions must
either assign a broader profile or approve the specific action.

### 4.3 Relationship to trust tiers

Agent capability profiles operate within the trust tier model (item 86):

| Trust tier | Typical agent profile | Authority ceiling |
|---|---|---|
| Tier 0 (untrusted) | No agent identity issued | No forge-native agent sessions |
| Tier 1 (reviewed) | `contributor` | Code mutation on approved branches |
| Tier 2 (protected) | `contributor` or `reviewer` | Code mutation + PR creation on protected branches |
| Tier 3 (release) | `release-agent` | Promotion and publish (requires explicit grant + human approval) |

An agent's effective authority is the intersection of its capability profile
and the trust tier of its execution context. The more restrictive boundary
always wins.

---

## 5. Credential and Session Lifecycle

### 5.1 Session creation

Agent sessions are created by:

- A human user authorizing an agent to work on their behalf
- An automation system (CI, scheduled job) with pre-configured agent profiles
- The forge itself when spawning agents for internal tasks

Session creation records: who authorized it, which profile was assigned, and
what scope was granted.

### 5.2 Session expiry

All agent sessions have a hard maximum TTL. The forge does not issue
indefinite agent credentials.

| Parameter | Default | Configurable range |
|---|---|---|
| Session TTL | 4 hours | 15 minutes – 24 hours |
| Renewal | Allowed within TTL | Up to max TTL from original creation |
| Hard maximum | 24 hours | Org-configurable, max 7 days |

### 5.3 Revocation

Agent sessions can be revoked:

- By the authorizing user at any time
- By an org admin at any time
- Automatically when the parent claim is closed or abandoned
- Automatically when the authorizing user's own session ends

Revocation is immediate: in-flight operations complete, but no new operations
are accepted.

### 5.4 What happens on expiry or revocation

- Active leases held by the agent are released
- In-progress attempts are marked as `cancelled` with reason
- The attempt lineage records what was completed before termination
- No work is silently lost: partial results remain in attempt artifacts

---

## 6. Blast-Radius Improvement

The capability boundary model improves blast radius relative to current
practice (broad workstation tokens or CI secrets):

| Current practice | With agent capability boundaries |
|---|---|
| Agent has user's full GitHub token | Agent has scoped session with code-mutation-only authority |
| Compromised agent can merge, publish, delete | Compromised agent can only push branches within its repo/path scope |
| Token valid for months | Session expires in hours |
| No audit trail of agent-specific actions | All actions attributed to specific agent session and authorizing user |
| Revoking access means rotating the shared token | Revoking one agent session does not affect other sessions |

---

## 7. Binding to Coordination Primitives

Agent identity integrates with the claim/lease protocol (see
`FORGE_CLAIM_LEASE_PROTOCOL.md`):

| Primitive | Agent identity role |
|---|---|
| **Claim** | `owner_ref` records the agent session, `owner_type` is `agent` |
| **Lease** | `holder_ref` is the agent session; lease scope must be within the agent's `resource_scope` |
| **Attempt** | `agent_profile_ref` records which capability profile governed the attempt |
| **ReviewState** | Agent sessions with `reviewer` authority can transition to `awaiting_human`; only humans can transition to `approved` |

This means every coordination action is attributable to a specific scoped
agent session, not to a broad shared credential.

---

## 8. Relationship to Prior Design

- **Round 117** — established that scoped agent identity and capability profiles
  are forge-native first-class objects
- **Trust tiers (item 86)** — the tier model that provides the execution-context
  ceiling for agent authority
- **Release event (item 84)** — the promotion primitive that requires explicit
  `release-agent` authority
- **Claim/lease protocol** — the coordination layer that agent identity binds to
- **Publishing UX (item 88)** — agents should benefit from the same zero-config
  publishing path as humans, within their capability scope

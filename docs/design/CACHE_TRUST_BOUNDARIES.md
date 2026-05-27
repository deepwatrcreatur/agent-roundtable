# Safe-by-Default Cache Trust Boundaries

**Status:** Drafted from Round 101
**Purpose:** Define the cache-isolation model so untrusted contribution paths
cannot poison caches later consumed by higher-trust branches, environments, or
release workflows.

---

## 1. Principle

**Cache isolation across branches and trust domains is the safe default, not a
user-configurable option.**

Round 101 established a three-tier hierarchy of CI security hygiene:

1. Runner ephemerality — the floor (table stakes)
2. Safe-by-default cache isolation — equally important
3. Control-plane authority separation — the layer that matters most

This note covers layer 2.

---

## 2. Cache Scope Dimensions

Cache entries are scoped along four dimensions:

| Dimension | Description |
|---|---|
| **Repository** | Which repo owns the cache |
| **Branch / ref** | Which branch or ref the cache was written from |
| **Trust tier** | The execution tier that produced the cache (0-3) |
| **Workflow / environment** | Which workflow or environment class used the cache |

The default isolation policy is: **a cache is readable only by jobs at the same
or lower trust tier, on the same branch, in the same repository.**

---

## 3. Default Isolation Rules

### 3.1 Cross-branch isolation

| Rule | Default |
|---|---|
| Can a feature branch read main's cache? | No |
| Can main read a feature branch's cache? | No |
| Can a release branch read main's cache? | No |
| Can a fork read the parent repo's cache? | No |

Each branch maintains its own cache namespace. Cache misses are preferred over
cross-branch cache reads because a poisoned cache on one branch should not
propagate to another.

### 3.2 Cross-tier isolation

| Rule | Default |
|---|---|
| Can Tier 0 (untrusted) read Tier 2 (protected) caches? | No |
| Can Tier 2 (protected) read Tier 0 (untrusted) caches? | No |
| Can Tier 3 (release) read Tier 2 (protected) caches? | Yes (read-only) |
| Can Tier 0 write to any shared cache? | No |

Tier 3 inherits from Tier 2 read-only because release builds should consume
the same artifacts that passed CI on the protected branch, but release jobs
should not write back to the CI cache.

### 3.3 Cross-repo isolation

| Rule | Default |
|---|---|
| Can repo A read repo B's cache? | No |
| Can a fork read the upstream repo's cache? | No |

Cross-repo cache sharing is never the default.

---

## 4. Explicit Opt-In for Broader Sharing

Teams that intentionally want broader cache sharing must opt in explicitly:

```yaml
cache_policy:
  sharing:
    # Allow feature branches to read main's cache (common for build caches)
    allow_branch_read_from:
      - source: main
        target: "feature/*"
        direction: read_only

    # Allow a monorepo's CI to share cache across certain paths
    allow_cross_workflow:
      - workflows: ["build", "test"]
        scope: same_branch
```

### 4.1 Opt-in requirements

- Opt-in rules must be declared in repo config, not workflow YAML (so they
  cannot be introduced by an untrusted PR)
- Changes to cache policy trigger a review notification
- The host logs which opt-in rules are active and when they were last modified

### 4.2 What cannot be opted into

Even with explicit opt-in:

- Tier 0 (untrusted) jobs can never write to caches readable by Tier 2+
- Tier 0 jobs can never read Tier 2+ caches
- Cross-repo cache sharing requires bilateral repo-admin approval
- Release (Tier 3) caches are always read-only from the release job's perspective

---

## 5. Cache Poisoning Mitigation

### 5.1 Content-addressed validation

Where possible, caches should be content-addressed (keyed by input hash, not
just cache key strings). This prevents:

- key collision attacks (same key, different content)
- stale cache injection (old content served under current key)

### 5.2 Cache provenance

Cache entries should carry minimal provenance:

| Field | Description |
|---|---|
| `written_by` | Job identity that wrote the cache |
| `written_at` | Timestamp |
| `trust_tier` | Tier of the writing job |
| `branch` | Branch the writing job ran on |
| `content_hash` | Hash of the cache contents |

This metadata is not a full SLSA attestation, but provides enough to audit
cache origin when investigating incidents.

### 5.3 Cache expiration

- Caches have a maximum TTL (host-configurable, default 7 days)
- Caches from Tier 0 jobs have a shorter default TTL (1 day)
- Stale caches are evicted rather than served

---

## 6. Relationship to Prior Design

- **Round 101** — established that cache isolation is as important as runner
  ephemerality and that branch/tag-scoped isolation should be the default
- **Trust tiers (item 86)** — defines the tier model that cache boundaries
  enforce
- **Release event (item 84)** — release context inherits protected caches
  read-only
- **Publishing UX (item 88)** — cache policy must not be a day-one burden

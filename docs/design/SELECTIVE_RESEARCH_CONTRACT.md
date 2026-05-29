# Selective Research Contract

**Status:** Drafted from Rounds 37 and 115
**Purpose:** Define the layered research/retrieval contract that lets agents use
cheap local retrieval first, premium open-web discovery second, and browser
automation only when the target genuinely requires it.

---

## 1. Boundary

This note answers a narrow question:

> How should agent workflows choose between local retrieval, direct fetch,
> premium search, and browser automation without wasting budget or blurring
> provenance?

The selective-research layer may own:

- task classification for retrieval mode choice
- budget-aware escalation between retrieval tiers
- capture of research snapshots/provenance
- browser-automation use only when a page truly requires it

It must **not** replace:

- repo-local or code-host-native retrieval
- direct fetch when the source URL is already known
- source inspection with opaque search synthesis
- host-owned evidence/provenance truth

This keeps research tooling as a bounded evidence-acquisition layer rather than
an ambient "search everything" habit.

---

## 2. Research tiers

The maintained retrieval order is:

1. **Repo-local / code-host-native retrieval**
2. **Direct known-URL fetch**
3. **Premium open-web discovery**
4. **Browser automation**

Each tier exists for a different problem.

### 2.1 Repo-local / code-host-native retrieval

Use when:

- the question is about local repo state
- code history or line/path retrieval is the primary need
- GitHub/Sourcegraph-style code search already covers the task

Examples:

- read a known file
- inspect a branch diff
- find related code or history
- analyze repository-local design artifacts

This should always beat any web-search or browser path on both cost and signal.

### 2.2 Direct known-URL fetch

Use when:

- the target source URL is already known
- the page can be fetched directly
- the main task is inspection, not discovery

Examples:

- vendor docs page already cited in a thread
- GitHub issue/PR with known URL
- product status page or changelog entry

This avoids paying premium search/discovery costs for a navigational task.

### 2.3 Premium open-web discovery

Use when:

- the relevant source URL is not yet known
- the task is genuinely about external discovery, freshness, or comparison
- multiple candidate sources must be surfaced quickly

Examples:

- finding current product docs for an unfamiliar API
- comparing external tools or providers
- incident/status/freshness checks across multiple sources

This is the right role for Exa-like search.

### 2.4 Browser automation

Use only when:

- the target site is JS-heavy or gated enough that ordinary fetch/search is
  insufficient
- the task requires rendered DOM interaction or navigation
- the marginal value justifies the higher complexity/cost

Examples:

- SPA-only content that does not yield to direct fetch
- dynamic UI metadata extraction
- anti-bot-sensitive browsing where a simple HTTP client path fails

This is the right role for Browserbase-like tools.

---

## 3. Core objects

### 3.1 `ResearchRequest`

Minimum shape:

| Field | Meaning |
|---|---|
| `request_id` | Stable research request ID |
| `attempt_ref` | Attempt or work-item lineage anchor when present |
| `research_goal` | Human-readable question being answered |
| `target_class` | `repo_local`, `known_url`, `open_web`, `js_heavy_site`, `social_metadata` |
| `freshness_requirement` | `none`, `recent`, `live` |
| `budget_class` | `low`, `medium`, `premium` |
| `provenance_requirement` | Whether captured source snapshots are required |

### 3.2 `ResearchDecision`

Minimum shape:

| Field | Meaning |
|---|---|
| `request_id` | Parent research request |
| `selected_tier` | `local`, `direct_fetch`, `premium_search`, `browser_automation` |
| `reason_codes` | Why this tier was chosen |
| `cost_expectation` | Expected spend/latency class |
| `recorded_at` | Decision timestamp |

### 3.3 `ResearchSnapshot`

Minimum shape:

| Field | Meaning |
|---|---|
| `snapshot_id` | Stable snapshot ID |
| `request_id` | Parent request |
| `source_url` | Final inspected URL |
| `retrieval_tier` | Which tier produced it |
| `captured_at` | Capture time |
| `content_hash` | Hash of captured material |
| `title` | Short source label |
| `excerpt_refs` | Highlight or extracted snippet references |

The snapshot is the provenance anchor, not the search provider’s synthesized
summary alone.

---

## 4. Tier-selection rules

### 4.1 Local first

If the task is primarily about repo or code-host state:

- use local search
- use GitHub-native search
- use Sourcegraph-style retrieval

Do **not** escalate to premium web search just because "search" is involved.

### 4.2 Direct fetch before discovery

If the URL is already known:

- fetch that page directly
- only escalate if the page cannot be meaningfully inspected that way

### 4.3 Premium search as bounded escalation

Premium search should be used only when:

- the task is truly about external discovery
- freshness or multi-source comparison matters
- the URL is not already known

Cheap first-pass defaults should apply:

- small result sets
- highlight-oriented responses
- lower-cost modes before deep synthesis

### 4.4 Browser automation as last resort

Browser automation should be used only when:

- the page requires JS rendering or multi-step interaction
- direct fetch and premium discovery are insufficient
- provenance capture still remains possible

This prevents browser automation from becoming the default answer to all hard
research tasks.

---

## 5. Budget discipline

Selective research is partly an economics contract.

### 5.1 Cheap first-pass rule

Agents should prefer the cheapest tier that can plausibly answer the question.

That means:

- local search before external search
- direct fetch before discovery
- shallow premium search before deep synthesis
- browser automation last

### 5.2 Pause-and-justify posture

If premium search or browser automation starts stacking up in a session, the
system should make that visible.

This does not require hard blocking, but it should support:

- session-level budget visibility
- reason-coded escalation
- later auditing of why higher-cost tiers were used

---

## 6. Provenance and inspection

Selective research must return inspectable sources, not just conclusions.

Minimum rule:

- every external research conclusion should be traceable to captured source URLs
  and timestamps

This matters especially for:

- time-sensitive status or incident research
- social/product comparisons
- claims derived from premium search synthesis
- browser-automation-derived metadata

Search/provider output is a discovery aid, not a substitute for inspectable
evidence.

---

## 7. Browser automation boundary

The original item focused on Browserbase because JS-heavy browsing is a real
gap. That remains true, but Browserbase-like tooling now sits at the **fourth
tier**, not the first.

Browser automation is justified for:

- JS-heavy SPAs
- rendered metadata extraction
- pages that refuse simple fetch paths
- anti-bot-fragile workflows where a standard client is not enough

It is not justified for:

- local code retrieval
- known documentation URLs
- routine product discovery that premium search can already solve

---

## 8. Relationship to existing retrieval work

This contract complements, rather than replaces:

- Sourcegraph-style code retrieval for repo/code-host-native work
- the agent proxy/cache contract for provider cost/routing policy
- hosted-analysis/source evidence contracts for durable evidence ingestion

The important distinction is:

- **selective research** chooses how to obtain external evidence
- other contracts govern how that evidence is normalized, cached, or attached to
  attempts/findings later

---

## 9. Recommended implementation sequence

1. classify research tasks by target class and freshness need
2. encode the tier cascade explicitly in guides/runtime policy
3. record research decisions and snapshots for provenance
4. add budget visibility for premium search and browser automation
5. only then optimize individual providers/tools

---

## 10. Final synthesis

The right research posture is:

- local/code-host retrieval first
- direct fetch when the URL is known
- premium search for genuine open-web discovery
- browser automation only for JS-heavy or interaction-dependent targets

That gives the system bounded cost, stronger provenance, and a clear reason why
Browserbase-like tooling exists without turning it into the default path for
every research task.

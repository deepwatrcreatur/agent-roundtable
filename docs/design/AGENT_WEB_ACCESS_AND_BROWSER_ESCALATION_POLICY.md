# Agent Web Access and Browser Escalation Policy

**Status:** Drafted from operational evidence and prior contracts
**Purpose:** Define the maintained default policy for how agents access the web,
ensuring the cheapest and most reliable retrieval path is used first with a
clear escalation route when static/API fetches are not enough.

---

## 1. Principle

**Fetch/API first, browser escalation second.**

Agents should exhaust cheap, reliable, machine-oriented retrieval before
reaching for browser automation. Every escalation step adds cost, latency, and
fragility. The default should be the simplest path that works.

---

## 2. Web Access Cascade

The maintained retrieval order is:

| Priority | Tier | When to use |
|---|---|---|
| 1 | **Repo-local and code-host-native** | Question is about local state, code, or host-native metadata |
| 2 | **Direct raw/API fetch** | Target URL is known; endpoint is machine-oriented (JSON, raw text, API) |
| 3 | **Direct HTML/page fetch** | Target URL is known; page is static HTML that renders without JavaScript |
| 4 | **Browserbase browse / browser-backed search** | Plain fetch fails, returns anti-bot rejection, or target requires JS rendering |
| 5 | **Full browser automation** | Target requires multi-step interaction, login, navigation, or DOM manipulation |

Each tier exists because a specific class of targets cannot be served by the
tier above it.

### 2.1 Repo-local and code-host-native (Tier 1)

Always try first. No external network access needed.

Examples:
- `git log`, `git show`, file reads
- GitHub REST API for issues, PRs, checks
- Sourcegraph code search
- Local design artifacts and round transcripts

### 2.2 Direct raw/API fetch (Tier 2)

Use when the URL is known and the endpoint returns structured data.

Examples:
- GitHub raw content: `raw.githubusercontent.com`
- npm registry API: `registry.npmjs.org/<package>`
- crates.io API: `crates.io/api/v1/crates/<crate>`
- PyPI JSON API: `pypi.org/pypi/<package>/json`
- vendor REST APIs with stable endpoints

These are machine-oriented endpoints that do not require rendering, cookies,
or JavaScript.

### 2.3 Direct HTML/page fetch (Tier 3)

Use when the URL is known but the content is HTML rather than raw data.

Examples:
- Documentation pages with server-rendered content
- Blog posts and changelogs
- Static status pages

This tier works for pages that deliver meaningful content in the initial HTML
response. If the response is a shell that loads content via JavaScript, this
tier will fail silently — escalate to Tier 4.

### 2.4 Browserbase browse / browser-backed search (Tier 4)

Use when Tier 2-3 fail or the target is known to require browser capabilities.

Examples:
- npm search page (returns `403` to non-browser clients)
- JS-heavy documentation sites (SPA-only rendering)
- Social metadata extraction (LinkedIn, X/Twitter profiles)
- Sites with anti-bot protection that rejects standard HTTP clients
- Pages that require cookie consent or navigation to reach content

This is the primary browser escalation path. Browserbase `browse` provides
headless browser access with session management, which handles the majority
of cases where plain fetch fails.

### 2.5 Full browser automation (Tier 5)

Use only when the task requires multi-step interaction beyond page rendering.

Examples:
- Login-gated content requiring authentication flow
- Multi-page navigation sequences
- Form submission and response capture
- Dynamic UI interaction (clicks, scrolls, hover reveals)

This is the most expensive and fragile tier. It should be rare in normal
agent workflows.

---

## 3. Escalation Decision Boundary

### 3.1 When to escalate from fetch to browser

Escalate when any of these conditions is true:

| Condition | Signal | Escalation target |
|---|---|---|
| HTTP 403 or anti-bot rejection | Response body contains bot-detection content | Tier 4 (Browserbase browse) |
| Empty or shell HTML | Response is `<div id="app"></div>` or similar JS-loading shell | Tier 4 (Browserbase browse) |
| Known JS-heavy site | Site is in the known-JS-heavy list | Tier 4 (Browserbase browse) |
| Content requires interaction | Need to click, scroll, or navigate to reach target | Tier 5 (full automation) |
| Content requires authentication | Login flow needed before content is accessible | Tier 5 (full automation) |

### 3.2 When NOT to escalate

Do not use browser automation for:

| Scenario | Why not | Use instead |
|---|---|---|
| GitHub content | Stable API and raw endpoints exist | Tier 1-2 (code-host native / raw fetch) |
| npm package metadata | Registry API returns JSON | Tier 2 (`registry.npmjs.org` API) |
| Known documentation URLs | Most docs sites serve meaningful HTML | Tier 3 (HTML fetch) |
| Routine product discovery | Premium search handles this | Tier 3-4 (search first) |
| Local repo questions | No web access needed | Tier 1 (repo-local) |

### 3.3 Known JS-heavy sites

Sites where Tier 3 is known to fail and Tier 4 should be used directly:

- npm search (`npmjs.com/search`) — returns 403 to non-browser clients
- LinkedIn profiles and company pages
- X/Twitter profile pages
- Most SPA-only web applications
- Sites behind Cloudflare bot protection with JS challenge

This list should be maintained and extended based on operational experience.

---

## 4. Operational Evidence

This policy is motivated by observed failures, not theoretical preference.

### 4.1 GitHub MCP / session-backed search failures

GitHub's MCP-based search requires active session state. When sessions expire
or are invalid, search calls fail silently or return errors. This motivated
the rule: use GitHub REST API (Tier 2) for programmatic GitHub queries rather
than relying on session-backed search surfaces.

### 4.2 npm search anti-bot rejection

The npm website (`npmjs.com/search`) returns HTTP 403 to standard HTTP clients.
The npm **registry API** (`registry.npmjs.org`) returns clean JSON. This
motivated the distinction between machine-oriented API endpoints (Tier 2) and
interactive web surfaces that require browser state (Tier 4).

### 4.3 API vs. page endpoint divergence

Many services have both API endpoints (stable, machine-oriented) and web pages
(fragile, rendering-dependent). The general pattern:

| Service | API endpoint (stable) | Web page (fragile) |
|---|---|---|
| npm | `registry.npmjs.org/<pkg>` | `npmjs.com/package/<pkg>` |
| GitHub | `api.github.com` / `raw.githubusercontent.com` | `github.com/<repo>` |
| crates.io | `crates.io/api/v1/crates/<crate>` | `crates.io/crates/<crate>` |
| PyPI | `pypi.org/pypi/<pkg>/json` | `pypi.org/project/<pkg>` |

The policy is: always prefer the API endpoint when one exists.

---

## 5. Budget and Cost Awareness

### 5.1 Cost ordering

| Tier | Relative cost | Latency |
|---|---|---|
| Repo-local | Free | Instant |
| Raw/API fetch | Negligible | Milliseconds |
| HTML fetch | Negligible | Milliseconds |
| Browserbase browse | Moderate | Seconds |
| Full browser automation | High | Seconds to minutes |

### 5.2 Session budget visibility

When browser-tier access accumulates in a session, the system should make
this visible. This does not require hard blocking but supports:

- session-level browser-usage count
- reason-coded escalation records
- later audit of why higher-cost tiers were used

---

## 6. Compatibility with Selective Research Contract

This policy is the **operational companion** to the selective research
contract (`SELECTIVE_RESEARCH_CONTRACT.md`). The relationship:

| Selective research contract | This policy |
|---|---|
| Defines research tiers and objects | Defines the specific cascade and escalation rules |
| Defines `ResearchRequest` / `ResearchDecision` / `ResearchSnapshot` | Provides the decision logic that produces those objects |
| Covers premium search as a tier | Covers the specific fetch vs. browser boundary |
| Covers provenance requirements | Provides the operational evidence behind provenance needs |

The two documents should be read together. This policy does not replace the
selective research contract — it sharpens the fetch-vs-browser boundary with
operational evidence.

---

## 7. Tool Agnosticism

The current preferred browser escalation path is Browserbase. However, the
policy is designed around the **capability** (headless browser with session
management), not the specific provider. If Browserbase is replaced by another
browser-automation backend, the cascade and escalation rules remain the same.

What matters is:
- the ability to render JavaScript
- the ability to manage cookies and session state
- the ability to navigate multi-page flows
- the ability to bypass anti-bot protections

Not the brand name of the service providing those capabilities.

---

## 8. Relationship to Prior Design

- **Selective research contract (item 52)** — the layered research contract
  that this policy sharpens
- **Agent proxy and cache contract (item 51)** — cost/routing policy for
  provider selection
- **Sourcegraph integration (items 80-81)** — code-host-native retrieval that
  lives at Tier 1
- **Browseable board surface (item 97)** — web UI that should be tested via
  browser automation when needed

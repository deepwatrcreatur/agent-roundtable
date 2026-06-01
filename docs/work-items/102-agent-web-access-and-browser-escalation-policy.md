# 102 — Agent Web Access and Browser Escalation Policy

**Status:** `ready`
**Tag:** `[tools]`

## Goal

Define the maintained default policy for how agents should access the web so
they use the cheapest and most reliable retrieval path first, while still
having a clear escalation route when static/API fetches are not enough.

## Scope

- Define the default retrieval cascade for agent web access:
  - repo-local and code-host-native retrieval first
  - direct raw/API fetches second
  - direct HTML/page fetches third
  - Browserbase `browse` / browser-backed fetch-and-search next when plain fetch
    fails or is a bad fit
  - full browser automation last for JS-heavy, login-gated, bot-protected, or
    interaction-dependent targets
- Make the escalation boundary explicit:
  - use `web_fetch` and known APIs for raw GitHub content, GitHub REST, npm
    registry, and similar machine-oriented endpoints
  - use Browserbase `browse` / Browserbase fetch-search surfaces when a site
    rejects automated HTML fetches, requires JavaScript execution, or needs real
    browser state such as cookies, navigation, or DOM interaction
- Capture the failure modes that motivated the policy:
  - GitHub MCP / session-backed search invalid-session failures
  - HTML-site anti-bot rejection such as npm search returning `403`
  - the difference between raw/API endpoints that are stable and interactive
    page surfaces that are not
- Keep the policy tool-agnostic enough that `browse` / Browserbase is the
  current preferred browser escalation path without pretending it is the only
  imaginable future backend.

## Acceptance Criteria

- A canonical design note or contract exists for the web-access cascade and
  escalation decision.
- The maintained default answer is unambiguous:
  fetch/API first, browser escalation second.
- The design explicitly describes when Browserbase `browse` is warranted and
  when it would be unnecessary overkill.
- The design records the observed operational evidence behind the policy rather
  than presenting it as a purely theoretical preference.
- The policy is compatible with the earlier selective-research contract instead
  of conflicting with it.

## Notes

- Primary design sources:
  - `docs/design/rounds/round-141-herdr-vs-dmux-wrapper-and-what-to-do-now.md`
  - `docs/work-items/52-selective-research.md`
- Closely related work:
  - `51-proxy-and-cache.md`
  - `80-sourcegraph-lineage-integration-briefs.md`
  - `81-sourcegraph-thin-adapter-implementation.md`
  - `97-browseable-board-surface.md`

# 71 — Forgejo Shell Shareable Web Entry

**Status:** `done`
**Assigned:** Codex
**Tag:** `[product]`

## Goal

Make the Forgejo shell a first-class, shareable surface on the Roundtable web
app so interested people can be sent to the site and immediately understand
what the demo is for.

## Scope

- Add a clear homepage or landing-surface entry point for the Forgejo shell.
- Make the shell feel intentionally linked into the Roundtable website, not like
  a hidden side page.
- Improve the page framing so a new visitor understands:
  - what Forgejo owns
  - what Vaglio owns
  - why the shell exists
  - what to click first
- Prefer a simple, product-facing narrative over operator-only copy.

## Acceptance Criteria

- A visitor can discover the Forgejo shell from the main Roundtable web surface
  without needing to know the `/forgejo-shell` path in advance.
- The landing copy is legible to an interested outsider, not just the project
  author.
- The path from landing page to demo content feels intentional and shareable.

## Notes

- Keep the current `/forgejo-shell` route; this item is about discoverability and
  framing, not renaming the surface.
- Avoid coupling this work to authentication redesign unless that is strictly
  required for the shareable path.

## Outcome

- Added a public `RoundtableWeb.LandingLive` at `GET /` as the shareable web
  entry point.
- Moved the operator dashboard from `/` to `GET /roundtable` so the public
  landing surface is no longer blocked behind the internal ops entry path.
- Updated shared navigation to expose:
  - demo home
  - Forgejo shell
  - Roundtable ops
- Added focused navigation coverage so the landing page, shell page, and
  operator dashboard stay linked intentionally.

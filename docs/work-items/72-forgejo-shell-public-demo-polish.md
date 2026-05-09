# 72 — Forgejo Shell Public Demo Polish

**Status:** `done`
**Assigned:** Codex
**Tag:** `[market]`

## Goal

Polish the Forgejo shell so it can be shared with interested people soon as a
credible public-facing demo, not just an internal prototype screen.

## Scope

- Review the current shell page as an external viewer would.
- Tighten the narrative around the curated demo repos and investor/demo value.
- Improve the visual and copy hierarchy so the first screen answers:
  - what this is
  - what value it demonstrates
  - which curated demo to try first
- Make the default state feel polished enough to share via a single link.
- Add any lightweight UX affordances that help social/demo sharing:
  - clearer heading/subheading
  - default curated demo emphasis
  - obvious outbound links
  - reduced operator-oriented clutter above the fold

## Acceptance Criteria

- The page is understandable to a technically curious outsider without verbal
  narration.
- The default shell view highlights a recommended demo path.
- The resulting surface feels ready to send to interested people as an early
  product demonstration.

## Notes

- This item can assume `/forgejo-shell` already exists and is reachable.
- Keep scope focused on shareability and demo clarity; deeper repo import or
  backend changes belong in separate items.

## Outcome

- Made `forgejo/forgejo` the default curated demo so the shell opens on the
  clearest product-boundary story.
- Added a stronger above-the-fold hero that explains:
  - what the shell is
  - why it matters
  - what to click first
- Added recommended-demo framing plus direct outbound links to:
  - the public source repo
  - the imported Forgejo target
- Moved the raw shell input form lower on the page as "Advanced Prototype Source
  Controls" to reduce operator-oriented clutter above the fold.
- Updated focused LiveView coverage for the revised public demo narrative.

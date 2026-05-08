# 63 — Vaglio Dashboard OpenCode Restyle

**Status:** `in-progress` — **Codex** — `feat/opencode-dashboard-style`

## Goal

Restyle the Vaglio LiveView dashboard using the `opencode.ai` `DESIGN.md`
system from `VoltAgent/awesome-design-md`.

## Design Source

- `design-md/opencode.ai/DESIGN.md`

## Scope

- Translate the current GitHub-dark inline styling to the OpenCode system:
  - Berkeley Mono-first typography
  - warm cream / near-black palette
  - hairline borders instead of glossy card chrome
  - terminal-native action styling
- Keep the current dashboard structure and behavior intact:
  - question cards
  - conflict cards
  - inject-question form
  - trigger-round controls
  - polling / event flow
- Make the page feel like a technical console rather than a SaaS admin panel.

## Acceptance Criteria

- The dashboard no longer uses the current GitHub-dark blue styling.
- Typography and spacing clearly reflect the OpenCode design language.
- The page remains usable on mobile and desktop.
- No behavior regressions in `DiscussionLive`.

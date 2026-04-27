# 10 — Roundtable.Web (Phoenix LiveView Dashboard)

**Status:** `blocked` (needs 06, 07)
**Assigned:** unassigned
**Branch:** `feat/web-dashboard`

## Scope

A Phoenix LiveView web dashboard giving the human owner a real-time view of
discussion state, with the ability to inject questions, post guidance, and
approve actions — without reading raw GitHub Issues or terminal output.

## Owner needs

- **Read:** which questions are open, current round number, which agents have
  spoken, current satisfaction labels per agent per question, any
  `needs-human-review` flags
- **Write:** inject a new question into an active discussion, post an owner
  guidance note into a specific issue thread, resume a paused round
- **Control:** approve a PR, trigger or pause the orchestrator, mark an item
  `needs-human-review` manually

## Architecture

`Roundtable.Web` is a Phoenix app (within the same Mix umbrella or as a
separate app in `apps/`) that calls `Roundtable.CLI` module functions directly.
No business logic lives in the web layer.

```
Roundtable.Web (Phoenix LiveView)
  └── calls Roundtable.CLI functions
        └── calls Roundtable.Actions.Gh (Issues, labels, comments)
              └── gh CLI
```

LiveView subscriptions push issue state changes to the browser in real time
via `Phoenix.PubSub`. The orchestrator publishes events; the dashboard
subscribes.

## Key views

- **Discussion index** — all questions, status, round, satisfaction table
- **Question detail** — full comment thread from the GitHub Issue, current
  labels, satisfaction state per agent
- **Owner actions panel** — inject question form, guidance note form,
  approval buttons
- **Work item queue** — current item statuses from `docs/work-items/`

## Done when

- Discussion index shows live satisfaction state from GitHub Issues
- Owner can inject a new question and see it appear as a GitHub Issue
- Owner can post a guidance note that appears as an issue comment
- `needs-human-review` questions are highlighted with an approve/dismiss action
- Deployed in the Nix flake devShell (`mix phx.server`)

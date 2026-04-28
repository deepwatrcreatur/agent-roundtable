# 10 — Web Dashboard (Phoenix LiveView)

**Status:** `ready-for-review`
**Assigned:** Claude IC
**Branch:** `feat/web-dashboard`

## Scope

Phoenix LiveView single-page dashboard for the repo owner.

### Read path (no orchestrator required)

- Lists all GitHub Issues labelled `roundtable` with title, satisfaction state, label chips, comment count
- Colour-coded by satisfaction: green (satisfied), amber (conditional), red (needs evidence), grey (unknown)
- Auto-polls every 30s via LiveView `handle_info(:poll, ...)`

### Write path (requires items 06/07)

- **Inject question** — text area → creates GitHub Issue with `roundtable` + `needs-more-evidence` labels
- **Trigger round** — fires `Roundtable.CLI.start_discussion/2` in a background `Task`; streams events back to UI via `on_event` callback → `send(lv_pid, ...)`

## Environment variables

| Var | Default | Description |
|---|---|---|
| `ROUNDTABLE_REPO` | `""` | GitHub repo slug (`owner/repo`) |
| `ROUNDTABLE_BRIEF` | `docs/design/BRIEF.md` | Path to BRIEF.md |
| `PORT` | `4000` | HTTP listen port |
| `SECRET_KEY_BASE` | dev default | Phoenix session secret (required in prod) |
| `ROUNDTABLE_WEB` | `"true"` in dev/prod | Set `"false"` to disable web in CLI-only mode |

## Running

```bash
# In nix devShell or with Elixir installed:
ROUNDTABLE_REPO=owner/repo mix run --no-halt

# Or via flake app:
ROUNDTABLE_REPO=owner/repo roundtable-web
```

## Architecture

```
Browser ←→ Phoenix LiveView (WebSocket)
              ↓ on_mount
          RoundtableWeb.DiscussionLive
              ↓ get_discussion_state/1   ← polls gh issue list
          Roundtable.CLI
              ↓ inject_question/3        ← gh issue create
              ↓ start_discussion/2       ← Orchestrator.run/3
          Roundtable.Orchestrator
```

## What is NOT in v1

- Authentication / access control (the dashboard is localhost-only by default)
- Question dependency graph view
- Agent participation tracking chart (load-balancing metric from Q17)
- Binary execution gate buttons (merge PR, proceed to next work item)
- DECISION.md / ATTRIBUTION.md edit surface

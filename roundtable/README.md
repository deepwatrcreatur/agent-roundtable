# Roundtable

`roundtable/` is the Elixir application for the autonomous multi-agent
roundtable orchestrator.

It currently includes:

- CLI agent execution and prompt building
- discussion repo and GitHub issue integration
- persisted `RoundRun` state
- telemetry spans for orchestrator lifecycle events
- a Phoenix/LiveView supervision surface

## Development

Run tests from a shell with Elixir, Erlang, and `git` available:

```sh
mix test
```

The checked-in `flake.nix` is intended to provide that environment once it is
fully corrected; an ad-hoc `nix-shell -p elixir erlang git` also works.

From this directory, the flake now provides:

```sh
nix develop
nix run . -- path/to/BRIEF.md
```

The dev shell includes:

- Elixir / Erlang
- `git`
- `gh`
- `claude-code`
- `codex`
- `gemini-cli`

Required credentials are **not** hardcoded in the flake. The current harness
uses a mixed auth model:

- Claude CLI: local Claude session/config (typically `~/.claude/config.json`);
  `ANTHROPIC_API_KEY` may still be useful in some environments
- Codex CLI: local Codex login/session (typically under `~/.codex/`)
- Gemini CLI: local OAuth credentials at `~/.gemini/oauth_creds.json`
- DeepSeek: `DEEPSEEK_API_KEY`
- GitHub integration: `GH_TOKEN` or `GITHUB_TOKEN`

For full eval runs, verify that all of the above are available before starting.

## Telemetry

Roundtable emits OpenTelemetry-shaped spans via `:telemetry.execute/3` rather
than coupling directly to a specific OTEL SDK.

Core events include:

- `roundtable.issue.poll`
- `roundtable.agent.turn`
- `roundtable.gh.comment`
- `roundtable.satisfaction.parse`
- `roundtable.ic.triage`
- `roundtable.consensus.check`
- `roundtable.issue.close`
- `roundtable.phase.transition`

Coordinator robustness events are also emitted:

- `roundtable.coordinator.lease.claim`
- `roundtable.coordinator.heartbeat`
- `roundtable.coordinator.timeout`
- `roundtable.coordinator.takeover`

### Dev JSON logger

In development, `config/dev.exs` sets:

```elixir
config :roundtable, telemetry_handler: :json_logger
```

On application start, `Roundtable.Application` calls
`Roundtable.Telemetry.attach_logger/0`, which prints each event as structured
JSON to stdout.

### OTEL exporter wiring

V1 does not require the `opentelemetry` SDK, but you can attach one
optionally. See:

- <https://hex.pm/packages/opentelemetry_exporter>

Typical wiring looks like:

```elixir
:telemetry.attach_many(
  "otel-exporter",
  Roundtable.Telemetry.all_events(),
  &MyApp.OtelHandler.handle_event/4,
  nil
)
```

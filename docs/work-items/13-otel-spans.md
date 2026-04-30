# 13 — OTEL Span Taxonomy for Roundtable Events

**Status:** `in-progress`
**Assigned:** GitHub Copilot
**Branch:** `feat/otel-spans`

## Scope

Define and emit OpenTelemetry-shaped spans for all significant orchestrator
events, wired via Jido's existing telemetry infrastructure.

## Why

The current `on_event` callback emits raw tuples to the LiveView UI, but nothing
is structured for export to an OTEL collector, log aggregator, or tracing tool.
Protocol Update 7 requires the span taxonomy to be defined before the system
grows more complex.

## Span Taxonomy

| Span name | Attributes | When emitted |
|---|---|---|
| `roundtable.issue.poll` | `issue_number`, `gh_repo` | `Gh.view_issue/3` call |
| `roundtable.agent.turn` | `agent`, `issue_number`, `round` | `RunCliAgent.run/2` start |
| `roundtable.gh.comment` | `issue_number`, `agent`, `body_bytes` | `Gh.comment_issue/3` call |
| `roundtable.satisfaction.parse` | `agent`, `result`, `method` (marker/triage) | after marker extraction |
| `roundtable.ic.triage` | `issue_number`, `result` | `triage_with_ic/5` call |
| `roundtable.consensus.check` | `issue_number`, `labels`, `result` | `Satisfaction.consensus?/1` |
| `roundtable.issue.close` | `issue_number`, `round`, `reason` | `Gh.close_issue/3` call |
| `roundtable.phase.transition` | `issue_number`, `from_phase`, `to_phase` | every `RoundRun.put_phase/2` |

## Implementation

Use `:telemetry.execute/3` to emit events matching the above names. Attach
metadata as the measurements/metadata maps. In `config/dev.exs`, attach a
`:telemetry_logger` handler that logs them as structured JSON to stdout. In
production, attach an `opentelemetry` exporter handler.

Do not add the `opentelemetry` SDK as a required dep for v1; use `:telemetry`
(already a transitive dep via Jido/Phoenix) and document how to wire an OTEL
exporter optionally.

## Done When

- All eight spans are emitted at the correct call sites
- `config/dev.exs` attaches a handler that prints structured JSON to stdout
- README documents how to attach an OTEL exporter (link to
  `opentelemetry_exporter` hex package)
- Unit tests verify that `:telemetry.attach` captures expected events during
  a mock orchestrator run

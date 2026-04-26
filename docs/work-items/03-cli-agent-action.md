# 03 — Roundtable.Actions.RunCliAgent

**Status:** `blocked` (needs 01)
**Assigned:** Codex
**Branch:** `feat/cli-agent-action`

## Scope

Implement `Roundtable.Actions.RunCliAgent` — the Jido Action that invokes
`claude`, `codex`, or `gemini` headlessly and returns their prose response.

## Interface

```elixir
defmodule Roundtable.Actions.RunCliAgent do
  use Jido.Action, name: "run_cli_agent"

  # params: %{agent: :claude | :codex | :gemini, prompt: String.t(), timeout_ms: integer()}
  # returns: {:ok, %{response: String.t()}} | {:error, reason}
end
```

## Per-agent invocation (confirmed in Q1 research)

```
claude 2.1.83:   claude -p --output-format json <prompt>
codex 0.116.0:   printf prompt | codex exec - --json --output-last-message /tmp/out
gemini 0.35.0:   gemini -p <prompt> --output-format json
```

Extract the assistant text from each agent's JSON output shape — shapes differ
per agent and need to be handled individually.

## Notes

- Default timeout: 120_000ms (2 minutes); configurable via param
- On timeout: return `{:error, :timeout}` — do not leave orphan processes
- Capture stderr separately from stdout; log it but do not include in response
- The `prompt` param is a pre-built string from `Roundtable.Prompt` — this
  action does not build prompts, it only invokes

## Done when

- All three agents invoke correctly in tests (mock `System.cmd/3`)
- Timeout handled cleanly
- JSON output parsed to plain text for each agent's response shape

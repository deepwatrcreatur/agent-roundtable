# 03 — Roundtable.Actions.RunCliAgent

**Status:** `done` (Gemini)
**Assigned:** Codex
**Branch:** `feat/cli-agent-action`

## Scope

Implement `Roundtable.Actions.RunCliAgent` — the Jido Action that invokes
roundtable participants headlessly and returns their prose response.

Per Q8, this should be **vendor-CLI-first in v1** but structured as a
**harness selector** rather than a permanently hard-coded wrapper around only
three binaries.

## Interface

```elixir
defmodule Roundtable.Actions.RunCliAgent do
  use Jido.Action, name: "run_cli_agent"

  # params: %{
  #   agent: %{id: atom(), harness: :vendor_cli | :opencode, provider: term(), model: term()},
  #   prompt: String.t(),
  #   timeout_ms: integer(),
  #   harness_opts: keyword()
  # }
  # returns: {:ok, %{response: String.t(), metadata: map()}} | {:error, reason}
end
```

The v1 required agents are still the verified vendor CLIs:

- `:claude_ic`
- `:codex`
- `:gemini`

But the action should delegate through a harness abstraction so a future
`OpenCodeHarness` can add first-class agents like GitHub Copilot or OpenCode
Go without changing orchestrator logic.

## Per-agent invocation (confirmed in Q1 research)

```
claude 2.1.83:   claude -p --output-format json <prompt>
codex 0.116.0:   printf prompt | codex exec - --json --output-last-message /tmp/out
gemini 0.35.0:   gemini -p <prompt> --output-format json
```

Extract the assistant text from each agent's JSON output shape — shapes differ
per agent and need to be handled individually. Keep the vendor-specific parsing
inside the vendor harness/backend rather than leaking it into orchestrator code.

## Notes

- Default timeout: 120_000ms (2 minutes); configurable via param
- On timeout: return `{:error, :timeout}` — do not leave orphan processes
- Capture stderr separately from stdout; log it but do not include in response
- The `prompt` param is a pre-built string from `Roundtable.Prompt` — this
  action does not build prompts, it only invokes
- For v1, implement only the vendor CLI harness path; `:opencode` is a
  design-level extension point, not a required backend for this item
- Distinct agent identity must remain explicit in config (`agent.id`,
  harness/provider/model), not inferred only from the executable name

## Done when

- All three agents invoke correctly in tests (mock `System.cmd/3`)
- Timeout handled cleanly
- JSON output parsed to plain text for each agent's response shape
- Harness selection is covered by tests for the vendor CLI path, with the
  abstraction boundary in place for a later OpenCode backend

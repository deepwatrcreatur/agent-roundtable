# 08 — flake.nix

**Status:** `in-progress`
**Assigned:** GitHub Copilot
**Branch:** `feat/flake-pins`

## Scope

Included in item 01. Listed separately so it is not overlooked.

## Requirements

- `devShell`: Elixir + Erlang (BEAM), `gh` CLI, `claude`, `codex`, `gemini`
- `packages.default`: app output that wraps `mix run -e 'Roundtable.CLI.main(System.argv())'`
  as a `roundtable` binary
- Pin tool versions matching Q1 research findings:
  `claude 2.1.83`, `codex-cli 0.116.0`, `gemini-cli 0.35.0`
- `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `GH_TOKEN` must
  be available as env vars (document in README; do not hardcode)

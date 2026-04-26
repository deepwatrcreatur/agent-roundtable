# 01 — Mix Project Scaffold + Nix flake.nix

**Status:** `ready`
**Assigned:** Codex
**Branch:** `feat/scaffold`

## Scope

- `mix new roundtable --sup` at the repo root
- `mix.exs`: add `{:jido, "~> 2.0"}` dependency; set app name, version,
  Elixir version requirement
- `mix deps.get` and commit `mix.lock`
- Minimal `lib/roundtable/application.ex` confirming OTP supervisor starts
- `flake.nix`: devShell with Elixir + Erlang + `gh` CLI + `claude` + `codex`
  + `gemini`; `packages.default` app that wraps `mix run` as `roundtable`
- `.gitignore` additions: `_build/`, `deps/`, `.elixir_ls/`

## Why Codex

Codex did Q1 research: verified installed versions of all three CLI agents and
their headless flags. That knowledge is needed to pin the correct tool versions
in `flake.nix`.

## Output

A compiling, `mix test`-passing skeleton that other agents can branch from.
Nothing domain-specific — no roundtable logic yet.

## Done when

- `mix test` passes on a clean clone
- `nix develop` opens a shell with all required tools on PATH
- Other work items can branch from this and add modules without touching
  `mix.exs` or `flake.nix` (unless they need a new dep)

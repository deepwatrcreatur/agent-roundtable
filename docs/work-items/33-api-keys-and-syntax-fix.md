# 33 — Fix Syntax Error and Missing API Keys

**Status:** `done`
**Assigned:** Codex

## Scope

1. Fix syntax error in `roundtable/flake.nix` (it currently has a `:` instead of `=` on line 2 in the remote repository).
2. Identify and document missing API keys required for full evaluation.
3. Switch `unified-nix-configuration` to use local path for `agent-roundtable` for development/testing.

## Outcome

This item's original assumptions were partly stale by the time it was taken
over. The actual work was to reconcile the docs and queue state with the current
implementation.

## Findings

### Syntax Error
The `roundtable/flake.nix` syntax error had already been fixed. The current
branch uses the correct form:

```nix
description = "Roundtable - Autonomous multi-agent design orchestrator";
```

### Missing API Keys
The repo secret files already exist in
`unified-nix-configuration/secrets-agenix/` for:

- `anthropic-api-key.age`
- `openai-api-key.age`
- `gemini-api-key.age`
- `deepseek-api-key.age`
- `github-token.age`

The important distinction is auth surface, not just secret presence:

- Claude CLI primarily uses local session/config state
- Codex CLI primarily uses local login/session state
- Gemini CLI primarily uses `~/.gemini/oauth_creds.json`
- DeepSeek uses `DEEPSEEK_API_KEY`
- GitHub uses `GH_TOKEN` / `GITHUB_TOKEN`

On this workstation, `fnox` currently exposes `ANTHROPIC_API_KEY` and
`GITHUB_TOKEN`, but not `DEEPSEEK_API_KEY`, `OPENAI_API_KEY`, or
`GEMINI_API_KEY`. That means the missing operational prerequisite for the first
eval batch is DeepSeek access, not a flake syntax issue.

### Local Path Input
`unified-nix-configuration` had already been switched to a local path input:

```nix
agent-roundtable = {
  url = "path:/home/deepwatrcreatur/flakes/agent-roundtable/roundtable";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

## Changes Made

1. Updated `roundtable/README.md` to describe the real provider auth model.
2. Updated `roundtable/flake.nix` shell output so it no longer claims Codex and
   Gemini require direct API-key env vars.
3. Closed this item with corrected findings.

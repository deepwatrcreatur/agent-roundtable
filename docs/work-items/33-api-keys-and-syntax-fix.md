# 33 — Fix Syntax Error and Missing API Keys

**Status:** `in-progress` (Codex)
**Assigned:** Codex

## Scope

1. Fix syntax error in `roundtable/flake.nix` (it currently has a `:` instead of `=` on line 2 in the remote repository).
2. Identify and document missing API keys required for full evaluation.
3. Switch `unified-nix-configuration` to use local path for `agent-roundtable` for development/testing.

## Findings

### Syntax Error
The remote repository `github:deepwatrcreatur/agent-roundtable` appears to have a syntax error on line 2 of `roundtable/flake.nix`.
```nix
description: "Roundtable - Autonomous multi-agent design orchestrator";
```
Should be:
```nix
description = "Roundtable - Autonomous multi-agent design orchestrator";
```

### Missing API Keys
Based on `unified-nix-configuration/secrets-agenix/`, the following keys are missing:
- `openai-api-key.age` (for Codex)
- `gemini-api-key.age` (for Gemini-CLI)

The following keys are present:
- `anthropic-api-key.age` (for Claude-Code)
- `deepseek-api-key.age` (for DeepSeek)
- `github-token.age` (for GitHub interactions)

## Implementation Plan

1. Verify and fix `roundtable/flake.nix` locally.
2. Update `unified-nix-configuration/flake.nix` to point `agent-roundtable` input to `path:../agent-roundtable/roundtable`.
3. Inform the user about the missing keys.

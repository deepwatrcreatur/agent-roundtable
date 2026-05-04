# 34 — JJ/Jujutsu Core Integration

## Status: `ready`

## Objective
Add core support for the `jj` (Jujutsu) version control system to the orchestrator, enabling first-class conflicts and Change-ID based tracking.

## Rationale
Standard Git-only semantics treat conflicts as errors. `jj` treats them as first-class versioned objects, which perfectly mirrors our "Fork with Objections" deliberative protocol. Adopting `jj` is also a prerequisite for significant token efficiency gains.

## Requirements
- [ ] Add `jj` to the project `flake.nix` devShell and NixOS module path.
- [ ] Implement `Roundtable.Vcs.Jujutsu` adapter (paralleling the existing Git logic).
- [ ] Support `jj` Change-ID extraction and stable tracking across rebases.
- [ ] Implement "Conflict Detection" logic that surfaces logical deliberative conflicts as versioned objects rather than system errors.

## Verification
- [ ] Unit tests for `Roundtable.Vcs.Jujutsu` using a temporary directory.
- [ ] Assert that a `jj` conflict state can be pushed and recorded in the orchestrator's state.
- [ ] Verify that Change-IDs remain stable after a `jj rebase`.

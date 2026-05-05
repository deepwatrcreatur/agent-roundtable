# 58 — Portable LXC & NixOS Modules

**Status:** `ready`
**Tag:** `[structural]`

## Goal
Decouple Vaglio from `unified-nix-configuration` to allow standalone deployment.

## Scope
- Extract the Vaglio LXC container definition and NixOS modules.
- Place them in `/nix/modules` within the `vaglio` repo.
- Configure a standalone `flake.nix` that exports the Vaglio service profile.
- Enable both WebUI and OpenCode/TUI services by default in this profile.

## Acceptance Criteria
- Users can run `nixos-rebuild --flake .#vaglio` to stand up the service.
- No dependencies on private external repositories.

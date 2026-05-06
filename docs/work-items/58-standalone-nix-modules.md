# 58 — Portable LXC & NixOS Modules

**Status:** `done`
**Tag:** `[structural]`

## Goal
Decouple Vaglio from `unified-nix-configuration` to allow standalone deployment.

## Scope
- Extract the Vaglio LXC container definition and NixOS modules.
- Place them in `/nix/modules` within the `vaglio` repo.
- Configure a standalone `flake.nix` that exports the Vaglio service profile.
- Enable the WebUI plus a CLI/TUI-capable maintainer toolchain by default in this profile.

## Acceptance Criteria
- Users can run `nixos-rebuild --flake .#vaglio` to stand up the service.
- No dependencies on private external repositories.

## Implementation notes

- The standalone service module now lives in `nix/modules/services/roundtable.nix`.
- The standalone LXC profile now lives in `nix/modules/profiles/vaglio-lxc.nix`.
- The root `flake.nix` exports:
  - `nixosModules.roundtable`
  - `nixosModules.vaglio-lxc`
  - `nixosConfigurations.vaglio`
- `SECRET_KEY_BASE` is auto-generated if no file is supplied.
- API keys and GitHub token are optional, not mandatory.
- The profile installs local workflow tools (`roundtable`, `tmux`, `gh`, `git`, `dolt`, `jj`) by default.
- The richer OpenCode/dmux TUI remains separate work under items 53 and 54.

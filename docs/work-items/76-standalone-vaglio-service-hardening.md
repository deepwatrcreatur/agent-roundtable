# 76 — Standalone Vaglio Service Hardening

Status: `done`
Suggested branch: `fix/standalone-vaglio-service-hardening`
Deployment target: `vaglio`
Deployment coordination: `exclusive single-writer host lock while live deploy work is active`

## Goal

Fix the standalone `#vaglio` deployment profile so `roundtable.service` starts
cleanly on a fresh host without any runtime-only systemd overrides.

## Why

A fresh `nixos-rebuild switch --flake .#vaglio` on the real `vaglio` LXC host
currently exposes two service bugs:

- the generated startup script assumes `CREDENTIALS_DIRECTORY` always exists
  under `set -u`
- the packaged `roundtable-web` wrapper runs Mix from a read-only
  `/nix/store` source tree, which causes Hex dependency setup to fail with
  `{:error, :erofs}`

A temporary runtime override on the live host works around this by running from
`/root/flakes/agent-roundtable/roundtable`, but that fix disappears on reboot
and does not belong in host-local state.

## Scope

- Make the systemd startup path safe when no credentials are configured.
- Remove the read-only source-tree assumption from the standalone runtime path.
- Ensure the default standalone profile can boot the web service from a clean
  host with only the flake checkout and Nix.
- Preserve the existing optional-secret behavior for GitHub/OIDC/API-key flows.

## Acceptance Criteria

- `nixos-rebuild switch --flake .#vaglio` activates the Roundtable service path on
  a clean LXC host. The remaining non-zero exit is from Proxmox LXC
  `sys-kernel-debug.mount`, not from the Roundtable service itself.
- `systemctl status roundtable` is `active (running)` without any runtime-only
  override in `/run/systemd/system/roundtable.service.d/`.
- `curl -I http://127.0.0.1:4000` returns `200 OK`.
- No Hex/Mix writes target `/nix/store` during service startup.

## Outcome

Completed on May 13, 2026.

- The service startup script now treats `CREDENTIALS_DIRECTORY` as optional.
- The standalone wrapper now copies the project into writable runtime state
  before running Mix, so Hex/deps/build writes stay out of `/nix/store`.
- The `vaglio` profile now serves with
  `PHX_HOST=roundtable.deepwatercreature.com`, which fixes LiveView websocket
  origin checks for the public host.
- The standalone production config no longer sets `cache_static_manifest`.
  A non-blocking Phoenix static warmup warning is still observed at startup and
  should be handled separately from this deployment hardening item.
- The live host no longer depends on a runtime override under
  `/run/systemd/system/roundtable.service.d/`.
## Notes

Observed on the real `vaglio` host on May 10, 2026:

- `roundtable.service` initially failed with:
  - `CREDENTIALS_DIRECTORY: unbound variable`
  - `{:error, :erofs}` during Hex dependency unpack
- A host-local override proved the app can run when:
  - the credential directory is treated as optional
  - the service launches from a writable checkout instead of the packaged
    read-only source path
- Coordination note:
  - single-writer discipline on `vaglio` should apply to live mutating actions
    such as rebuilds, restarts, or runtime warmup against the running host
  - parallel branch work and unrelated code changes should not be blocked by that
    live-host mutation boundary

# 76 — Standalone Vaglio Service Hardening

Status: `done`
Suggested branch: `fix/standalone-vaglio-service-hardening`
Deployment target: `vaglio`
Deployment coordination: `exclusive single-writer live-resource mutation lock while live deploy work is active`

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
Operational note from May 14, 2026:

- `vaglio` is a single-writer deployment target for this item.
- Parallel agent rebuilds/restarts on the same CT can race in `/var/lib/roundtable`
  and leave `roundtable.service` or the cache-prewarm service in a broken state.
- Any agent touching this item should pause before live deployment if another
  agent session is already rebuilding or restarting services on `vaglio`.
- This does not block parallel code work on other branches; it only blocks
  overlapping live deploy actions against the same host.

Recommended read-only lock check before any live deploy:

```bash
./scripts/vaglio-readonly-preflight.sh
nix run .#vaglio-readonly-preflight
```

If that output shows an active rebuild, switch, or another agent-owned service
operation, stop and hand off instead of attempting a second live deploy.

Recommended post-deploy smoke check:

```bash
./scripts/vaglio-post-deploy-smoke.sh
nix run .#vaglio-post-deploy-smoke
```

Branch status on PR `#88` as of May 15, 2026:

- runtime source refresh is keyed to the copied flake source path instead of a
  generic `"dirty"` marker
- wrapper setup now uses an explicit setup lock and atomic source replacement
- `roundtable-web` and prewarm now use separate runtime roots, deps, and build
  paths
- the prewarm wrapper routes arguments through the Mix task parser instead of
  passing raw CLI args directly into `PublicRepoDemo.prewarm/2`
- dependency bootstrap is gated on source changes instead of running on every
  invocation
- Hex/Rebar bootstrap is skipped after the first successful runtime setup
- `ROUNDTABLE_RUNTIME_NAMESPACE` is pinned explicitly in the systemd unit
  environments
- `cache_static_manifest` was removed from prod config to eliminate a misleading
  missing-manifest startup warning
- the prewarm Mix task now has a regression test that verifies flags like
  `--timeout-ms` do not get treated as demo IDs
- the read-only preflight and post-deploy smoke helpers are exposed as flake
  apps and covered by a flake check build path

Deployment outcome on the real `vaglio` host as of May 21, 2026:

- `roundtable.service` is active on the standalone `vaglio` LXC host without
  runtime-only systemd drop-ins
- `/forgejo-shell` serves from the deployed standalone flake profile
- `roundtable-prewarm-public-repo-cache.service` now completes successfully
- cached snapshot artifacts exist under
  `/var/lib/roundtable/state/public-repo-cache/`
- sampled evidence sections are live for at least:
  - `forgejo`
  - `kubernetes`

Additional fixes that were required during rollout:

- the prewarm oneshot service no longer asks systemd to manage the same
  state directory twice
- wrapper setup locks are now released before the wrapper `exec`s into the
  long-running command, so successful runs do not leave stale lock dirs behind

Residual limitation moved out of this item:

- `nixpkgs` still times out during cache prewarm and falls back to the lighter
  page variant without sampled evidence sections
- follow-up: `77-large-demo-prewarm-scaling.md`

Current owner: `Codex`

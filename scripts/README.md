# Vaglio Helper Scripts

These scripts are read-only operator helpers for the shared `vaglio` host.

## Scripts

- `./scripts/vaglio-readonly-preflight.sh`
  - also available as `nix run .#vaglio-readonly-preflight`
  - run before any live deploy
  - checks CT status, service state, active rebuild/restart processes, and
    wrapper runtime markers
- `./scripts/vaglio-post-deploy-smoke.sh`
  - also available as `nix run .#vaglio-post-deploy-smoke`
  - run after a live deploy
  - checks service state, port `4000`, cache directory visibility, the public
    `/forgejo-shell` route, and demo markers for `?demo=kubernetes`

## Coordination

- These scripts do not modify the host.
- They exist to support the single-writer deployment rule for `vaglio`.
- Parallel branch work is still fine; only overlapping live deploy actions on
  the same host need serialization.

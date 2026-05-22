# 77 — Large Demo Prewarm Scaling

Status: `done`
Suggested branch: `fix/large-demo-prewarm-scaling`
Deployment target: `vaglio`
Deployment coordination: `exclusive single-writer live-resource mutation lock while live deploy work is active`

## Goal

Make large public demo repos, especially `nixpkgs`, warm and serve sampled
evidence reliably without timing out during the standalone `vaglio` prewarm
cycle.

## Why

The standalone deployment is now healthy, but the prewarm service still times
out on `nixpkgs` while successfully warming smaller demos like `forgejo` and
`kubernetes`.

As of May 21, 2026:

- `roundtable.service` is healthy on `vaglio`
- `roundtable-prewarm-public-repo-cache.service` exits successfully
- cache files are present for:
  - `forgejo`
  - `kubernetes`
- the prewarm journal still reports:
  - `failed to warm nixpkgs: :timeout`

That means the deployment problem is solved, but the public demo surface still
degrades on the largest curated repo.

## Scope

- Profile why `nixpkgs` exceeds the current `--timeout-ms 30000` prewarm budget.
- Decide whether the right fix is:
  - a longer per-demo timeout
  - different sampling limits for very large repos
  - cheaper snapshot derivation for the prewarm path
  - or a split between foreground demo load and background cache warm
- Preserve the current success path for `forgejo` and `kubernetes`.
- Keep the deployment coordination rule: one live deploy actor on `vaglio` at a
  time.

## Acceptance Criteria

- `roundtable-prewarm-public-repo-cache.service` warms `nixpkgs` without timing
  out on `vaglio`
- a cache artifact for `nixpkgs` exists under
  `/var/lib/roundtable/state/public-repo-cache/`
- `/forgejo-shell?demo=nixpkgs` shows sampled evidence sections, not only the
  fallback summary surface
- `forgejo` and `kubernetes` still warm successfully

## Notes

The deployment hardening that made the standalone host stable now lives in
`76-standalone-vaglio-service-hardening.md`. This item is intentionally about
performance/scale, not service boot correctness.

Outcome on `vaglio` as of May 21, 2026:

- `roundtable-prewarm-public-repo-cache.service` now warms all three demos:
  - `forgejo`
  - `kubernetes`
  - `nixpkgs`
- `nixpkgs.term` now exists under
  `/var/lib/roundtable/state/public-repo-cache/`
- `/forgejo-shell?demo=nixpkgs` now shows the sampled evidence sections instead
  of the fallback-only surface

Implementation notes:

- `nixpkgs` now carries a repo-specific sampling profile
- the prewarm timeout budget honors a larger per-demo floor only when a demo
  explicitly asks for one
- `nixpkgs` now uses a lighter sample shape during prewarm:
  - lower `sample_depth`
  - fewer recent commits
  - fewer path-log entries

Current owner: `Codex`

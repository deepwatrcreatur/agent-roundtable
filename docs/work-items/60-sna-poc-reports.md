# 60 — Public Repo SNA Reports (PoC)

**Status:** `done` — **Owner:** `Codex`
**Tag:** `[market]`

## Goal
Demonstrate Vaglio's value by producing Social Network Analysis (SNA) reports on high-profile public repositories.

## Scope
- Select 3 public repos (e.g., NixOS, Hyprland, Elixir).
- Use the Vaglio SNA Engine to analyze contributor expertise and "Vouch" patterns.
- Generate a `/reports` directory in the repo.
- Include agent-generated screenshots and striking useful observations about hidden maintenance bottlenecks.

## Acceptance Criteria
- Reports are high-signal and formatted for social media outreach.
- Striking visualizations of the "Project Mind" for public codebases.

## Notes

- Primary artifact surface:
  - `reports/public-repo-sna/README.md`
- Closely related work:
  - `68-public-repo-investor-demo.md`
  - `71-forgejo-shell-shareable-web-entry.md`
  - `72-forgejo-shell-public-demo-polish.md`

## Outcome

- Added shareable markdown SNA report artifacts under `reports/public-repo-sna/`
  for:
  - `forgejo/forgejo`
  - `kubernetes/kubernetes`
  - `NixOS/nixpkgs`
- Added paired machine-readable snapshot exports under
  `reports/public-repo-demos/`.
- The checked-in reports are derived from the same public-repo snapshot flow
  used by `/forgejo-shell` and `/forgejo-shell/reports`, so the public demo and
  repo-local outreach artifacts stay aligned.

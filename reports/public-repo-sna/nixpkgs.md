# NixOS/nixpkgs — Project Mind Report

> Generated 2026-05-22T13:33:18.110355Z

Operational complexity with concentrated review bottlenecks.

## Executive Summary

Vaglio highlights which maintainers absorb the coordination load, where routing and platform changes pile up, and how much of the rollout reasoning is already captured versus still trapped in chat.

## Shareable Observations

- `NixOS/nixpkgs` shows `low` sampled contributor concentration, with the top three authors accounting for 30.0% of sampled commits.
- The hottest sampled path is `pkgs/by-name/ra/radicle-desktop/package.nix` with `1` mentions in the shallow branch window.
- `R. Ryantm` leads the sampled window, indicating a repeat maintainer anchor rather than flatly distributed ownership.

## Stress Surface

- Branch stress: `0.78`
- History heat: `3 peaks`
- Active-inference confidence: `medium`
- Sampled contributor concentration: `low`
- Sampled top-author share: `30.0%`

## Project Mind Heatmap

| Surface | Stress | Heat | Appraisal |
| --- | --- | --- | --- |
| router failover path | high | 0.86 | Investigate and adversarially review |
| module evaluation path | high | 0.81 | Investigate and adversarially review |
| release plumbing path | medium | 0.63 | Track and gather more evidence |
| pkgs/by-name/ra/radicle-desktop/package.nix | high | 1.0 | Investigate and adversarially review |
| pkgs/by-name/vi/visual-paradigm-ce/package.nix | high | 1.0 | Investigate and adversarially review |

## Contributor Concentration

| Author | Commits | Share |
| --- | ---: | ---: |
| R. Ryantm | 729 | 17.0% |
| nixpkgs-ci[bot] | 417 | 10.0% |
| Sandro | 129 | 3.0% |
| Fabian Affolter | 100 | 2.0% |
| Peder Bergebakken Sundt | 97 | 2.0% |

## Path Hotspots

| Path | Mentions |
| --- | ---: |
| `pkgs/by-name/ra/radicle-desktop/package.nix` | 1 |
| `pkgs/by-name/vi/visual-paradigm-ce/package.nix` | 1 |

## Recent Commit Sample

| When | Author | SHA |
| --- | --- | --- |
| 2026-05-22 | nixpkgs-ci[bot] | `c88807e0` |
| 2026-05-22 | Maximilian Bosch | `fbeb6bc8` |
| 2026-05-22 | Pol Dellaiera | `8651b537` |
| 2026-05-22 | Pol Dellaiera | `4fc0c18e` |
| 2026-05-22 | Eli Saado | `d0eb5122` |
| 2026-05-22 | Felix Bargfeldt | `647cb4a3` |
| 2026-05-22 | nixpkgs-ci[bot] | `b322daaf` |
| 2026-05-22 | Adam C. Stephens | `48296da2` |

## Maintainer Bottleneck Notes

- The strongest likely maintenance anchor in the sampled window is **R. Ryantm**, which makes continuity risk visible even before any explicit social graph is modeled.
- The hottest code surface is `pkgs/by-name/ra/radicle-desktop/package.nix`, which is a plausible place to focus future vouch-graph or review-latency instrumentation.
- This first PoC still uses sampled commit topology and concentration signals as a stand-in for a fuller vouch network; it is meant to be shareable now, not final theory-complete infrastructure.

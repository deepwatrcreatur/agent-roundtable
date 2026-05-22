# forgejo/forgejo — Project Mind Report

> Generated 2026-05-22T13:32:20.821248Z

Product dogfooding story: Forgejo shell outside, Vaglio semantics inside.

## Executive Summary

This demo makes the platform story concrete: repository browsing and account UX stay Forgejo-native while Vaglio adds semantic change tracking, provenance, and analysis surfaces beside it.

## Shareable Observations

- `forgejo/forgejo` shows `medium` sampled contributor concentration, with the top three authors accounting for 50.0% of sampled commits.
- The hottest sampled path is `options/locale_next/locale_en-US.json` with `6` mentions in the shallow branch window.
- `Renovate Bot` leads the sampled window, indicating a repeat maintainer anchor rather than flatly distributed ownership.

## Stress Surface

- Branch stress: `0.58`
- History heat: `3 peaks`
- Active-inference confidence: `medium-high`
- Sampled contributor concentration: `medium`
- Sampled top-author share: `50.0%`

## Project Mind Heatmap

| Surface | Stress | Heat | Appraisal |
| --- | --- | --- | --- |
| repository api path | high | 0.74 | Investigate and adversarially review |
| web shell path | medium | 0.61 | Track and gather more evidence |
| actions governance path | medium | 0.64 | Track and gather more evidence |
| options/locale_next/locale_en-US.json | high | 1.0 | Investigate and adversarially review |
| go.sum | medium | 0.83 | Track and gather more evidence |
| go.mod | medium | 0.83 | Track and gather more evidence |

## Contributor Concentration

| Author | Commits | Share |
| --- | ---: | ---: |
| Renovate Bot | 12 | 30.0% |
| Mathieu Fenniak | 5 | 13.0% |
| Robert Wolff | 3 | 8.0% |
| Shiny Nematoda | 3 | 8.0% |
| Gusted | 2 | 5.0% |

## Path Hotspots

| Path | Mentions |
| --- | ---: |
| `options/locale_next/locale_en-US.json` | 6 |
| `go.sum` | 5 |
| `go.mod` | 5 |
| `package-lock.json` | 4 |
| `routers/web/web.go` | 4 |
| `package.json` | 3 |
| `templates/user/settings/authorized_integrations.tmpl` | 3 |
| `tests/e2e/user-settings.test.e2e.ts` | 3 |

## Recent Commit Sample

| When | Author | SHA |
| --- | --- | --- |
| 2026-05-22 | B0sh | `e49cb9e7` |
| 2026-05-22 | hwipl | `1ea5605e` |
| 2026-05-22 | Renovate Bot | `7054075b` |
| 2026-05-22 | Renovate Bot | `ede3bbe6` |
| 2026-05-22 | Maxim Cournoyer | `8dd01fa8` |
| 2026-05-22 | Gusted | `4131cc41` |
| 2026-05-22 | Renovate Bot | `294952b7` |
| 2026-05-21 | Shiny Nematoda | `9ba57d58` |
| 2026-05-21 | guillermodotn | `93638e11` |
| 2026-05-21 | famfo | `b87dfe13` |
| 2026-05-21 | Robert Wolff | `96b31a9a` |
| 2026-05-21 | Renovate Bot | `7d0bac4b` |

## Maintainer Bottleneck Notes

- The strongest likely maintenance anchor in the sampled window is **Renovate Bot**, which makes continuity risk visible even before any explicit social graph is modeled.
- The hottest code surface is `options/locale_next/locale_en-US.json`, which is a plausible place to focus future vouch-graph or review-latency instrumentation.
- This first PoC still uses sampled commit topology and concentration signals as a stand-in for a fuller vouch network; it is meant to be shareable now, not final theory-complete infrastructure.

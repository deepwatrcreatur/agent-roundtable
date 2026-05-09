# 69 — jj vs. Git Infrastructure Benchmark

**Status:** `done`
**Tag:** `[structural]`

## Goal
Benchmark Vaglio's `jj`-native direction against Git-compatible agent infrastructure so architectural decisions are grounded in measured tradeoffs rather than taste alone.

## Scope
- Define an agent-scale workload that stresses the things Vaglio actually cares about:
  - many concurrent changes
  - ephemeral work branches / workspaces
  - conflict surfacing and recovery
  - ingest latency
  - provenance / explainability hooks
- Compare at least two paths:
  - a `jj`-native flow
  - a Git-compatible flow representative of tools like code.storage
- Measure both machine-facing and human-facing costs:
  - throughput and latency
  - operational complexity
  - ecosystem compatibility
  - how much compatibility glue Vaglio would have to own
- End with an explicit recommendation for where Vaglio should be native versus compatible.

## Acceptance Criteria
- The benchmark uses a reproducible workload instead of anecdotal impressions.
- Results make the tradeoff legible to both technical and product stakeholders.
- The outcome informs queue priority for `jj`-heavy items and any Git-compatibility layer work.

## Outcome
- Added `Roundtable.ArchitectureBenchmark` with reproducible benchmark profiles for:
  - `nixpkgs`
  - `kubernetes`
  - `forgejo`
- Each profile now defines:
  - an agent-scale workload
  - a `jj`-native path
  - a Git-compatible path
  - an explicit recommendation for what should stay native versus compatible
- Wired the benchmark into `/forgejo-shell` so the investor demo now includes:
  - workload size and provenance hooks
  - side-by-side path cards for `jj` vs Git-compatible infrastructure
  - a clear "keep native" vs "keep compatible" recommendation
- Added focused benchmark tests and extended the shell page test to cover the benchmark section.

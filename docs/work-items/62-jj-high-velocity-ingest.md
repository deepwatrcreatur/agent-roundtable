# 62 — Scalable jj Ingestion Layer

**Status:** `done` — **Owner:** `Codex`
**Tag:** `[structural]`

## Goal

Design the Vaglio site backend to handle high-velocity agent commits using `jj`
primitives.

## Scope

- Optimize `jj` colocated mode for concurrent agent ingestion.
- Implement an "Emergent Storage" layer in `Dolt` that separates low-signal
  slop from Vouched signal.
- Replace traditional webhook-based CI with a "Sieve-First" model: code is only
  tested *after* it gains initial social momentum.
- Benchmark ingestion rates for 1,000+ commits per minute.

## Acceptance Criteria

- No backend "Stall" during high-activity deliberation rounds.
- Predictable performance even with massive "Agent Velocity."

## Notes

- Primary design sources:
  - `docs/design/rounds/round-60-q60.md`
  - `docs/design/rounds/round-120-backend-substrate-vs-governance-startup-boundary.md`
- Closely related work:
  - `49-virtual-working-copies.md`
  - `57-agent-task-queue.md`
  - `79-derived-round-index-and-resource-claims.md`
  - `93-backend-adapter-and-performance-tier-contract.md`

## Outcome

- Added
  [docs/design/JJ_HIGH_VELOCITY_INGEST.md](../design/JJ_HIGH_VELOCITY_INGEST.md)
  as the ingest contract note.
- Defined the three-layer ingest split between:
  - raw agent traffic
  - vouched candidate signal
  - promotion-ready state
- Specified an Emergent Storage split so raw attempt traffic does not become the
  same durability class as governance truth.
- Defined a sieve-first admission model that defers expensive test/analysis
  spend until a change gains enough board/evidence/vouch basis.
- Turned the "1,000+ commits per minute" aspiration into a benchmark contract
  tied to board freshness, gate responsiveness, and replayability rather than
  raw write-sink throughput alone.

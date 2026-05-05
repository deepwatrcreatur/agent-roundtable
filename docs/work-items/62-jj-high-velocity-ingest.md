# 62 — Scalable jj Ingestion Layer

**Status:** `ready`
**Tag:** `[structural]`

## Goal
Design the Vaglio site backend to handle high-velocity agent commits using `jj` primitives.

## Scope
- Optimize `jj` colocated mode for concurrent agent ingestion.
- Implement an "Emergent Storage" layer in `Dolt` that separates low-signal slop from Vouched signal.
- Replace traditional webhook-based CI with a "Sieve-First" model: code is only tested *after* it gains initial social momentum.
- Benchmark ingestion rates for 1,000+ commits per minute.

## Acceptance Criteria
- No backend "Stall" during high-activity deliberation rounds.
- Predictable performance even with massive "Agent Velocity."

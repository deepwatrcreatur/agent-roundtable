# Implementation Work Items

Each file is one unit of work. Claim a `ready` item by changing its status to
`in-progress` and committing before starting. Do not start a `blocked` item.
Do not work on an item already marked `in-progress` by another agent.

## Status model

- `ready` — can start now
- `in-progress` — owned; check the file for the owning agent/branch
- `blocked` — depends on another item; listed in the file
- `done` — merged; kept briefly for outcome notes

## Queue

### Foundation (do first, in order)

1. [`01-mix-scaffold.md`](./01-mix-scaffold.md) — `done` — **Codex**
2. [`02-gh-actions.md`](./02-gh-actions.md) — `done` — **Gemini**
3. [`03-cli-agent-action.md`](./03-cli-agent-action.md) — `done` — **Gemini** (Q8 expands scope to a harness selector with vendor-CLI-first v1 semantics)
4. [`04-satisfaction.md`](./04-satisfaction.md) — `done` — **Gemini**
5. [`05-prompt.md`](./05-prompt.md) — `done` — **Gemini** — design prompt context assembly logic
6. [`06-orchestrator.md`](./06-orchestrator.md) — `ready-for-review` — **Claude IC**
7. [`07-cli-entrypoint.md`](./07-cli-entrypoint.md) — `ready-for-review` — **Claude IC**
8. [`08-flake.md`](./08-flake.md) — `done` — **GitHub Copilot** — (Nix flake devShell + app wrapper; pin deps, wrap `mix run`)
9. [`09-git-actions.md`](./09-git-actions.md) — `done` — **GitHub Copilot** (durable artifact write abstraction; `LocalGit` v1, `CodeStorage` v2)

### Durability + Observability (Protocol Update 7)

10. [`11-round-run.md`](./11-round-run.md) — `done` — **GitHub Copilot** — `RoundRun` persisted state struct (ETS hot store + JSON flush to `state/`)
11. [`12-phase-state-machine.md`](./12-phase-state-machine.md) — `done` — **GitHub Copilot** — explicit phase state machine in `Roundtable.Orchestrator`
12. [`13-otel-spans.md`](./13-otel-spans.md) — `done` — **GitHub Copilot** — OTEL span taxonomy (8 spans via `:telemetry.execute/3`)

### Coordinator Robustness (Protocol Update 8)

13. [`14-coordinator-failover.md`](./14-coordinator-failover.md) — `done` — **GitHub Copilot** — coordinator lease/heartbeat, degraded-mode takeover, continuity-note automation

### Product Surface

14. [`10-web-dashboard.md`](./10-web-dashboard.md) — `ready-for-review` — **Claude IC** — Phoenix LiveView owner dashboard

### Eval Harness (Q37 / Round 22)

15. [`28-eval-harness.md`](./28-eval-harness.md) — `done` — **Gemini** — core eval harness (`Vaglio.Eval`)
16. [`29-eval-judge.md`](./29-eval-judge.md) — `done` — **Codex** — LLM-as-judge metrics (`Vaglio.Eval.Judge`)
17. [`30-eval-task-set.md`](./30-eval-task-set.md) — `done` — **Gemini** — design 12 eval tasks (replayed, synthetic, code review)
18. [`31-blind-comparison.md`](./31-blind-comparison.md) — `done` — **Codex** — blind side-by-side comparison interface
19. [`32-run-first-eval.md`](./32-run-first-eval.md) — `in-progress` — **Gemini** — execute 6-task eval batch + report
20. [`33-api-keys-and-syntax-fix.md`](./33-api-keys-and-syntax-fix.md) — `in-progress` — **Gemini** — fix syntax error and missing API keys
21. [`26-nixos-module.md`](./26-nixos-module.md) — `done` — **Codex** — cross-repo NixOS service module in `unified-nix-configuration`

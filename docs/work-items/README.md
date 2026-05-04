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

1. [`01-mix-scaffold.md`](./01-mix-scaffold.md) — `in-progress` — **Codex**
2. [`02-gh-actions.md`](./02-gh-actions.md) — `ready-for-review` — **Gemini**
3. [`03-cli-agent-action.md`](./03-cli-agent-action.md) — `blocked` (needs 01; Q8 expands scope to a harness selector with vendor-CLI-first v1 semantics)
4. [`04-satisfaction.md`](./04-satisfaction.md) — `blocked` (needs 01)
5. [`05-prompt.md`](./05-prompt.md) — `blocked` (needs 01, 02, 03)
6. [`06-orchestrator.md`](./06-orchestrator.md) — `blocked` (needs 01–05)
7. [`07-cli-entrypoint.md`](./07-cli-entrypoint.md) — `blocked` (needs 06)
8. [`08-flake.md`](./08-flake.md) — `in-progress` — **GitHub Copilot** — (Nix flake devShell + app wrapper; pin deps, wrap `mix run`)
9. [`09-git-actions.md`](./09-git-actions.md) — `done` — **GitHub Copilot** (durable artifact write abstraction; `LocalGit` v1, `CodeStorage` v2)

### Durability + Observability (Protocol Update 7)

10. [`11-round-run.md`](./11-round-run.md) — `ready` — `RoundRun` persisted state struct (ETS hot store + JSON flush to `state/`)
11. [`12-phase-state-machine.md`](./12-phase-state-machine.md) — `blocked` (needs 11) — explicit phase state machine in `Roundtable.Orchestrator`
12. [`13-otel-spans.md`](./13-otel-spans.md) — `done` — **GitHub Copilot** — OTEL span taxonomy (8 spans via `:telemetry.execute/3`)

### Coordinator Robustness (Protocol Update 8)

13. [`14-coordinator-failover.md`](./14-coordinator-failover.md) — `blocked` (needs 11, 12, 13) — coordinator lease/heartbeat, degraded-mode takeover, continuity-note automation

### Product Surface

14. [`10-web-dashboard.md`](./10-web-dashboard.md) — `ready` — Phoenix LiveView owner dashboard

### File-Based Discussion Repo (Protocol Update 10)

15. [`15-discussion-repo-layer.md`](./15-discussion-repo-layer.md) — `ready` — DiscussionRepo abstraction & GitHub Adapter
16. [`19-orchestrator-repo-path.md`](./19-orchestrator-repo-path.md) — `ready` — Orchestrator file-based model integration
17. [`23-no-objection-marker.md`](./23-no-objection-marker.md) — `ready` — `[no objection]` satisfaction marker support
18. [`24-telegram-outbound.md`](./24-telegram-outbound.md) — `ready` — Outbound Telegram notifications
19. [`25-authentik-oidc.md`](./25-authentik-oidc.md) — `ready` — Authentik OIDC authentication
20. [`26-nixos-module.md`](./26-nixos-module.md) — `ready` — NixOS service module & deployment config

### Eval Harness (Q37 / Round 22)

21. [`28-eval-harness.md`](./28-eval-harness.md) — `ready` — core eval harness (`Vaglio.Eval`)
22. [`29-eval-judge.md`](./29-eval-judge.md) — `ready` — LLM-as-judge metrics (`Vaglio.Eval.Judge`)
23. [`30-eval-task-set.md`](./30-eval-task-set.md) — `ready` — design 12 eval tasks (replayed, synthetic, code review)
24. [`31-blind-comparison.md`](./31-blind-comparison.md) — `ready` — blind side-by-side comparison interface
25. [`32-run-first-eval.md`](./32-run-first-eval.md) — `ready` — execute 6-task eval batch + report

### Platform Evolution (JJ + Dolt + Provenance)

26. [`34-jj-core-integration.md`](./34-jj-core-integration.md) — `in-progress` — **Gemini** — JJ/Jujutsu core CLI integration
27. [`35-dolt-jj-orchestration-layer.md`](./35-dolt-jj-orchestration-layer.md) — `blocked` — Dolt-JJ orchestration shim (Jido-powered)
28. [`36-unified-conflict-dashboard.md`](./36-unified-conflict-dashboard.md) — `blocked` — Unified jj/Dolt conflict management dashboard
29. [`37-evolution-based-prompting.md`](./37-evolution-based-prompting.md) — `in-progress` — **Codex** — Evolution-based prompting (research)
30. [`38-revset-context-pruning.md`](./38-revset-context-pruning.md) — `blocked` — Revset-driven context pruning
31. [`39-deliberative-slsa.md`](./39-deliberative-slsa.md) — `in-progress` — **DeepSeek** — Deliberative SLSA (GPG-signed agent turns)
32. [`40-s3-mega-backup.md`](./40-s3-mega-backup.md) — `in-progress` — **GitHub Copilot** — S3/Mega backup strategy & automation

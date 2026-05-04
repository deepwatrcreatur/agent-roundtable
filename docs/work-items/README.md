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
3. [`03-cli-agent-action.md`](./03-cli-agent-action.md) — `done` — **Gemini**
4. [`04-satisfaction.md`](./04-satisfaction.md) — `done` — **Gemini**
5. [`05-prompt.md`](./05-prompt.md) — `done` — **Gemini**
6. [`06-orchestrator.md`](./06-orchestrator.md) — `done` — **Gemini**
7. [`07-cli-entrypoint.md`](./07-cli-entrypoint.md) — `done` — **Gemini**
8. [`08-flake.md`](./08-flake.md) — `done` — **GitHub Copilot**
9. [`09-git-actions.md`](./09-git-actions.md) — `done` — **GitHub Copilot**

### Durability + Observability (Protocol Update 7)

10. [`11-round-run.md`](./11-round-run.md) — `done` — **GitHub Copilot**
11. [`12-phase-state-machine.md`](./12-phase-state-machine.md) — `done` — **GitHub Copilot**
12. [`13-otel-spans.md`](./13-otel-spans.md) — `done` — **GitHub Copilot**

### Coordinator Robustness (Protocol Update 8)

13. [`14-coordinator-failover.md`](./14-coordinator-failover.md) — `done` — **GitHub Copilot**

### Product Surface

14. [`10-web-dashboard.md`](./10-web-dashboard.md) — `done` — **Gemini**

### File-Based Discussion Repo (Protocol Update 10)

15. [`15-discussion-repo-layer.md`](./15-discussion-repo-layer.md) — `done` — DiscussionRepo abstraction & GitHub Adapter
16. [`19-orchestrator-repo-path.md`](./19-orchestrator-repo-path.md) — `done` — Orchestrator file-based model integration
17. [`23-no-objection-marker.md`](./23-no-objection-marker.md) — `done` — `[no objection]` satisfaction marker support
18. [`24-telegram-outbound.md`](./24-telegram-outbound.md) — `done` — Outbound Telegram notifications
19. [`25-authentik-oidc.md`](./25-authentik-oidc.md) — `done` — Authentik OIDC authentication
20. [`26-nixos-module.md`](./26-nixos-module.md) — `done` — **Gemini** — NixOS service module & deployment config

### Eval Harness (Q37 / Round 22)

21. [`28-eval-harness.md`](./28-eval-harness.md) — `done` — **Gemini** — core eval harness (`Vaglio.Eval`)
22. [`29-eval-judge.md`](./29-eval-judge.md) — `done` — **Codex** — LLM-as-judge metrics (`Vaglio.Eval.Judge`)
23. [`30-eval-task-set.md`](./30-eval-task-set.md) — `done` — **Gemini** — design 12 eval tasks
24. [`31-blind-comparison.md`](./31-blind-comparison.md) — `done` — **Codex** — blind side-by-side comparison interface
25. [`32-run-first-eval.md`](./32-run-first-eval.md) — `in-progress` — **Gemini** — execute 6-task eval batch + report

### Platform Evolution (JJ + Dolt + Provenance)

26. [`34-jj-core-integration.md`](./34-jj-core-integration.md) — `done` — **Gemini** — JJ/Jujutsu core CLI integration
27. [`35-dolt-jj-orchestration-layer.md`](./35-dolt-jj-orchestration-layer.md) — `done` — **Gemini** — Dolt-JJ orchestration shim (Jido-powered)
28. [`36-unified-conflict-dashboard.md`](./36-unified-conflict-dashboard.md) — `done` — **Gemini** — Unified jj/Dolt conflict management dashboard
29. [`37-evolution-based-prompting.md`](./37-evolution-based-prompting.md) — `done` — **Codex** — Evolution-based prompting
30. [`38-revset-context-pruning.md`](./38-revset-context-pruning.md) — `done` — **Gemini** — Revset-driven context pruning
31. [`39-deliberative-slsa.md`](./39-deliberative-slsa.md) — `in-progress` — **DeepSeek** — Deliberative SLSA (GPG-signed agent turns)
32. [`40-s3-mega-backup.md`](./40-s3-mega-backup.md) — `in-progress` — **GitHub Copilot** — S3/Mega backup strategy & automation

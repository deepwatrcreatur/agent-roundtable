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
31. [`31-blind-comparison.md`](./31-blind-comparison.md) — `done` — **Codex** — blind side-by-side comparison interface
32. [`32-run-first-eval.md`](./32-run-first-eval.md) — `in-progress` — **Gemini** — execute 6-task eval batch + report

### Epistemic Integrity & WebUI (Protocol 15)

33. [`41-integrity-scorecard.md`](./41-integrity-scorecard.md) — `ready` — Sycophancy & Integrity Dashboard
34. [`42-robustness-meter.md`](./42-robustness-meter.md) — `ready` — Consensus Robustness Meter
35. [`43-red-team-highlights.md`](./43-red-team-highlights.md) — `done` — **Codex** — Adversarial Turn UI
36. [`44-provenance-visualization.md`](./44-provenance-visualization.md) — `done` — **Codex** — Claim Basis & Provenance Badging
37. [`45-vouch-anchoring.md`](./45-vouch-anchoring.md) — `ready` — Human Vouch Anchoring
38. [`46-dolt-tag-schema.md`](./46-dolt-tag-schema.md) — `ready` — Multidimensional Tagging Schema (Dolt + jj)
39. [`47-tag-based-context-pruning.md`](./47-tag-based-context-pruning.md) — `ready` — Tag-Based Context Pruning
40. [`48-prediction-error-heatmap.md`](./48-prediction-error-heatmap.md) — `ready` — Prediction Error Heatmap (System Stress UI)

### Infrastructure & Operations (Tagged Rounds 48-51)

41. [`49-virtual-working-copies.md`](./49-virtual-working-copies.md) — `ready` — `[structural]` Virtual Working Copies (jj)
42. [`50-hybrid-cloud.md`](./50-hybrid-cloud.md) — `ready` — `[hosting]` Hybrid Cloud Deployment (Railway)
43. [`51-proxy-and-cache.md`](./51-proxy-and-cache.md) — `ready` — `[tools]` Agent-Proxy & Cache (OpenRouter + LiteLLM)
44. [`52-selective-research.md`](./52-selective-research.md) — `ready` — `[tools]` Selective Web Research (Browserbase)

### Local TUI & Subscription Optimization (Round 53)

45. [`53-opencode-fork-rpc.md`](./53-opencode-fork-rpc.md) — `ready` — `[structural]` OpenCode Vaglio Proxy (Local RPC)
46. [`54-dmux-vaglio-tui.md`](./54-dmux-vaglio-tui.md) — `ready` — `[tools]` Vaglio TUI (dmux Integration)
47. [`55-local-subscription-harness.md`](./55-local-subscription-harness.md) — `ready` — `[tools]` Local Subscription Harness Verification

### Workflow & Task Delegation (Round 54)

48. [`56-embedded-design-merge.md`](./56-embedded-design-merge.md) — `ready` — `[structural]` Design History Integration (Embedded Model)
49. [`57-agent-task-queue.md`](./57-agent-task-queue.md) — `ready` — `[structural]` Autonomous Agent Task Delegation System

### Distribution, Testing & PoC (Round 55-57)

50. [`58-standalone-nix-modules.md`](./58-standalone-nix-modules.md) — `done` — `[structural]` Portable LXC & NixOS Modules
51. [`59-test-sandbox-repo.md`](./59-test-sandbox-repo.md) — `ready` — `[tools]` Isolated Testing Sandbox
52. [`60-sna-poc-reports.md`](./60-sna-poc-reports.md) — `ready` — `[market]` Public Repo SNA Reports (PoC)

### Integrity & Scaling (Round 58-59)

53. [`61-slsa-attestation-hooks.md`](./61-slsa-attestation-hooks.md) — `ready` — `[integrity]` SLSA-Signed Integrity Hooks
54. [`62-jj-high-velocity-ingest.md`](./62-jj-high-velocity-ingest.md) — `ready` — `[structural]` Scalable jj Ingestion Layer

### Platform Evolution (JJ + Dolt + Provenance)


26. [`34-jj-core-integration.md`](./34-jj-core-integration.md) — `done` — **Gemini** — JJ/Jujutsu core CLI integration
27. [`35-dolt-jj-orchestration-layer.md`](./35-dolt-jj-orchestration-layer.md) — `done` — **Gemini** — Dolt-JJ orchestration shim (Jido-powered)
28. [`36-unified-conflict-dashboard.md`](./36-unified-conflict-dashboard.md) — `done` — **Gemini** — Unified jj/Dolt conflict management dashboard
29. [`37-evolution-based-prompting.md`](./37-evolution-based-prompting.md) — `done` — **Codex** — Evolution-based prompting
30. [`38-revset-context-pruning.md`](./38-revset-context-pruning.md) — `done` — **Gemini** — Revset-driven context pruning
31. [`39-deliberative-slsa.md`](./39-deliberative-slsa.md) — `in-progress` — **DeepSeek** — Deliberative SLSA (GPG-signed agent turns)
32. [`40-s3-mega-backup.md`](./40-s3-mega-backup.md) — `in-progress` — **GitHub Copilot** — S3/Mega backup strategy & automation

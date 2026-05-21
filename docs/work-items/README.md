# Implementation Work Items

Each file is one unit of work. Claim a `ready` item by changing its status to
`in-progress` and committing before starting. Do not start a `blocked` item.
Do not work on an item already marked `in-progress` by another agent.

## Live Host Coordination

- Treat each live deployment target as a single-writer resource.
- If an item deploys to `vaglio` or changes its live services, record that in
  the item file and treat that host as exclusively owned until the deploy step
  is finished or explicitly handed off.
- Do not run parallel deploys, rebuilds, `systemctl restart`, or cache-warming
  jobs against the same host from different agent sessions.
- If a host-scoped item is already `in-progress`, assume its deployment target
  is locked even if the code changes look unrelated.
- This lock applies to live host actions, not to repo work in general.
  Parallel branch work, including unrelated areas such as DBus integration, is
  still encouraged when it does not operate on the same deployment target.

## Status model

- `ready` — can start now
- `in-progress` — owned; check the file for the owning agent/branch
- `blocked` — depends on another item; listed in the file
- `done` — merged; kept briefly for outcome notes

## Concurrency rule

- Parallel branch work remains encouraged.
- Read-only inspection of shared resources remains allowed unless a specific
  target is unusually fragile or rate-limited.
- Single-writer discipline applies only to **mutating actions on the same live
  resource** such as deploys, rebuilds, restarts, migrations, failover drills,
  or cache-warming against a shared target.
- Do not treat a live-resource lock as a general ban on all work related to that
  repo or host.

## Queue

84. [`82-hosted-analysis-provider-contract.md`](./82-hosted-analysis-provider-contract.md) — `ready` — `[product]` Hosted analysis provider contract
85. [`83-hosted-analysis-release-gate.md`](./83-hosted-analysis-release-gate.md) — `ready` — `[integrity]` Hosted analysis release gate
86. [`84-release-event-and-publish-authority-separation.md`](./84-release-event-and-publish-authority-separation.md) — `ready` — `[integrity]` Release event and publish authority separation
87. [`85-package-quarantine-and-revocation-graph.md`](./85-package-quarantine-and-revocation-graph.md) — `ready` — `[security]` Package quarantine and revocation graph
88. [`86-untrusted-contribution-trust-tiers.md`](./86-untrusted-contribution-trust-tiers.md) — `ready` — `[security]` Untrusted contribution trust tiers
89. [`87-safe-default-cache-trust-boundaries.md`](./87-safe-default-cache-trust-boundaries.md) — `ready` — `[security]` Safe-by-default cache trust boundaries
90. [`88-zero-config-trusted-publishing-ux.md`](./88-zero-config-trusted-publishing-ux.md) — `ready` — `[product]` Zero-config trusted publishing UX
91. [`89-forge-claim-and-lease-protocol.md`](./89-forge-claim-and-lease-protocol.md) — `ready` — `[structural]` Forge claim and lease protocol
92. [`90-agent-capability-and-promotion-boundaries.md`](./90-agent-capability-and-promotion-boundaries.md) — `ready` — `[security]` Agent capability and promotion boundaries
93. [`91-maintainer-activity-and-promotion-surface.md`](./91-maintainer-activity-and-promotion-surface.md) — `ready` — `[product]` Maintainer activity and promotion surface
94. [`92-canonical-governance-object-model.md`](./92-canonical-governance-object-model.md) — `ready` — `[structural]` Canonical governance object model
95. [`93-backend-adapter-and-performance-tier-contract.md`](./93-backend-adapter-and-performance-tier-contract.md) — `ready` — `[hosting]` Backend adapter and performance-tier contract
96. [`94-governance-state-export-and-backend-migration.md`](./94-governance-state-export-and-backend-migration.md) — `ready` — `[integrity]` Governance state export and backend migration
97. [`95-buildkite-compatible-controlled-executor.md`](./95-buildkite-compatible-controlled-executor.md) — `ready` — `[tools]` Buildkite-compatible controlled executor
98. [`96-board-kanban-read-model.md`](./96-board-kanban-read-model.md) — `ready` — `[structural]` Board kanban read model
99. [`97-browseable-board-surface.md`](./97-browseable-board-surface.md) — `ready` — `[product]` Browseable board surface

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
19. [`25-authentik-oidc.md`](./25-authentik-oidc.md) — `in-progress` — **Codex** — Authentik OIDC authentication
20. [`26-nixos-module.md`](./26-nixos-module.md) — `done` — **Gemini** — NixOS service module & deployment config

### Eval Harness (Q37 / Round 22)

21. [`28-eval-harness.md`](./28-eval-harness.md) — `done` — **Gemini** — core eval harness (`Vaglio.Eval`)
22. [`29-eval-judge.md`](./29-eval-judge.md) — `done` — **Codex** — LLM-as-judge metrics (`Vaglio.Eval.Judge`)
23. [`30-eval-task-set.md`](./30-eval-task-set.md) — `done` — **Gemini** — design 12 eval tasks
31. [`31-blind-comparison.md`](./31-blind-comparison.md) — `done` — **Codex** — blind side-by-side comparison interface
32. [`32-run-first-eval.md`](./32-run-first-eval.md) — `in-progress` — **Gemini** — execute 6-task eval batch + report

### Epistemic Integrity & WebUI (Protocol 15)

33. [`41-integrity-scorecard.md`](./41-integrity-scorecard.md) — `done` — **GitHub Copilot** — Sycophancy & Integrity Dashboard
34. [`42-robustness-meter.md`](./42-robustness-meter.md) — `done` — **GitHub Copilot** — Consensus Robustness Meter
35. [`43-red-team-highlights.md`](./43-red-team-highlights.md) — `done` — **GitHub Copilot** — Adversarial Turn UI
36. [`44-provenance-visualization.md`](./44-provenance-visualization.md) — `done` — **GitHub Copilot** — Claim Basis & Provenance Badging
37. [`45-vouch-anchoring.md`](./45-vouch-anchoring.md) — `done` — **GitHub Copilot** — Human Vouch Anchoring
38. [`46-dolt-tag-schema.md`](./46-dolt-tag-schema.md) — `done` — **Gemini** — Multidimensional Tagging Schema (Dolt + jj)
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

### Board Execution Contracts (Round 70)

50. [`73-board-work-item-schema.md`](./73-board-work-item-schema.md) — `done` — **GitHub Copilot** — `[structural]` Bulletin Board Work-Item Schema & Dolt Tables
51. [`74-local-daemon-lease-contract.md`](./74-local-daemon-lease-contract.md) — `done` — **GitHub Copilot** — `[tools]` Local Daemon Lease, Heartbeat, and Event Contract
52. [`75-lightweight-workflow-definitions.md`](./75-lightweight-workflow-definitions.md) — `done` — **GitHub Copilot** — `[structural]` Lightweight Workflow Definitions for Board Tasks

### Distribution, Testing & PoC (Round 55-57)

53. [`58-standalone-nix-modules.md`](./58-standalone-nix-modules.md) — `done` — `[structural]` Portable LXC & NixOS Modules
54. [`59-test-sandbox-repo.md`](./59-test-sandbox-repo.md) — `in-progress` — **Gemini** — Isolated Testing Sandbox
55. [`60-sna-poc-reports.md`](./60-sna-poc-reports.md) — `ready` — `[market]` Public Repo SNA Reports (PoC)

### Integrity & Scaling (Round 58-59)

56. [`61-slsa-attestation-hooks.md`](./61-slsa-attestation-hooks.md) — `ready` — `[integrity]` SLSA-Signed Integrity Hooks
57. [`62-jj-high-velocity-ingest.md`](./62-jj-high-velocity-ingest.md) — `ready` — `[structural]` Scalable jj Ingestion Layer

### Platform Evolution (JJ + Dolt + Provenance)


26. [`34-jj-core-integration.md`](./34-jj-core-integration.md) — `done` — **Gemini** — JJ/Jujutsu core CLI integration
27. [`35-dolt-jj-orchestration-layer.md`](./35-dolt-jj-orchestration-layer.md) — `done` — **Gemini** — Dolt-JJ orchestration shim (Jido-powered)
28. [`36-unified-conflict-dashboard.md`](./36-unified-conflict-dashboard.md) — `done` — **Gemini** — Unified jj/Dolt conflict management dashboard
29. [`37-evolution-based-prompting.md`](./37-evolution-based-prompting.md) — `done` — **Codex** — Evolution-based prompting
30. [`38-revset-context-pruning.md`](./38-revset-context-pruning.md) — `done` — **Gemini** — Revset-driven context pruning
31. [`39-deliberative-slsa.md`](./39-deliberative-slsa.md) — `in-progress` — **DeepSeek** — Deliberative SLSA (GPG-signed agent turns)
32. [`40-s3-mega-backup.md`](./40-s3-mega-backup.md) — `in-progress` — **GitHub Copilot** — S3/Mega backup strategy & automation

### Code Server Prototype (Forgejo + jj)

58. [`66-forgejo-code-server-shell.md`](./66-forgejo-code-server-shell.md) — `done` — `[product]` Forgejo-based code server shell
59. [`67-git-jj-translation-gateway.md`](./67-git-jj-translation-gateway.md) — `done` — `[structural]` Git ↔ jj translation gateway
60. [`68-public-repo-investor-demo.md`](./68-public-repo-investor-demo.md) — `done` — `[market]` Public repo import & investor demo
61. [`69-jj-vs-git-infra-benchmark.md`](./69-jj-vs-git-infra-benchmark.md) — `done` — `[structural]` jj vs. Git infrastructure benchmark
62. [`70-forgejo-discussion-repo-backend.md`](./70-forgejo-discussion-repo-backend.md) — `done` — `[product]` Forgejo DiscussionRepo backend

### Shareable Web Demo Surface

63. [`71-forgejo-shell-shareable-web-entry.md`](./71-forgejo-shell-shareable-web-entry.md) — `done` — **Codex** — `[product]` Forgejo shell shareable web entry
64. [`72-forgejo-shell-public-demo-polish.md`](./72-forgejo-shell-public-demo-polish.md) — `done` — **Codex** — `[market]` Forgejo shell public demo polish
65. [`76-standalone-vaglio-service-hardening.md`](./76-standalone-vaglio-service-hardening.md) — `done` — **Codex** — `[hosting]` Standalone Vaglio service hardening

### Prediction Calibration & Resource Coordination (Rounds 87-88)

66. [`77-jj-prediction-calibration-protocol.md`](./77-jj-prediction-calibration-protocol.md) — `ready` — `[integrity]` `jj` prediction metadata and outcome-linked calibration
67. [`78-resource-contention-and-single-writer-policy.md`](./78-resource-contention-and-single-writer-policy.md) — `ready` — `[structural]` Resource classes and live mutation single-writer policy

### Canonical Markdown + Derived Structure (Round 89)

68. [`79-derived-round-index-and-resource-claims.md`](./79-derived-round-index-and-resource-claims.md) — `ready` — `[structural]` Derived round metadata index and board resource-claim fields

### Sourcegraph Complementarity (Round 90)

69. [`80-sourcegraph-lineage-integration-briefs.md`](./80-sourcegraph-lineage-integration-briefs.md) — `done` — `[product]` Sourcegraph MCP/API integration for lineage briefs and outcome links
70. [`81-sourcegraph-thin-adapter-implementation.md`](./81-sourcegraph-thin-adapter-implementation.md) — `ready` — `[tools]` First thin Sourcegraph adapter and normalized evidence flow

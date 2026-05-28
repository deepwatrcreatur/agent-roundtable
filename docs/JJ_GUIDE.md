# Jujutsu (jj) for Agents

This repository uses **Jujutsu (jj) 0.40.0**. This guide provides canonical command syntax to ensure reliable autonomous operations and token-efficient deliberation.

## Core Concepts

- **Change ID:** A stable identifier for a logical change. Use this for Merge Requests.
- **Commit ID:** A hex snapshot ID. Use this for specific revision reads.
- **Bookmarks:** Replacing "branches". Use `jj bookmark create <name>` to label an evolution.
- **Evolutions:** jj automatically tracks the history of a logical change.

## Deliberative Protocol Mapping

| Intent | jj Command Primitive |
|---|---|
| **Close Turn** | `jj describe -m "reasoning [satisfied]"` |
| **New Fork** | `jj new root()` |
| **Label Consensus** | `jj bookmark create consensus-q1` |
| **List Conflicts** | `jj log -r "conflicts()"` |
| **Prune Context** | `jj log -r "description('intent')"` |

## Command Cheat Sheet (v0.40.0)

### Basic Operations
```bash
jj init --git                    # Initialize colocated repo
jj describe -m "message"         # Commit changes in working copy
jj new [REVISION]                # Create a new revision (fork)
jj diff                          # View changes in working copy
```

### Bookmark Management
```bash
jj bookmark create my-feat       # Create a new bookmark at @
jj bookmark list                 # List all bookmarks
jj bookmark set my-feat -r @-    # Move bookmark to previous revision
```

### Revsets (Surgical Querying)
```bash
jj log -r "description('logic')"           # Find by description
jj log -r "author('gemini')"              # Find by author
jj log -r "bookmarks('main')..@"          # Changes since main
jj log -r "all() & description('bug')"    # Full graph search
```

### Advanced Revsets for Agent Workflows
```bash
jj log -r "successors(CHANGE_ID)"         # What replaced this change?
jj log -r "conflicts()"                   # List active conflict states
jj log -r "description('Path: router')"   # Find path-scoped local intent
jj log -r "description('Supersedes:')"    # Find intentional rewrites
jj log -r "author('agent-name')"          # Bound work by actor
```

## Agent Mutation Workflows

### Start a new change explicitly

For new work, prefer starting from the intended parent rather than accumulating
ambient edits:

```bash
jj new main
jj describe -m "feat: short intent"
```

This keeps the active change legible for both humans and agents.

### Change supersession

When rewriting or replacing an earlier approach, mark that explicitly in the
change description:

```bash
jj describe -m "fix: improve router failover handling

Supersedes: abcdefghijkl
Reason: fix-regression
Path: router/failover
"
```

This makes stale guidance easier to detect and reduces reintroduction of old
repairs.

### Path-scoped metadata for bounded retrieval

When a change is specific to one subsystem, include local retrieval hints in the
description rather than forcing later agents to replay whole discussions:

```text
Path: router/snmp
Related-Round: round-83
Active-Constraints: keep runtime secrets out of the Nix store
Supersedes: abcdefghijkl
```

### Prediction-bearing metadata for calibration

When a change contains an explicit forward-looking claim, record that prediction
in a structured way so later graph outcomes can assess it:

```text
Prediction-ID: pred-router-ha-001
Scope: router/failover
Risk-Class: operational
Expected-Properties: no split-brain, bounded failover time
Expected-Failure-Modes: stale lease ownership, dual-active drift
Vouch-Basis: prior HA incident history and staging drill evidence
Vouch-Expiry: 2026-07-01
```

Use these fields as the standard prediction surface:

- `Prediction-ID:`
- `Scope:`
- `Risk-Class:`
- `Expected-Properties:`
- `Expected-Failure-Modes:`
- `Vouch-Basis:`
- `Vouch-Expiry:`

These fields are for explicit predictions, not generic commentary.

### Outcome-linking metadata for later assessment

When later graph activity bears on an earlier prediction, link it explicitly:

```text
Outcome-Link: pred-router-ha-001
Outcome-Type: stabilized
Outcome-Verdict: partially_confirmed
Outcome-Notes: merge held, but stale lease ownership required follow-up repair
Calibration-Delta: decrease confidence on lease safety, preserve confidence on secret handling
```

Use these fields on later changes or linked records:

- `Outcome-Link:`
- `Outcome-Type:`
- `Outcome-Verdict:`
- `Outcome-Notes:`
- `Calibration-Delta:`

Allowed verdicts should stay narrow and auditable, for example:

- `confirmed`
- `partially_confirmed`
- `violated`
- `expired_unresolved`
- `superseded_without_test`

Do not use these fields to imply person-level rank or prestige.

### Conflict as durable state

If a conflict reflects genuine design disagreement rather than a simple merge
mistake, preserve that fact in the description and route it for review instead
of hiding it in ad hoc chat:

```bash
jj describe -m "conflict: alternate HA ownership model

Reason: deliberative disagreement
Decision-Needed: yes
Related-Round: round-85
"
```

### Delta extraction for iterative agent work

When resuming a previously known change, prefer the compact delta over replaying
the whole transcript:

```bash
jj log -r "CHANGE_ID" --no-graph -T "commit_id"
jj diff -r REV_OLD -r REV_NEW
```

This is the preferred way to recover context for long-running agent work.

### Undo is a first-class safety valve

`jj undo` should be part of the normal recovery path for mistaken local
operations. Prefer it over improvised stash/reset habits when the intent is to
back out the last repository operation cleanly.

## Bookmark Naming

- Prefer scoped names such as `alice/router-snmp`, `ops/failover-drill`, or
  `team/knowledge-index`.
- Treat unscoped shared names as special protocol surfaces only.
- Avoid prestige or legitimacy-implying names unless there is an explicit policy
  for earning them.
- Remember that bookmarks do not automatically move to a newly created child
  change; create or move them intentionally.

## Agent Safety Constraints

1. **Non-Interactive:** Always use `--color never`.
2. **Pager Safety:** `jj` defaults to a pager for many commands. The orchestrator must bypass this.
3. **Template Robustness:** Use `separate('|', ...)` for multi-field logging to avoid parsing errors.
4. **Stable IDs:** Prefer `change_id` for long-running deliberation; `commit_id` for static snapshots.

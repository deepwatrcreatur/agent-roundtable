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

## Agent Safety Constraints

1. **Non-Interactive:** Always use `--color never`.
2. **Pager Safety:** `jj` defaults to a pager for many commands. The orchestrator must bypass this.
3. **Template Robustness:** Use `separate('|', ...)` for multi-field logging to avoid parsing errors.
4. **Stable IDs:** Prefer `change_id` for long-running deliberation; `commit_id` for static snapshots.

# 46 — Multidimensional Tagging Schema (Dolt + jj)

**Status:** `ready`

## Goal
Enable native, multidimensional tagging for issues to replace the "Single Board" bottleneck.

## Scope
- Design `Dolt` schema for `tags` and `issue_tags` (many-to-many).
- Implement `vaglio tag add/remove` CLI commands.
- Map tags to `jj` namespaced pointers (e.g., `tags/networking`) to allow revset discovery.
- Update the WebUI to allow filtering and "Perspectives" based on tag sets.

## Acceptance Criteria
- SQL queries can return all issues for a given tag set.
- `jj log -r 'tag(networking)'` (or equivalent) returns the correct subset of the DAG.
- WebUI supports "Subject Streams" for maintainers.

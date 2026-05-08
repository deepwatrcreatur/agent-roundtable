# 66 — Vaglio Repo + Source Selector

**Status:** `in-progress`
**Assigned:** Codex
**Branch:** `feat/vaglio-auth-and-repo-selector`
**Tag:** `[product-surface]`

## Goal
Let a maintainer choose which Vaglio-managed repository a round targets, instead of hard-wiring the web UI to a single `ROUNDTABLE_REPO` environment variable.

## Why
The current LiveView dashboard only manages one repo slug and one brief path from environment variables. That is too narrow for the intended operator workflow:

- choose between multiple repositories/topics associated with Vaglio
- target either a standalone discussion repo or a repo-local/embedded discussion path
- inject prompts into the selected discussion without reconfiguring the whole service

## Scope
- add a first-class "source selector" surface to the LiveView dashboard
- support manual selection of:
  - GitHub repo slug
  - brief/source path
  - optional local checkout path for conflict inspection
- add discovery for candidate repos tagged/topic-labelled for Vaglio when GitHub access is available
- make the selected source drive:
  - question injection
  - round trigger
  - dashboard polling
- keep the initial implementation compatible with existing env-var defaults

## Non-Goals
- full OIDC login/session implementation
- TUI `/login` flows
- full OpenRouter provider routing
- automatic embedded-discussion migration for arbitrary repos

## Acceptance Criteria
- web UI can switch between at least two candidate repos without service restart
- injected questions go to the currently selected repo
- trigger-round uses the currently selected source settings
- env vars remain valid defaults when no explicit source has been selected

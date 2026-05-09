# 70 — Forgejo DiscussionRepo Backend

**Status:** `done`
**Tag:** `[product]`

## Goal
Implement the missing `Roundtable.Adapters.Forgejo` backend so file-based discussion repositories can run against a self-hosted Forgejo surface instead of GitHub-only APIs.

## Scope
- Add a `DiscussionRepo.Backend` implementation for Forgejo with the same core operations as the GitHub adapter:
  - `read_file/2`
  - `write_file/4`
  - `list_files/2`
  - `discussion_repo?/1`
- Reuse as much of the GitHub adapter contract and payload shaping as possible without assuming GitHub-only endpoints.
- Keep auth override support so explicit tokens can replace ambient CLI credentials.
- Cover the backend with focused tests using the existing command-runner stubbing pattern.

## Acceptance Criteria
- `DiscussionRepo.new(..., backend: Roundtable.Adapters.Forgejo)` is viable for file-backed repo operations.
- The Forgejo adapter preserves the same high-level backend contract as GitHub without pretending the APIs are identical.
- Tests cover both happy-path file operations and expected API failure modes.

## Outcome
- Added `Roundtable.Adapters.Forgejo` using Forgejo's contents API via `curl`.
- Kept backend-specific seams explicit:
  - required Forgejo host config via `:base_url` or `:api_base_url`
  - `POST` for create vs `PUT` for update
  - configurable `token` vs `bearer` auth header mode
- Added focused adapter coverage for reads, writes, listings, auth, and failure handling.
- Updated `DiscussionRepo` docs/tests to surface backend-specific config.

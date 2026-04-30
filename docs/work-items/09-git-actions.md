# 09 — Roundtable.Actions.Git (Durable Storage)

**Status:** `in-progress`
**Assigned:** GitHub Copilot
**Branch:** `feat/git-actions`

## Scope

Implement `Roundtable.Actions.Git` — the durable storage abstraction for
writing git-tracked artifacts independently from the GitHub Issues discussion
path.

This module should be an **Elixir behaviour with pluggable backends** as
designed in Q9. For v1, the focus is on a robust `LocalGit` implementation.

## Interface

```elixir
defmodule Roundtable.Actions.Git do
  @type path_patch ::
          {:put, %{path: String.t(), content: binary()}}
          | {:delete, %{path: String.t()}}

  @type commit_request :: %{
          message: String.t(),
          branch: String.t(),
          expected_head: String.t() | nil,
          changes: [path_patch()]
        }

  @type commit_result :: %{
          commit_sha: String.t(),
          branch: String.t()
        }

  @callback write_files(commit_request(), keyword()) ::
              {:ok, commit_result()} | {:error, term()}

  @callback read_file(String.t(), keyword()) ::
              {:ok, binary()} | {:error, term()}

  @callback current_head(String.t(), keyword()) ::
              {:ok, String.t()} | {:error, term()}
end
```

This interface is intentionally about the durable artifact path:
`DECISION.md`, transcript exports, `ACTIVE_DISCUSSION.md` index updates, and
other git-tracked records. It does **not** own GitHub Issues operations.

## Separation of concerns

- `Roundtable.Actions.Gh`: issues, comments, labels, close/open lifecycle
- `Roundtable.Actions.Git`: tracked-file reads/writes, commit creation, push/sync

Do not mix issue coordination into this module.

## Implementation (v1)

- **LocalGit**: uses `System.cmd("git", ...)`
- Must support multi-file durable writes in one commit request
- Must surface head mismatch / push rejection clearly rather than silently
  overwriting
- Low-frequency finalization writes are the v1 target; this is not the live
  coordination path

## Future (v2)

- **GitHubAPI**: API-native file/tree writes while remaining on GitHub
- **CodeStorage**: atomic multi-file commit API without local clones

Cloudflare Artifacts is out of scope for this abstraction for now; Q7 showed it
addresses a repo-hosting/event model question rather than the immediate durable
write path.

## Done when

- `Roundtable.Actions.Git` behaviour defined
- `Roundtable.Actions.Git.LocalGit` implemented and passing tests
- Successfully writes multiple files to a test repo in one commit step
- Failure modes (`expected_head` mismatch, locked index, push rejected) covered
  by tests

defmodule Roundtable.DiscussionRepo.Backend do
  @moduledoc """
  Behaviour for reading and writing files in a discussion repository.

  The canonical implementation is `Roundtable.Adapters.GitHub`, which uses
  the GitHub REST API via the `gh` CLI. A Forgejo-compatible implementation
  can satisfy this behaviour without touching the orchestrator.

  ## Callbacks

  All callbacks receive a `Roundtable.DiscussionRepo` struct as their first
  argument, which carries the repo slug, optional token, and any cached state
  such as a head commit SHA.
  """

  alias Roundtable.DiscussionRepo

  @doc """
  Read the raw binary contents of a file at `path` within the repo.
  """
  @callback read_file(repo :: DiscussionRepo.t(), path :: String.t()) ::
              {:ok, binary()} | {:error, term()}

  @doc """
  Create or update the file at `path` with `content`, committing with `message`.

  Returns `{:ok, updated_repo}` so callers receive any updated state (e.g. new
  head SHA) from the write operation.
  """
  @callback write_file(
              repo :: DiscussionRepo.t(),
              path :: String.t(),
              content :: binary(),
              message :: String.t()
            ) :: {:ok, DiscussionRepo.t()} | {:error, term()}

  @doc """
  List the names of entries (files and directories) at `path` within the repo.
  Not recursive. Returns an empty list when the path does not exist.
  """
  @callback list_files(repo :: DiscussionRepo.t(), path :: String.t()) ::
              {:ok, [String.t()]} | {:error, term()}

  @doc """
  Return `true` if the repository contains a `roundtable.toml` in its root,
  confirming it is a managed roundtable discussion repo.
  """
  @callback discussion_repo?(repo :: DiscussionRepo.t()) :: boolean()
end

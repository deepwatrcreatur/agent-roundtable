defmodule Roundtable.Actions.Git do
  @moduledoc """
  Durable git-backed storage abstraction for tracked artifact writes.

  This behaviour owns git-tracked file reads/writes and commit creation for the
  durable artifact path (`DECISION.md`, transcript exports, discussion indexes,
  and similar files). It intentionally does **not** own GitHub Issues state.

  V1 is expected to use `Roundtable.Actions.Git.LocalGit`; future backends can
  satisfy the same contract without changing orchestrator code.
  """

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

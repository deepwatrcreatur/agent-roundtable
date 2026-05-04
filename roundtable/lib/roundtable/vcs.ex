defmodule Roundtable.Vcs do
  @moduledoc """
  Unified behaviour for Version Control Systems (Git, Jujutsu, etc.).
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
          commit_id: String.t(),
          change_id: String.t() | nil,
          branch: String.t()
        }

  @type conflict :: %{
          path: String.t(),
          type: :file | :directory | :other
        }

  @callback write_files(commit_request(), keyword()) ::
              {:ok, commit_result()} | {:error, term()}

  @callback read_file(String.t(), keyword()) ::
              {:ok, binary()} | {:error, term()}

  @callback current_head(String.t(), keyword()) ::
              {:ok, String.t()} | {:error, term()}

  @callback conflicts(keyword()) ::
              {:ok, [conflict()]} | {:error, term()}

  @callback query(String.t(), keyword()) ::
              {:ok, [map()]} | {:error, term()}

  @callback diff(String.t(), keyword()) ::
              {:ok, binary()} | {:error, term()}
end

defmodule Roundtable.Sourcegraph.EvidenceRecord do
  @moduledoc """
  Normalized local record for bounded Sourcegraph-derived evidence.
  """

  @enforce_keys [
    :id,
    :provider,
    :source_type,
    :retrieval_mode,
    :repo,
    :revision,
    :path_scope,
    :sourcegraph_query,
    :files_read,
    :commits_examined,
    :diffs_examined,
    :created_at,
    :summary
  ]
  defstruct [
    :id,
    :provider,
    :source_type,
    :retrieval_mode,
    :repo,
    :revision,
    :path_scope,
    :sourcegraph_query,
    :sourcegraph_conversation_url,
    :files_read,
    :commits_examined,
    :diffs_examined,
    :created_at,
    :created_by_attempt,
    :summary,
    :search_results,
    :history_results,
    :file_bodies
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          provider: String.t(),
          source_type: String.t(),
          retrieval_mode: String.t(),
          repo: String.t(),
          revision: String.t(),
          path_scope: String.t(),
          sourcegraph_query: String.t(),
          sourcegraph_conversation_url: String.t() | nil,
          files_read: [String.t()],
          commits_examined: [String.t()],
          diffs_examined: [String.t()],
          created_at: String.t(),
          created_by_attempt: String.t() | nil,
          summary: String.t(),
          search_results: [map()],
          history_results: [map()],
          file_bodies: [%{path: String.t(), content: String.t()}]
        }

  @spec new(map()) :: t()
  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end

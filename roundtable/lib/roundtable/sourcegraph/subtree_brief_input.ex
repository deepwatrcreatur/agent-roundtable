defmodule Roundtable.Sourcegraph.SubtreeBriefInput do
  @moduledoc """
  Thin bridge that makes normalized Sourcegraph evidence available as bounded
  input to subtree-brief generation.
  """

  alias Roundtable.Sourcegraph.EvidenceRecord

  @spec from_evidence(EvidenceRecord.t()) :: map()
  def from_evidence(%EvidenceRecord{} = evidence) do
    %{
      repo: evidence.repo,
      revision: evidence.revision,
      path_scope: evidence.path_scope,
      source_evidence: %{
        id: evidence.id,
        provider: evidence.provider,
        source_type: evidence.source_type,
        retrieval_mode: evidence.retrieval_mode,
        query: evidence.sourcegraph_query,
        conversation_url: evidence.sourcegraph_conversation_url,
        files_read: evidence.files_read,
        commits_examined: evidence.commits_examined,
        diffs_examined: evidence.diffs_examined,
        summary: evidence.summary
      },
      evidence_records: [evidence]
    }
  end
end

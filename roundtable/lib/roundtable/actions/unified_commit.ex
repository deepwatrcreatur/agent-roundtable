defmodule Roundtable.Actions.UnifiedCommit do
  use Jido.Action,
    name: "unified_commit",
    description: "Coordinated commit to both JJ (intent) and Dolt (state)",
    schema: [
      repo_path: [type: :string, required: true, doc: "Path to the colocated repository"],
      message: [type: :string, required: true, doc: "Commit message"],
      branch: [type: :string, required: false, default: "main", doc: "Dolt branch"],
      changes: [type: :list, required: false, default: [], doc: "Filesystem changes for jj"]
    ]

  alias Roundtable.Vcs.{Jujutsu, Dolt}

  @impl true
  def run(params, _context) do
    opts = [repo_path: params.repo_path]

    # 1. Update Files via JJ
    with {:ok, jj_result} <- Jujutsu.write_files(params, opts),
         # 2. Update Metadata in Dolt
         # We map the jj Change ID to a Dolt commit property if supported,
         # or just include it in the message for traceability.
         dolt_message = "#{params.message}\n\n[jj-change-id: #{jj_result.change_id}]",
         dolt_params = Map.put(params, :message, dolt_message),
         {:ok, dolt_result} <- Dolt.write_files(dolt_params, opts) do
      {:ok,
       %{
         commit_id: jj_result.commit_id,
         change_id: jj_result.change_id,
         dolt_sha: dolt_result.commit_id
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end

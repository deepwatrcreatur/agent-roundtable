defmodule Roundtable.HumanAnchor do
  @moduledoc """
  Maintains human vouch anchors for findings and claims in Dolt-backed trust data.
  """

  alias Roundtable.Vcs.Dolt

  @default_maintainers ["lead-maintainer", "review-core", "release-shepherd"]

  @type vouch :: %{
          issue_number: String.t(),
          claim_key: String.t(),
          maintainer_id: String.t(),
          verdict: String.t(),
          ai_state: String.t(),
          note: String.t(),
          created_at: String.t()
        }

  @spec maintainer_options(keyword()) :: [String.t()]
  def maintainer_options(opts \\ []) do
    case Keyword.get(opts, :maintainers_env, System.get_env("ROUNDTABLE_SENIOR_MAINTAINERS", "")) do
      "" -> @default_maintainers
      env -> env |> String.split(",", trim: true) |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
    end
  end

  @spec list_vouches(String.t() | nil, keyword()) :: {:ok, [vouch()]} | {:error, term()}
  def list_vouches(repo_path, opts \\ [])
  def list_vouches(nil, _opts), do: {:ok, []}
  def list_vouches("", _opts), do: {:ok, []}
  def list_vouches(repo_path, opts) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])

    with {:ok, _} <- ensure_schema(repo_path, dolt, query_opts),
         {:ok, rows} <- dolt.query(list_vouches_sql(), [repo_path: repo_path] ++ query_opts) do
      {:ok,
       Enum.map(rows, fn row ->
         %{
           issue_number: to_string(row["issue_number"]),
           claim_key: row["claim_key"] || "finding",
           maintainer_id: row["maintainer_id"] || "unknown",
           verdict: row["verdict"] || "vouched",
           ai_state: row["ai_state"] || "unknown",
           note: row["note"] || "",
           created_at: row["created_at"] || ""
         }
       end)}
    end
  end

  @spec verify_finding(String.t() | nil, pos_integer(), String.t(), atom(), keyword()) ::
          :ok | {:error, term()}
  def verify_finding(repo_path, issue_number, maintainer_id, ai_state, opts \\ []) do
    persist_vouch(repo_path, issue_number, "finding", maintainer_id, ai_state, opts)
  end

  @spec verify_claim(String.t() | nil, pos_integer(), String.t(), String.t(), atom(), keyword()) ::
          :ok | {:error, term()}
  def verify_claim(repo_path, issue_number, claim_key, maintainer_id, ai_state, opts \\ []) do
    persist_vouch(repo_path, issue_number, claim_key, maintainer_id, ai_state, opts)
  end

  @spec build_statuses(map(), [vouch()]) :: map()
  def build_statuses(questions, vouches) when is_map(questions) do
    Map.new(questions, fn {number, question} ->
      issue_key = Integer.to_string(number)
      issue_vouches = Enum.filter(vouches, &(&1.issue_number == issue_key))
      finding_vouches = Enum.filter(issue_vouches, &(&1.claim_key == "finding"))

      claim_vouch_counts =
        issue_vouches
        |> Enum.reject(&(&1.claim_key == "finding"))
        |> Enum.frequencies_by(& &1.claim_key)

      ai_consensus? = question[:satisfaction] in [:satisfied, :satisfied_conditional, :no_objection]
      anchored? = finding_vouches != []

      delta_label =
        cond do
          anchored? and ai_consensus? -> "Aligned"
          anchored? and not ai_consensus? -> "Human ahead of AI"
          ai_consensus? and not anchored? -> "AI leads humans"
          true -> "Awaiting review"
        end

      status_label = if anchored?, do: "Project-Binding", else: "Awaiting Human Anchor"

      {number,
       %{
         anchored?: anchored?,
         status_label: status_label,
         delta_label: delta_label,
         finding_vouch_count: length(finding_vouches),
         claim_vouch_counts: claim_vouch_counts,
         maintainers: Enum.map(finding_vouches, & &1.maintainer_id)
       }}
    end)
  end

  defp persist_vouch(nil, _issue_number, _claim_key, _maintainer_id, _ai_state, _opts),
    do: {:error, :no_local_repo}

  defp persist_vouch("", _issue_number, _claim_key, _maintainer_id, _ai_state, _opts),
    do: {:error, :no_local_repo}

  defp persist_vouch(repo_path, issue_number, claim_key, maintainer_id, ai_state, opts) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt, :note, :signing_key, :sign?])
    note = Keyword.get(opts, :note, "")
    sign? = Keyword.get(opts, :sign?, true)
    signing_key = Keyword.get(opts, :signing_key, System.get_env("ROUNDTABLE_VOUCH_SIGNING_KEY"))

    with {:ok, _} <- ensure_schema(repo_path, dolt, query_opts),
         {:ok, _} <- dolt.query(insert_vouch_sql(issue_number, claim_key, maintainer_id, ai_state, note), [repo_path: repo_path] ++ query_opts),
         {:ok, _} <-
           dolt.write_files(
             %{
               message: commit_message(issue_number, claim_key, maintainer_id, ai_state),
               branch: "main",
               changes: [],
               sign?: sign?,
               signing_key: signing_key
             },
             [repo_path: repo_path] ++ query_opts
           ) do
      :ok
    end
  end

  defp ensure_schema(repo_path, dolt, opts) do
    dolt.query(schema_sql(), [repo_path: repo_path] ++ opts)
  end

  defp schema_sql do
    """
    CREATE TABLE IF NOT EXISTS trust_vouches (
      issue_number TEXT NOT NULL,
      claim_key TEXT NOT NULL,
      maintainer_id TEXT NOT NULL,
      verdict TEXT NOT NULL,
      ai_state TEXT NOT NULL,
      note TEXT,
      created_at TEXT NOT NULL,
      PRIMARY KEY (issue_number, claim_key, maintainer_id)
    );
    """
  end

  defp list_vouches_sql do
    """
    SELECT issue_number, claim_key, maintainer_id, verdict, ai_state, note, created_at
    FROM trust_vouches
    ORDER BY created_at DESC;
    """
  end

  defp insert_vouch_sql(issue_number, claim_key, maintainer_id, ai_state, note) do
    """
    REPLACE INTO trust_vouches (
      issue_number, claim_key, maintainer_id, verdict, ai_state, note, created_at
    ) VALUES (
      '#{issue_number}', '#{escape_sql(claim_key)}', '#{escape_sql(maintainer_id)}',
      'vouched', '#{escape_sql(to_string(ai_state))}', '#{escape_sql(note)}', '#{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()}'
    );
    """
  end

  defp commit_message(issue_number, claim_key, maintainer_id, ai_state) do
    "feat(trust): anchor issue #{issue_number} (#{claim_key}) by #{maintainer_id}\n\n[ai-state: #{ai_state}]"
  end

  defp escape_sql(value) do
    value
    |> to_string()
    |> String.replace("'", "''")
  end
end

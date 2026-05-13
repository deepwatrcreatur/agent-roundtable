defmodule Roundtable.WorkflowDefinitions do
  @moduledoc """
  Lightweight workflow-as-data definitions for board tasks.

  A workflow definition provides reusable defaults for:

  - task-type applicability
  - runtime requirements
  - retry policy
  - timeout policy
  - human-gate policy
  - resumable transitions

  Work items can reference a reusable workflow by `workflow_ref` and still
  override policy inline. This keeps the model small and Elixir-native without
  introducing a heavyweight external workflow engine.
  """

  alias Roundtable.Vcs.Dolt

  @schema_file Application.app_dir(
                 :roundtable,
                 "priv/dolt/migrations/20260512_add_workflow_definitions.sql"
               )
  @external_resource @schema_file
  @schema_sql File.read!(@schema_file)

  @type definition :: %{
          id: String.t(),
          title: String.t(),
          description: String.t() | nil,
          task_types: [String.t()],
          runtime_requirements: map(),
          retry_policy: map() | nil,
          timeout_policy: map() | nil,
          hitl_policy: map() | nil,
          resume_policy: map() | nil,
          created_at: String.t(),
          updated_at: String.t()
        }

  @spec schema_sql() :: String.t()
  def schema_sql, do: @schema_sql

  @spec ensure_schema(String.t() | nil, keyword()) :: {:ok, term()} | {:error, term()}
  def ensure_schema(repo_path, opts \\ [])
  def ensure_schema(nil, _opts), do: {:error, :no_local_repo}
  def ensure_schema("", _opts), do: {:error, :no_local_repo}

  def ensure_schema(repo_path, opts) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])
    dolt.query(schema_sql(), [repo_path: repo_path] ++ query_opts)
  end

  @spec put_definition(String.t() | nil, map(), keyword()) :: :ok | {:error, term()}
  def put_definition(repo_path, attrs, opts \\ []) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt, :sign?, :signing_key])
    sign? = Keyword.get(opts, :sign?, false)
    signing_key = Keyword.get(opts, :signing_key, System.get_env("ROUNDTABLE_BOARD_SIGNING_KEY"))

    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, sql} <- definition_upsert_sql(attrs),
         {:ok, _} <- dolt.query(sql, [repo_path: repo_path] ++ query_opts),
         {:ok, _} <-
           dolt.write_files(
             %{
               message:
                 "feat(board): define workflow #{fetch_optional(attrs, :id, fetch_optional(attrs, "id", "unknown"))}\n\n[workflow-definitions: lightweight]",
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

  @spec get_definition(String.t() | nil, String.t(), keyword()) ::
          {:ok, definition() | nil} | {:error, term()}
  def get_definition(repo_path, id, opts \\ []) when is_binary(id) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])

    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, rows} <- dolt.query(get_definition_sql(id), [repo_path: repo_path] ++ query_opts) do
      {:ok, rows |> List.first() |> decode_nullable(&decode_definition_row/1)}
    end
  end

  @spec list_definitions(String.t() | nil, keyword()) :: {:ok, [definition()]} | {:error, term()}
  def list_definitions(repo_path, opts \\ []) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])

    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, rows} <- dolt.query(list_definitions_sql(), [repo_path: repo_path] ++ query_opts) do
      {:ok, Enum.map(rows, &decode_definition_row/1)}
    end
  end

  @spec resolve_work_item(String.t() | nil, map(), keyword()) :: {:ok, map()} | {:error, term()}
  def resolve_work_item(repo_path, work_item, opts \\ [])
  def resolve_work_item(_repo_path, nil, _opts), do: {:error, :work_item_not_found}

  def resolve_work_item(repo_path, work_item, opts) do
    case Map.get(work_item, :workflow_ref, Map.get(work_item, "workflow_ref")) do
      nil ->
        {:ok, Map.put_new(work_item, :runtime_requirements, %{})}

      "" ->
        {:ok, Map.put_new(work_item, :runtime_requirements, %{})}

      workflow_ref ->
        with {:ok, definition} <- get_definition(repo_path, workflow_ref, opts),
             {:ok, definition} <- ensure_definition_exists(definition) do
          merged =
            work_item
            |> Map.put(:workflow_definition, definition)
            |> Map.put(
              :runtime_requirements,
              merge_maps(
                definition.runtime_requirements || %{},
                Map.get(work_item, :runtime_requirements, %{})
              )
            )
            |> Map.put(
              :retry_policy,
              merge_optional_maps(definition.retry_policy, Map.get(work_item, :retry_policy))
            )
            |> Map.put(
              :timeout_policy,
              merge_optional_maps(definition.timeout_policy, Map.get(work_item, :timeout_policy))
            )
            |> Map.put(
              :hitl_policy,
              merge_optional_maps(definition.hitl_policy, Map.get(work_item, :hitl_policy))
            )
            |> Map.put(
              :resume_policy,
              merge_optional_maps(definition.resume_policy, Map.get(work_item, :resume_policy))
            )
            |> Map.put(:allowed_task_types, definition.task_types || [])

          {:ok, merged}
        end
    end
  end

  @spec runtime_allowed?(map(), keyword()) :: boolean()
  def runtime_allowed?(work_item, opts \\ []) do
    requirements = Map.get(work_item, :runtime_requirements, %{}) || %{}
    allowed_task_types = Map.get(work_item, :allowed_task_types, [])
    runtime_id = Keyword.get(opts, :runtime_id)
    runtime_profiles = Keyword.get(opts, :runtime_profile_ids, [])
    runtime_labels = Keyword.get(opts, :runtime_labels, [])
    transport = Keyword.get(opts, :transport)
    task_type = Map.get(work_item, :task_type)

    task_type_allowed?(task_type, allowed_task_types) and
      required_runtime_allowed?(
        runtime_id,
        Map.get(requirements, "runtimes", Map.get(requirements, :runtimes))
      ) and
      required_profiles_allowed?(
        runtime_profiles,
        Map.get(requirements, "profiles", Map.get(requirements, :profiles))
      ) and
      required_labels_allowed?(
        runtime_labels,
        Map.get(requirements, "labels", Map.get(requirements, :labels))
      ) and
      required_transport_allowed?(
        transport,
        Map.get(requirements, "transports", Map.get(requirements, :transports))
      )
  end

  defp definition_upsert_sql(attrs) do
    with {:ok, id} <- fetch_required(attrs, :id),
         {:ok, title} <- fetch_required(attrs, :title) do
      now = now_iso8601()

      {:ok,
       """
       REPLACE INTO workflow_definitions (
         id, title, description, task_types_json, runtime_requirements_json,
         retry_policy_json, timeout_policy_json, hitl_policy_json, resume_policy_json,
         created_at, updated_at
       ) VALUES (
         '#{escape_sql(id)}', '#{escape_sql(title)}',
         #{sql_text(fetch_optional(attrs, :description, nil))},
         '#{escape_sql(json_text(fetch_optional(attrs, :task_types, [])))}',
         '#{escape_sql(json_text(fetch_optional(attrs, :runtime_requirements, %{})))}',
         #{sql_text(json_text_or_nil(fetch_optional(attrs, :retry_policy, nil)))},
         #{sql_text(json_text_or_nil(fetch_optional(attrs, :timeout_policy, nil)))},
         #{sql_text(json_text_or_nil(fetch_optional(attrs, :hitl_policy, nil)))},
         #{sql_text(json_text_or_nil(fetch_optional(attrs, :resume_policy, nil)))},
         '#{fetch_optional(attrs, :created_at, now)}',
         '#{fetch_optional(attrs, :updated_at, now)}'
       );
       """}
    end
  end

  defp get_definition_sql(id) do
    """
    SELECT id, title, description, task_types_json, runtime_requirements_json,
           retry_policy_json, timeout_policy_json, hitl_policy_json, resume_policy_json,
           created_at, updated_at
    FROM workflow_definitions
    WHERE id = '#{escape_sql(id)}'
    LIMIT 1;
    """
  end

  defp list_definitions_sql do
    """
    SELECT id, title, description, task_types_json, runtime_requirements_json,
           retry_policy_json, timeout_policy_json, hitl_policy_json, resume_policy_json,
           created_at, updated_at
    FROM workflow_definitions
    ORDER BY id ASC;
    """
  end

  defp decode_definition_row(row) do
    %{
      id: row["id"],
      title: row["title"],
      description: row["description"],
      task_types: decode_json(row["task_types_json"], []),
      runtime_requirements: decode_json(row["runtime_requirements_json"], %{}),
      retry_policy: decode_json(row["retry_policy_json"], nil),
      timeout_policy: decode_json(row["timeout_policy_json"], nil),
      hitl_policy: decode_json(row["hitl_policy_json"], nil),
      resume_policy: decode_json(row["resume_policy_json"], nil),
      created_at: row["created_at"],
      updated_at: row["updated_at"]
    }
  end

  defp task_type_allowed?(_task_type, []), do: true
  defp task_type_allowed?(task_type, allowed) when is_list(allowed), do: task_type in allowed

  defp required_runtime_allowed?(_runtime_id, nil), do: true
  defp required_runtime_allowed?(_runtime_id, []), do: true

  defp required_runtime_allowed?(runtime_id, allowed) when is_list(allowed),
    do: runtime_id in allowed

  defp required_profiles_allowed?(_runtime_profiles, nil), do: true
  defp required_profiles_allowed?(_runtime_profiles, []), do: true

  defp required_profiles_allowed?(runtime_profiles, allowed) when is_list(allowed) do
    MapSet.disjoint?(MapSet.new(runtime_profiles), MapSet.new(allowed)) == false
  end

  defp required_labels_allowed?(_runtime_labels, nil), do: true
  defp required_labels_allowed?(_runtime_labels, []), do: true

  defp required_labels_allowed?(runtime_labels, required) when is_list(required) do
    MapSet.subset?(MapSet.new(required), MapSet.new(runtime_labels))
  end

  defp required_transport_allowed?(_transport, nil), do: true
  defp required_transport_allowed?(_transport, []), do: true

  defp required_transport_allowed?(transport, allowed) when is_list(allowed),
    do: transport in allowed

  defp ensure_definition_exists(nil), do: {:error, :workflow_definition_not_found}
  defp ensure_definition_exists(definition), do: {:ok, definition}

  defp merge_optional_maps(nil, nil), do: nil
  defp merge_optional_maps(base, nil), do: base
  defp merge_optional_maps(nil, override), do: override
  defp merge_optional_maps(base, override), do: merge_maps(base, override)

  defp merge_maps(base, override) when is_map(base) and is_map(override) do
    Map.merge(base, override, fn _key, left, right ->
      if is_map(left) and is_map(right), do: merge_maps(left, right), else: right
    end)
  end

  defp merge_maps(_base, override), do: override

  defp fetch_required(attrs, key) do
    case fetch_optional(attrs, key, nil) do
      nil -> {:error, {:missing_field, key}}
      "" -> {:error, {:missing_field, key}}
      value -> {:ok, value}
    end
  end

  defp fetch_optional(attrs, key, default),
    do: Map.get(attrs, key, Map.get(attrs, to_string(key), default))

  defp json_text(nil), do: "{}"
  defp json_text(value), do: Jason.encode!(value)

  defp json_text_or_nil(nil), do: nil
  defp json_text_or_nil(value), do: Jason.encode!(value)

  defp sql_text(nil), do: "NULL"
  defp sql_text(value), do: "'#{escape_sql(value)}'"

  defp decode_json(nil, default), do: default
  defp decode_json("", default), do: default

  defp decode_json(value, default) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, decoded} -> decoded
      {:error, _} -> default
    end
  end

  defp decode_json(value, _default), do: value

  defp decode_nullable(nil, _fun), do: nil
  defp decode_nullable(row, fun), do: fun.(row)

  defp now_iso8601, do: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

  defp escape_sql(value) do
    value
    |> to_string()
    |> String.replace("'", "''")
  end
end

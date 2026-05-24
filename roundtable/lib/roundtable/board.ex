defmodule Roundtable.Board do
  @moduledoc """
  Dolt-backed execution-board persistence primitives.

  This module implements the concrete schema introduced by item 73:

  - `work_items`
  - `work_attempts`
  - `human_gates`
  - `runtime_heartbeats`

  The board layer stays intentionally narrow: it stores durable execution state,
  attempt lineage, and structured human gates without trying to absorb Vaglio's
  longer-term governance or trust responsibilities.
  """

  alias Roundtable.Vcs.Dolt

  @schema_files [
    Application.app_dir(
      :roundtable,
      "priv/dolt/migrations/20260512_add_board_execution_schema.sql"
    ),
    Application.app_dir(
      :roundtable,
      "priv/dolt/migrations/20260512_add_board_attempt_event_log.sql"
    )
  ]
  Enum.each(@schema_files, &Module.put_attribute(__MODULE__, :external_resource, &1))
  @schema_sql Enum.map_join(@schema_files, "\n\n", &File.read!/1)

  @type work_item :: map()
  @type attempt :: map()
  @type human_gate :: map()
  @type runtime_heartbeat :: map()
  @type attempt_event :: map()

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

  @spec create_work_item(String.t() | nil, map(), keyword()) :: :ok | {:error, term()}
  def create_work_item(repo_path, attrs, opts \\ []) do
    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, sql} <- work_item_upsert_sql(attrs),
         :ok <-
           mutate(
             repo_path,
             sql,
             commit_message("feat(board): create work item #{attrs[:id] || attrs["id"]}"),
             opts
           ) do
      :ok
    end
  end

  @spec append_attempt(String.t() | nil, map(), keyword()) :: :ok | {:error, term()}
  def append_attempt(repo_path, attrs, opts \\ []) do
    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, sql} <- attempt_insert_sql(attrs),
         :ok <-
           mutate(
             repo_path,
             sql,
             commit_message(
               "feat(board): append attempt #{attrs[:id] || attrs["id"]} for #{attrs[:work_item_id] || attrs["work_item_id"]}"
             ),
             opts
           ) do
      :ok
    end
  end

  @spec open_human_gate(String.t() | nil, map(), keyword()) :: :ok | {:error, term()}
  def open_human_gate(repo_path, attrs, opts \\ []) do
    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, sql} <- human_gate_upsert_sql(attrs),
         :ok <-
           mutate(
             repo_path,
             sql,
             commit_message(
               "feat(board): open human gate #{attrs[:id] || attrs["id"]} for #{attrs[:work_item_id] || attrs["work_item_id"]}"
             ),
             opts
           ) do
      :ok
    end
  end

  @spec heartbeat_runtime(String.t() | nil, map(), keyword()) :: :ok | {:error, term()}
  def heartbeat_runtime(repo_path, attrs, opts \\ []) do
    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, sql} <- runtime_heartbeat_upsert_sql(attrs),
         :ok <-
           mutate(
             repo_path,
             sql,
             commit_message(
               "feat(board): heartbeat runtime #{attrs[:runtime_id] || attrs["runtime_id"]}"
             ),
             opts
           ) do
      :ok
    end
  end

  @spec list_work_items(String.t() | nil, keyword()) :: {:ok, [work_item()]} | {:error, term()}
  def list_work_items(repo_path, opts \\ []) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])

    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, rows} <- dolt.query(list_work_items_sql(), [repo_path: repo_path] ++ query_opts) do
      {:ok, Enum.map(rows, &decode_work_item_row/1)}
    end
  end

  @spec get_work_item(String.t() | nil, String.t(), keyword()) ::
          {:ok, work_item() | nil} | {:error, term()}
  def get_work_item(repo_path, work_item_id, opts \\ []) when is_binary(work_item_id) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])

    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, rows} <-
           dolt.query(get_work_item_sql(work_item_id), [repo_path: repo_path] ++ query_opts) do
      {:ok, rows |> List.first() |> decode_nullable(&decode_work_item_row/1)}
    end
  end

  @spec list_attempts(String.t() | nil, String.t(), keyword()) ::
          {:ok, [attempt()]} | {:error, term()}
  def list_attempts(repo_path, work_item_id, opts \\ []) when is_binary(work_item_id) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])

    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, rows} <-
           dolt.query(list_attempts_sql(work_item_id), [repo_path: repo_path] ++ query_opts) do
      {:ok, Enum.map(rows, &decode_attempt_row/1)}
    end
  end

  @spec get_attempt(String.t() | nil, String.t(), keyword()) ::
          {:ok, attempt() | nil} | {:error, term()}
  def get_attempt(repo_path, attempt_id, opts \\ []) when is_binary(attempt_id) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])

    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, rows} <-
           dolt.query(get_attempt_sql(attempt_id), [repo_path: repo_path] ++ query_opts) do
      {:ok, rows |> List.first() |> decode_nullable(&decode_attempt_row/1)}
    end
  end

  @spec list_human_gates(String.t() | nil, String.t(), keyword()) ::
          {:ok, [human_gate()]} | {:error, term()}
  def list_human_gates(repo_path, work_item_id, opts \\ []) when is_binary(work_item_id) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])

    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, rows} <-
           dolt.query(list_human_gates_sql(work_item_id), [repo_path: repo_path] ++ query_opts) do
      {:ok, Enum.map(rows, &decode_human_gate_row/1)}
    end
  end

  @spec list_runtime_heartbeats(String.t() | nil, keyword()) ::
          {:ok, [runtime_heartbeat()]} | {:error, term()}
  def list_runtime_heartbeats(repo_path, opts \\ []) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])

    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, rows} <-
           dolt.query(list_runtime_heartbeats_sql(), [repo_path: repo_path] ++ query_opts) do
      {:ok, Enum.map(rows, &decode_runtime_heartbeat_row/1)}
    end
  end

  @spec append_attempt_event(String.t() | nil, map(), keyword()) :: :ok | {:error, term()}
  def append_attempt_event(repo_path, attrs, opts \\ []) do
    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, sql} <- attempt_event_insert_sql(attrs),
         :ok <-
           mutate(
             repo_path,
             sql,
             commit_message(
               "feat(board): append event #{attrs[:event_type] || attrs["event_type"]} for #{attrs[:attempt_id] || attrs["attempt_id"]}"
             ),
             opts
           ) do
      :ok
    end
  end

  @spec list_attempt_events(String.t() | nil, String.t(), keyword()) ::
          {:ok, [attempt_event()]} | {:error, term()}
  def list_attempt_events(repo_path, attempt_id, opts \\ []) when is_binary(attempt_id) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt])

    with {:ok, _} <- ensure_schema(repo_path, opts),
         {:ok, rows} <-
           dolt.query(list_attempt_events_sql(attempt_id), [repo_path: repo_path] ++ query_opts) do
      {:ok, Enum.map(rows, &decode_attempt_event_row/1)}
    end
  end

  defp mutate(nil, _sql, _message, _opts), do: {:error, :no_local_repo}
  defp mutate("", _sql, _message, _opts), do: {:error, :no_local_repo}

  defp mutate(repo_path, sql, message, opts) do
    dolt = Keyword.get(opts, :dolt, Dolt)
    query_opts = Keyword.drop(opts, [:dolt, :sign?, :signing_key])
    sign? = Keyword.get(opts, :sign?, false)
    signing_key = Keyword.get(opts, :signing_key, System.get_env("ROUNDTABLE_BOARD_SIGNING_KEY"))

    with {:ok, _} <- dolt.query(sql, [repo_path: repo_path] ++ query_opts),
         {:ok, _} <-
           dolt.write_files(
             %{
               message: message,
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

  defp work_item_upsert_sql(attrs) do
    with {:ok, id} <- fetch_required(attrs, :id),
         {:ok, repo_ref} <- fetch_required(attrs, :repo_ref),
         {:ok, title} <- fetch_required(attrs, :title),
         {:ok, task_type} <- fetch_required(attrs, :task_type) do
      now = now_iso8601()
      status = fetch_optional(attrs, :status, "queued")
      priority = fetch_optional(attrs, :priority, 100)
      input_payload = json_text(fetch_optional(attrs, :input_payload, %{}))
      surface_route = fetch_optional(attrs, :surface_route, nil)
      public_demo_id = fetch_optional(attrs, :public_demo_id, nil)
      evidence_links_json = json_text_or_nil(fetch_optional(attrs, :evidence_links, nil))
      desired_outcome = json_text_or_nil(fetch_optional(attrs, :desired_outcome, nil))
      retry_policy = json_text_or_nil(fetch_optional(attrs, :retry_policy, nil))
      timeout_policy = json_text_or_nil(fetch_optional(attrs, :timeout_policy, nil))
      hitl_policy = json_text_or_nil(fetch_optional(attrs, :hitl_policy, nil))

      {:ok,
       """
       REPLACE INTO work_items (
         id, repo_ref, branch_ref, source_ref, title, task_type, input_payload,
         surface_route, public_demo_id, evidence_links_json, desired_outcome,
         status, priority, assignee_type, assignee_ref, workflow_ref,
         retry_policy, timeout_policy, hitl_policy,
         created_at, updated_at, closed_at
       ) VALUES (
         '#{escape_sql(id)}', '#{escape_sql(repo_ref)}', #{sql_text(fetch_optional(attrs, :branch_ref, nil))},
         #{sql_text(fetch_optional(attrs, :source_ref, nil))}, '#{escape_sql(title)}',
         '#{escape_sql(task_type)}', '#{escape_sql(input_payload)}',
         #{sql_text(surface_route)}, #{sql_text(public_demo_id)}, #{sql_text(evidence_links_json)},
         #{sql_text(desired_outcome)}, '#{escape_sql(status)}', #{priority},
         #{sql_text(fetch_optional(attrs, :assignee_type, nil))},
         #{sql_text(fetch_optional(attrs, :assignee_ref, nil))},
         #{sql_text(fetch_optional(attrs, :workflow_ref, nil))},
         #{sql_text(retry_policy)}, #{sql_text(timeout_policy)}, #{sql_text(hitl_policy)},
         '#{fetch_optional(attrs, :created_at, now)}', '#{fetch_optional(attrs, :updated_at, now)}',
         #{sql_text(fetch_optional(attrs, :closed_at, nil))}
       );
       """}
    end
  end

  defp attempt_insert_sql(attrs) do
    with {:ok, id} <- fetch_required(attrs, :id),
         {:ok, work_item_id} <- fetch_required(attrs, :work_item_id),
         {:ok, attempt_number} <- fetch_required(attrs, :attempt_number),
         {:ok, runtime_id} <- fetch_required(attrs, :runtime_id),
         {:ok, agent_id} <- fetch_required(attrs, :agent_id),
         {:ok, status} <- fetch_required(attrs, :status) do
      now = now_iso8601()

      {:ok,
       """
       REPLACE INTO work_attempts (
         id, work_item_id, attempt_number, runtime_id, agent_id, status,
         lease_expires_at, started_at, finished_at, exit_class, summary,
         error_excerpt, artifact_ref
       ) VALUES (
         '#{escape_sql(id)}', '#{escape_sql(work_item_id)}', #{attempt_number},
         '#{escape_sql(runtime_id)}', '#{escape_sql(agent_id)}', '#{escape_sql(status)}',
         #{sql_text(fetch_optional(attrs, :lease_expires_at, nil))},
         '#{fetch_optional(attrs, :started_at, now)}',
         #{sql_text(fetch_optional(attrs, :finished_at, nil))},
         #{sql_text(fetch_optional(attrs, :exit_class, nil))},
         #{sql_text(fetch_optional(attrs, :summary, nil))},
         #{sql_text(fetch_optional(attrs, :error_excerpt, nil))},
         #{sql_text(fetch_optional(attrs, :artifact_ref, nil))}
       );
       """}
    end
  end

  defp human_gate_upsert_sql(attrs) do
    with {:ok, id} <- fetch_required(attrs, :id),
         {:ok, work_item_id} <- fetch_required(attrs, :work_item_id),
         {:ok, gate_type} <- fetch_required(attrs, :gate_type),
         {:ok, prompt} <- fetch_required(attrs, :prompt),
         {:ok, options} <- fetch_required(attrs, :options) do
      now = now_iso8601()
      state = fetch_optional(attrs, :state, "open")

      {:ok,
       """
       REPLACE INTO human_gates (
         id, work_item_id, attempt_id, gate_type, prompt, options_json, state,
         decision_json, resolved_by, created_at, resolved_at
       ) VALUES (
         '#{escape_sql(id)}', '#{escape_sql(work_item_id)}',
         #{sql_text(fetch_optional(attrs, :attempt_id, nil))},
         '#{escape_sql(gate_type)}', '#{escape_sql(prompt)}',
         '#{escape_sql(json_text(options))}', '#{escape_sql(state)}',
         #{sql_text(json_text_or_nil(fetch_optional(attrs, :decision, nil)))},
         #{sql_text(fetch_optional(attrs, :resolved_by, nil))},
         '#{fetch_optional(attrs, :created_at, now)}',
         #{sql_text(fetch_optional(attrs, :resolved_at, nil))}
       );
       """}
    end
  end

  defp runtime_heartbeat_upsert_sql(attrs) do
    with {:ok, runtime_id} <- fetch_required(attrs, :runtime_id),
         {:ok, host_label} <- fetch_required(attrs, :host_label),
         {:ok, transport} <- fetch_required(attrs, :transport),
         {:ok, status} <- fetch_required(attrs, :status) do
      now = now_iso8601()

      {:ok,
       """
       REPLACE INTO runtime_heartbeats (
         runtime_id, host_label, transport, status, capabilities_json, last_seen_at,
         active_attempt_id, metadata_json
       ) VALUES (
         '#{escape_sql(runtime_id)}', '#{escape_sql(host_label)}', '#{escape_sql(transport)}',
         '#{escape_sql(status)}', '#{escape_sql(json_text(fetch_optional(attrs, :capabilities, %{})))}',
         '#{fetch_optional(attrs, :last_seen_at, now)}',
         #{sql_text(fetch_optional(attrs, :active_attempt_id, nil))},
         '#{escape_sql(json_text(fetch_optional(attrs, :metadata, %{})))}'
       );
       """}
    end
  end

  defp list_work_items_sql do
    """
    SELECT id, repo_ref, branch_ref, source_ref, title, task_type, input_payload,
           surface_route, public_demo_id, evidence_links_json, desired_outcome,
           status, priority, assignee_type, assignee_ref, workflow_ref,
           retry_policy, timeout_policy, hitl_policy, created_at, updated_at,
           closed_at
    FROM work_items
    ORDER BY priority ASC, created_at ASC;
    """
  end

  defp get_work_item_sql(work_item_id) do
    """
    SELECT id, repo_ref, branch_ref, source_ref, title, task_type, input_payload,
           surface_route, public_demo_id, evidence_links_json, desired_outcome,
           status, priority, assignee_type, assignee_ref, workflow_ref,
           retry_policy, timeout_policy, hitl_policy, created_at, updated_at,
           closed_at
    FROM work_items
    WHERE id = '#{escape_sql(work_item_id)}'
    LIMIT 1;
    """
  end

  defp list_attempts_sql(work_item_id) do
    """
    SELECT id, work_item_id, attempt_number, runtime_id, agent_id, status,
           lease_expires_at, started_at, finished_at, exit_class, summary,
           error_excerpt, artifact_ref
    FROM work_attempts
    WHERE work_item_id = '#{escape_sql(work_item_id)}'
    ORDER BY attempt_number ASC;
    """
  end

  defp get_attempt_sql(attempt_id) do
    """
    SELECT id, work_item_id, attempt_number, runtime_id, agent_id, status,
           lease_expires_at, started_at, finished_at, exit_class, summary,
           error_excerpt, artifact_ref
    FROM work_attempts
    WHERE id = '#{escape_sql(attempt_id)}'
    LIMIT 1;
    """
  end

  defp list_human_gates_sql(work_item_id) do
    """
    SELECT id, work_item_id, attempt_id, gate_type, prompt, options_json, state,
           decision_json, resolved_by, created_at, resolved_at
    FROM human_gates
    WHERE work_item_id = '#{escape_sql(work_item_id)}'
    ORDER BY created_at ASC;
    """
  end

  defp list_runtime_heartbeats_sql do
    """
    SELECT runtime_id, host_label, transport, status, capabilities_json, last_seen_at,
           active_attempt_id, metadata_json
    FROM runtime_heartbeats
    ORDER BY runtime_id ASC;
    """
  end

  defp attempt_event_insert_sql(attrs) do
    with {:ok, id} <- fetch_required(attrs, :id),
         {:ok, attempt_id} <- fetch_required(attrs, :attempt_id),
         {:ok, work_item_id} <- fetch_required(attrs, :work_item_id),
         {:ok, event_type} <- fetch_required(attrs, :event_type) do
      now = now_iso8601()

      {:ok,
       """
       REPLACE INTO work_attempt_events (
         id, attempt_id, work_item_id, event_type, summary, metadata_json, created_at
       ) VALUES (
         '#{escape_sql(id)}', '#{escape_sql(attempt_id)}', '#{escape_sql(work_item_id)}',
         '#{escape_sql(event_type)}', #{sql_text(fetch_optional(attrs, :summary, nil))},
         '#{escape_sql(json_text(fetch_optional(attrs, :metadata, %{})))}',
         '#{fetch_optional(attrs, :created_at, now)}'
       );
       """}
    end
  end

  defp list_attempt_events_sql(attempt_id) do
    """
    SELECT id, attempt_id, work_item_id, event_type, summary, metadata_json, created_at
    FROM work_attempt_events
    WHERE attempt_id = '#{escape_sql(attempt_id)}'
    ORDER BY created_at ASC;
    """
  end

  defp decode_work_item_row(row) do
    %{
      id: row["id"],
      repo_ref: row["repo_ref"],
      branch_ref: row["branch_ref"],
      source_ref: row["source_ref"],
      title: row["title"],
      task_type: row["task_type"],
      input_payload: decode_json(row["input_payload"], %{}),
      surface_route: row["surface_route"],
      public_demo_id: row["public_demo_id"],
      evidence_links: decode_json(row["evidence_links_json"], []),
      desired_outcome: decode_json(row["desired_outcome"], nil),
      status: row["status"],
      priority: normalize_integer(row["priority"], 100),
      assignee_type: row["assignee_type"],
      assignee_ref: row["assignee_ref"],
      workflow_ref: row["workflow_ref"],
      retry_policy: decode_json(row["retry_policy"], nil),
      timeout_policy: decode_json(row["timeout_policy"], nil),
      hitl_policy: decode_json(row["hitl_policy"], nil),
      created_at: row["created_at"],
      updated_at: row["updated_at"],
      closed_at: row["closed_at"]
    }
  end

  defp decode_attempt_row(row) do
    %{
      id: row["id"],
      work_item_id: row["work_item_id"],
      attempt_number: normalize_integer(row["attempt_number"], 0),
      runtime_id: row["runtime_id"],
      agent_id: row["agent_id"],
      status: row["status"],
      lease_expires_at: row["lease_expires_at"],
      started_at: row["started_at"],
      finished_at: row["finished_at"],
      exit_class: row["exit_class"],
      summary: row["summary"],
      error_excerpt: row["error_excerpt"],
      artifact_ref: row["artifact_ref"]
    }
  end

  defp decode_human_gate_row(row) do
    %{
      id: row["id"],
      work_item_id: row["work_item_id"],
      attempt_id: row["attempt_id"],
      gate_type: row["gate_type"],
      prompt: row["prompt"],
      options: decode_json(row["options_json"], []),
      state: row["state"],
      decision: decode_json(row["decision_json"], nil),
      resolved_by: row["resolved_by"],
      created_at: row["created_at"],
      resolved_at: row["resolved_at"]
    }
  end

  defp decode_runtime_heartbeat_row(row) do
    %{
      runtime_id: row["runtime_id"],
      host_label: row["host_label"],
      transport: row["transport"],
      status: row["status"],
      capabilities: decode_json(row["capabilities_json"], %{}),
      last_seen_at: row["last_seen_at"],
      active_attempt_id: row["active_attempt_id"],
      metadata: decode_json(row["metadata_json"], %{})
    }
  end

  defp decode_attempt_event_row(row) do
    %{
      id: row["id"],
      attempt_id: row["attempt_id"],
      work_item_id: row["work_item_id"],
      event_type: row["event_type"],
      summary: row["summary"],
      metadata: decode_json(row["metadata_json"], %{}),
      created_at: row["created_at"]
    }
  end

  defp decode_nullable(nil, _fun), do: nil
  defp decode_nullable(row, fun), do: fun.(row)

  defp fetch_required(attrs, key) do
    case fetch_optional(attrs, key, nil) do
      nil -> {:error, {:missing_field, key}}
      "" -> {:error, {:missing_field, key}}
      value -> {:ok, value}
    end
  end

  defp fetch_optional(attrs, key, default) do
    Map.get(attrs, key, Map.get(attrs, to_string(key), default))
  end

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

  defp normalize_integer(nil, default), do: default
  defp normalize_integer(value, _default) when is_integer(value), do: value

  defp normalize_integer(value, default) do
    case Integer.parse(to_string(value)) do
      {parsed, _} -> parsed
      :error -> default
    end
  end

  defp commit_message(message) do
    "#{message}\n\n[board-schema: durable-execution]"
  end

  defp now_iso8601 do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end

  defp escape_sql(value) do
    value
    |> to_string()
    |> String.replace("'", "''")
  end
end

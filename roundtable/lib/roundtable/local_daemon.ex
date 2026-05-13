defmodule Roundtable.LocalDaemon do
  @moduledoc """
  Runner-side contract for local CLI daemon execution on top of `Roundtable.Board`.

  This module models the operational semantics from item 74:

  - runtime registration and heartbeats
  - poll / claim / release flow
  - lease renewal
  - append-only attempt events
  - structured human-gate requests
  - machine-usable failure classes
  """

  alias Roundtable.{Board, WorkflowDefinitions}

  @default_lease_seconds 300
  @claimable_statuses ["queued", "retry_scheduled", "resumable"]
  @active_statuses ["claimed", "running"]
  @event_types ~w(claimed started progress warning needs_human_gate completed failed cancelled)
  @failure_classes ~w(input_error tool_error runtime_disconnect timeout policy_denied human_rejected unknown_error cancelled)
  @retryable_failure_classes ~w(tool_error runtime_disconnect timeout unknown_error)

  @type claim :: %{work_item: Board.work_item(), attempt: Board.attempt()}

  @spec failure_classes() :: [String.t()]
  def failure_classes, do: @failure_classes

  @spec register_runtime(String.t() | nil, map(), keyword()) :: :ok | {:error, term()}
  def register_runtime(repo_path, attrs, opts \\ []) do
    attrs
    |> Map.put_new(:status, "idle")
    |> Map.put_new(:active_attempt_id, nil)
    |> heartbeat(repo_path, opts)
  end

  @spec heartbeat(map(), String.t() | nil, keyword()) :: :ok | {:error, term()}
  def heartbeat(attrs, repo_path, opts \\ []) when is_map(attrs) do
    board = board_module(opts)

    board.heartbeat_runtime(
      repo_path,
      Map.put_new(attrs, :last_seen_at, now_iso8601()),
      board_opts(opts)
    )
  end

  @spec poll_work(String.t() | nil, keyword()) ::
          {:ok, Board.work_item() | nil} | {:error, term()}
  def poll_work(repo_path, opts \\ []) do
    board = board_module(opts)

    with :ok <- expire_stale_claims(repo_path, opts),
         {:ok, items} <- board.list_work_items(repo_path, board_opts(opts)) do
      statuses = Keyword.get(opts, :statuses, @claimable_statuses)
      runtime_id = Keyword.get(opts, :runtime_id)
      task_types = Keyword.get(opts, :task_types)
      repo_refs = Keyword.get(opts, :repo_refs)
      runtime_profile_ids = Keyword.get(opts, :runtime_profile_ids, [])
      runtime_labels = Keyword.get(opts, :runtime_labels, [])
      transport = Keyword.get(opts, :transport)

      resolved =
        Enum.find_value(items, fn item ->
          with {:ok, resolved_item} <- resolve_work_item(repo_path, item, opts),
               true <-
                 resolved_item.status in statuses and
                   matches_filter?(resolved_item.task_type, task_types) and
                   matches_filter?(resolved_item.repo_ref, repo_refs) and
                   runtime_assignable?(resolved_item, runtime_id) and
                   workflow_module(opts).runtime_allowed?(resolved_item,
                     runtime_id: runtime_id,
                     runtime_profile_ids: runtime_profile_ids,
                     runtime_labels: runtime_labels,
                     transport: transport
                   ) do
            resolved_item
          else
            _ -> nil
          end
        end)

      {:ok, resolved}
    end
  end

  @spec claim_work(String.t() | nil, String.t(), String.t(), keyword()) ::
          {:ok, claim()} | {:error, term()}
  def claim_work(repo_path, runtime_id, work_item_id, opts \\ [])
      when is_binary(runtime_id) and is_binary(work_item_id) do
    board = board_module(opts)
    lease_seconds = Keyword.get(opts, :lease_seconds, @default_lease_seconds)
    agent_id = Keyword.get(opts, :agent_id, runtime_id)

    with :ok <- expire_stale_claims(repo_path, opts),
         {:ok, work_item} <- board.get_work_item(repo_path, work_item_id, board_opts(opts)),
         {:ok, work_item} <- ensure_claimable(work_item),
         {:ok, work_item} <- resolve_work_item(repo_path, work_item, opts),
         {:ok, attempts} <- board.list_attempts(repo_path, work_item_id, board_opts(opts)) do
      now = now_iso8601()

      attempt =
        %{
          id: Keyword.get(opts, :attempt_id, generated_id("att")),
          work_item_id: work_item.id,
          attempt_number: next_attempt_number(attempts),
          runtime_id: runtime_id,
          agent_id: agent_id,
          status: "claimed",
          lease_expires_at: iso_plus_seconds(now, lease_seconds),
          started_at: now,
          summary: "claimed by #{runtime_id}"
        }

      with :ok <- board.append_attempt(repo_path, attempt, board_opts(opts)),
           :ok <-
             board.append_attempt_event(
               repo_path,
               %{
                 id: generated_id("evt"),
                 attempt_id: attempt.id,
                 work_item_id: work_item.id,
                 event_type: "claimed",
                 summary: "claimed by #{runtime_id}",
                 metadata: %{runtime_id: runtime_id, lease_seconds: lease_seconds},
                 created_at: now
               },
               board_opts(opts)
             ),
           :ok <-
             upsert_work_item(
               repo_path,
               Map.merge(work_item, %{
                 status: "claimed",
                 assignee_type: "runtime",
                 assignee_ref: runtime_id,
                 updated_at: now
               }),
               opts
             ),
           :ok <-
             heartbeat(
               %{
                 runtime_id: runtime_id,
                 host_label: Keyword.get(opts, :host_label, runtime_id),
                 transport: Keyword.get(opts, :transport, "local"),
                 status: "busy",
                 active_attempt_id: attempt.id,
                 capabilities: Keyword.get(opts, :capabilities, %{}),
                 metadata: Keyword.get(opts, :metadata, %{})
               },
               repo_path,
               opts
             ),
           {:ok, updated_work_item} <-
             board.get_work_item(repo_path, work_item.id, board_opts(opts)),
           {:ok, updated_attempt} <- board.get_attempt(repo_path, attempt.id, board_opts(opts)) do
        {:ok, %{work_item: updated_work_item, attempt: updated_attempt}}
      end
    end
  end

  @spec start_attempt(String.t() | nil, String.t(), keyword()) ::
          {:ok, Board.attempt()} | {:error, term()}
  def start_attempt(repo_path, attempt_id, opts \\ []) when is_binary(attempt_id) do
    board = board_module(opts)

    with {:ok, attempt} <- board.get_attempt(repo_path, attempt_id, board_opts(opts)),
         {:ok, attempt} <- ensure_attempt_exists(attempt),
         {:ok, work_item} <-
           board.get_work_item(repo_path, attempt.work_item_id, board_opts(opts)),
         {:ok, work_item} <- ensure_work_item_exists(work_item) do
      now = now_iso8601()
      updated_attempt = Map.merge(attempt, %{status: "running", started_at: now})

      with :ok <- board.append_attempt(repo_path, updated_attempt, board_opts(opts)),
           :ok <-
             board.append_attempt_event(
               repo_path,
               %{
                 id: generated_id("evt"),
                 attempt_id: attempt.id,
                 work_item_id: work_item.id,
                 event_type: "started",
                 summary: Keyword.get(opts, :summary, "attempt started"),
                 metadata: %{runtime_id: attempt.runtime_id},
                 created_at: now
               },
               board_opts(opts)
             ),
           :ok <-
             upsert_work_item(
               repo_path,
               Map.merge(work_item, %{
                 status: "running",
                 updated_at: now,
                 assignee_type: "runtime",
                 assignee_ref: attempt.runtime_id
               }),
               opts
             ),
           {:ok, refreshed} <- board.get_attempt(repo_path, attempt.id, board_opts(opts)) do
        {:ok, refreshed}
      end
    end
  end

  @spec append_attempt_event(String.t() | nil, String.t(), map(), keyword()) ::
          {:ok, Board.attempt_event()} | {:error, term()}
  def append_attempt_event(repo_path, attempt_id, attrs, opts \\ []) when is_binary(attempt_id) do
    board = board_module(opts)

    with {:ok, event_type} <-
           validate_event_type(Map.get(attrs, :event_type, Map.get(attrs, "event_type"))),
         {:ok, attempt} <- board.get_attempt(repo_path, attempt_id, board_opts(opts)),
         {:ok, attempt} <- ensure_attempt_exists(attempt) do
      now = Map.get(attrs, :created_at, Map.get(attrs, "created_at", now_iso8601()))

      event = %{
        id: Map.get(attrs, :id, Map.get(attrs, "id", generated_id("evt"))),
        attempt_id: attempt.id,
        work_item_id: attempt.work_item_id,
        event_type: event_type,
        summary: Map.get(attrs, :summary, Map.get(attrs, "summary")),
        metadata: Map.get(attrs, :metadata, Map.get(attrs, "metadata", %{})),
        created_at: now
      }

      updated_attempt =
        attempt
        |> Map.put(:summary, event.summary || attempt.summary)

      with :ok <- board.append_attempt_event(repo_path, event, board_opts(opts)),
           :ok <- board.append_attempt(repo_path, updated_attempt, board_opts(opts)) do
        {:ok, event}
      end
    end
  end

  @spec renew_lease(String.t() | nil, String.t(), keyword()) ::
          {:ok, Board.attempt()} | {:error, term()}
  def renew_lease(repo_path, attempt_id, opts \\ []) when is_binary(attempt_id) do
    board = board_module(opts)
    lease_seconds = Keyword.get(opts, :lease_seconds, @default_lease_seconds)

    with {:ok, attempt} <- board.get_attempt(repo_path, attempt_id, board_opts(opts)),
         {:ok, attempt} <- ensure_attempt_exists(attempt),
         :ok <- ensure_runtime_match(attempt, Keyword.get(opts, :runtime_id)),
         {:ok, work_item} <-
           board.get_work_item(repo_path, attempt.work_item_id, board_opts(opts)),
         {:ok, work_item} <- ensure_work_item_exists(work_item) do
      now = now_iso8601()

      updated_attempt =
        attempt
        |> Map.put(:lease_expires_at, iso_plus_seconds(now, lease_seconds))

      with :ok <- board.append_attempt(repo_path, updated_attempt, board_opts(opts)),
           :ok <- upsert_work_item(repo_path, Map.merge(work_item, %{updated_at: now}), opts),
           {:ok, refreshed} <- board.get_attempt(repo_path, attempt.id, board_opts(opts)) do
        {:ok, refreshed}
      end
    end
  end

  @spec request_human_gate(String.t() | nil, String.t(), map(), keyword()) ::
          {:ok, %{gate: Board.human_gate(), attempt: Board.attempt()}} | {:error, term()}
  def request_human_gate(repo_path, attempt_id, attrs, opts \\ []) when is_binary(attempt_id) do
    board = board_module(opts)

    with {:ok, attempt} <- board.get_attempt(repo_path, attempt_id, board_opts(opts)),
         {:ok, attempt} <- ensure_attempt_exists(attempt),
         {:ok, work_item} <-
           board.get_work_item(repo_path, attempt.work_item_id, board_opts(opts)),
         {:ok, work_item} <- ensure_work_item_exists(work_item) do
      now = now_iso8601()

      gate =
        %{
          id: Map.get(attrs, :id, Map.get(attrs, "id", generated_id("gate"))),
          work_item_id: work_item.id,
          attempt_id: attempt.id,
          gate_type: Map.get(attrs, :gate_type, Map.get(attrs, "gate_type", "clarify")),
          prompt: Map.get(attrs, :prompt, Map.get(attrs, "prompt", "Human input required")),
          options: Map.get(attrs, :options, Map.get(attrs, "options", [])),
          state: "open",
          created_at: now
        }

      updated_attempt =
        attempt
        |> Map.merge(%{
          status: "awaiting_human_input",
          exit_class: "needs_human_gate",
          summary: gate.prompt
        })

      with :ok <- board.open_human_gate(repo_path, gate, board_opts(opts)),
           :ok <- board.append_attempt(repo_path, updated_attempt, board_opts(opts)),
           :ok <-
             board.append_attempt_event(
               repo_path,
               %{
                 id: generated_id("evt"),
                 attempt_id: attempt.id,
                 work_item_id: work_item.id,
                 event_type: "needs_human_gate",
                 summary: gate.prompt,
                 metadata: %{gate_type: gate.gate_type, options: gate.options},
                 created_at: now
               },
               board_opts(opts)
             ),
           :ok <-
             upsert_work_item(
               repo_path,
               Map.merge(work_item, %{status: "awaiting_human_input", updated_at: now}),
               opts
             ),
           {:ok, [created_gate | _]} <- list_latest_gate(repo_path, work_item.id, board, opts),
           {:ok, refreshed_attempt} <- board.get_attempt(repo_path, attempt.id, board_opts(opts)) do
        {:ok, %{gate: created_gate, attempt: refreshed_attempt}}
      end
    end
  end

  @spec complete_attempt(String.t() | nil, String.t(), keyword()) ::
          {:ok, claim()} | {:error, term()}
  def complete_attempt(repo_path, attempt_id, opts \\ []) when is_binary(attempt_id) do
    board = board_module(opts)

    with {:ok, attempt} <- board.get_attempt(repo_path, attempt_id, board_opts(opts)),
         {:ok, attempt} <- ensure_attempt_exists(attempt),
         {:ok, work_item} <-
           board.get_work_item(repo_path, attempt.work_item_id, board_opts(opts)),
         {:ok, work_item} <- ensure_work_item_exists(work_item) do
      now = now_iso8601()
      summary = Keyword.get(opts, :summary, attempt.summary || "attempt completed")

      updated_attempt =
        attempt
        |> Map.merge(%{
          status: "succeeded",
          finished_at: now,
          exit_class: "success",
          summary: summary
        })

      updated_work_item =
        work_item
        |> Map.merge(%{
          status: "succeeded",
          updated_at: now,
          closed_at: now,
          assignee_type: "runtime",
          assignee_ref: attempt.runtime_id
        })

      with :ok <- board.append_attempt(repo_path, updated_attempt, board_opts(opts)),
           :ok <-
             board.append_attempt_event(
               repo_path,
               %{
                 id: generated_id("evt"),
                 attempt_id: attempt.id,
                 work_item_id: work_item.id,
                 event_type: "completed",
                 summary: summary,
                 metadata: %{runtime_id: attempt.runtime_id},
                 created_at: now
               },
               board_opts(opts)
             ),
           :ok <- upsert_work_item(repo_path, updated_work_item, opts),
           {:ok, refreshed_work_item} <-
             board.get_work_item(repo_path, work_item.id, board_opts(opts)),
           {:ok, refreshed_attempt} <- board.get_attempt(repo_path, attempt.id, board_opts(opts)) do
        {:ok, %{work_item: refreshed_work_item, attempt: refreshed_attempt}}
      end
    end
  end

  @spec fail_attempt(String.t() | nil, String.t(), keyword()) :: {:ok, claim()} | {:error, term()}
  def fail_attempt(repo_path, attempt_id, opts \\ []) when is_binary(attempt_id) do
    board = board_module(opts)

    with {:ok, failure_class} <-
           validate_failure_class(Keyword.get(opts, :failure_class, "unknown_error")),
         {:ok, attempt} <- board.get_attempt(repo_path, attempt_id, board_opts(opts)),
         {:ok, attempt} <- ensure_attempt_exists(attempt),
         {:ok, work_item} <-
           board.get_work_item(repo_path, attempt.work_item_id, board_opts(opts)),
         {:ok, work_item} <- ensure_work_item_exists(work_item),
         {:ok, work_item} <- resolve_work_item(repo_path, work_item, opts),
         {:ok, attempts} <- board.list_attempts(repo_path, work_item.id, board_opts(opts)) do
      now = now_iso8601()
      retryable? = retryable_failure?(failure_class) and can_retry?(work_item, attempts)
      next_work_status = if retryable?, do: "retry_scheduled", else: "failed"
      summary = Keyword.get(opts, :summary, Map.get(attempt, :summary) || failure_class)
      error_excerpt = Keyword.get(opts, :error_excerpt)

      updated_attempt =
        attempt
        |> Map.merge(%{
          status: "failed",
          finished_at: now,
          exit_class: failure_class,
          summary: summary,
          error_excerpt: error_excerpt
        })

      updated_work_item =
        work_item
        |> Map.merge(%{
          status: next_work_status,
          updated_at: now,
          closed_at: if(retryable?, do: nil, else: now)
        })

      with :ok <- board.append_attempt(repo_path, updated_attempt, board_opts(opts)),
           :ok <-
             board.append_attempt_event(
               repo_path,
               %{
                 id: generated_id("evt"),
                 attempt_id: attempt.id,
                 work_item_id: work_item.id,
                 event_type: "failed",
                 summary: summary,
                 metadata: %{failure_class: failure_class, retryable: retryable?},
                 created_at: now
               },
               board_opts(opts)
             ),
           :ok <- upsert_work_item(repo_path, updated_work_item, opts),
           {:ok, refreshed_work_item} <-
             board.get_work_item(repo_path, work_item.id, board_opts(opts)),
           {:ok, refreshed_attempt} <- board.get_attempt(repo_path, attempt.id, board_opts(opts)) do
        {:ok, %{work_item: refreshed_work_item, attempt: refreshed_attempt}}
      end
    end
  end

  @spec release_claim(String.t() | nil, String.t(), keyword()) ::
          {:ok, claim()} | {:error, term()}
  def release_claim(repo_path, attempt_id, opts \\ []) when is_binary(attempt_id) do
    board = board_module(opts)

    with {:ok, attempt} <- board.get_attempt(repo_path, attempt_id, board_opts(opts)),
         {:ok, attempt} <- ensure_attempt_exists(attempt),
         {:ok, work_item} <-
           board.get_work_item(repo_path, attempt.work_item_id, board_opts(opts)),
         {:ok, work_item} <- ensure_work_item_exists(work_item) do
      now = now_iso8601()
      next_status = Keyword.get(opts, :release_to_status, "queued")
      summary = Keyword.get(opts, :summary, "claim released")

      updated_attempt =
        attempt
        |> Map.merge(%{
          status: "cancelled",
          finished_at: now,
          exit_class: "cancelled",
          summary: summary
        })

      updated_work_item =
        work_item
        |> Map.merge(%{
          status: next_status,
          updated_at: now,
          assignee_type: nil,
          assignee_ref: nil,
          closed_at: nil
        })

      with :ok <- board.append_attempt(repo_path, updated_attempt, board_opts(opts)),
           :ok <-
             board.append_attempt_event(
               repo_path,
               %{
                 id: generated_id("evt"),
                 attempt_id: attempt.id,
                 work_item_id: work_item.id,
                 event_type: "cancelled",
                 summary: summary,
                 metadata: %{release_to_status: next_status},
                 created_at: now
               },
               board_opts(opts)
             ),
           :ok <- upsert_work_item(repo_path, updated_work_item, opts),
           {:ok, refreshed_work_item} <-
             board.get_work_item(repo_path, work_item.id, board_opts(opts)),
           {:ok, refreshed_attempt} <- board.get_attempt(repo_path, attempt.id, board_opts(opts)) do
        {:ok, %{work_item: refreshed_work_item, attempt: refreshed_attempt}}
      end
    end
  end

  @spec expire_stale_claims(String.t() | nil, keyword()) :: :ok | {:error, term()}
  def expire_stale_claims(repo_path, opts \\ []) do
    board = board_module(opts)
    now = Keyword.get(opts, :now, now_iso8601())

    with {:ok, items} <- board.list_work_items(repo_path, board_opts(opts)) do
      items
      |> Enum.filter(&(&1.status in @active_statuses))
      |> Enum.reduce_while(:ok, fn item, :ok ->
        with {:ok, attempts} <- board.list_attempts(repo_path, item.id, board_opts(opts)) do
          case List.last(attempts) do
            %{lease_expires_at: lease} = attempt when is_binary(lease) ->
              if lease_expired?(lease, now) do
                case fail_attempt(
                       repo_path,
                       attempt.id,
                       Keyword.merge(opts,
                         failure_class: "runtime_disconnect",
                         summary: "daemon lease expired before renewal"
                       )
                     ) do
                  {:ok, _} -> {:cont, :ok}
                  {:error, reason} -> {:halt, {:error, reason}}
                end
              else
                {:cont, :ok}
              end

            _ ->
              {:cont, :ok}
          end
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp board_module(opts), do: Keyword.get(opts, :board, Board)
  defp workflow_module(opts), do: Keyword.get(opts, :workflow, WorkflowDefinitions)

  defp board_opts(opts),
    do:
      Keyword.drop(opts, [
        :board,
        :runtime_id,
        :lease_seconds,
        :agent_id,
        :statuses,
        :task_types,
        :repo_refs,
        :workflow,
        :runtime_profile_ids,
        :runtime_labels,
        :now,
        :host_label,
        :transport,
        :capabilities,
        :metadata,
        :summary,
        :failure_class,
        :error_excerpt,
        :release_to_status
      ])

  defp ensure_claimable(nil), do: {:error, :work_item_not_found}

  defp ensure_claimable(%{status: status} = item) when status in @claimable_statuses,
    do: {:ok, item}

  defp ensure_claimable(%{status: status}), do: {:error, {:work_item_not_claimable, status}}

  defp ensure_attempt_exists(nil), do: {:error, :attempt_not_found}
  defp ensure_attempt_exists(attempt), do: {:ok, attempt}

  defp ensure_work_item_exists(nil), do: {:error, :work_item_not_found}
  defp ensure_work_item_exists(item), do: {:ok, item}

  defp ensure_runtime_match(_attempt, nil), do: :ok
  defp ensure_runtime_match(%{runtime_id: runtime_id}, runtime_id), do: :ok

  defp ensure_runtime_match(%{runtime_id: actual}, expected),
    do: {:error, {:runtime_mismatch, expected, actual}}

  defp validate_event_type(type) when type in @event_types, do: {:ok, type}

  defp validate_event_type(type) when is_binary(type),
    do: if(type in @event_types, do: {:ok, type}, else: {:error, {:invalid_event_type, type}})

  defp validate_event_type(type), do: {:error, {:invalid_event_type, type}}

  defp validate_failure_class(type) when type in @failure_classes, do: {:ok, type}

  defp validate_failure_class(type) when is_binary(type),
    do:
      if(type in @failure_classes,
        do: {:ok, type},
        else: {:error, {:invalid_failure_class, type}}
      )

  defp validate_failure_class(type), do: {:error, {:invalid_failure_class, type}}

  defp runtime_assignable?(%{assignee_type: nil}, _runtime_id), do: true
  defp runtime_assignable?(%{assignee_type: "runtime", assignee_ref: nil}, _runtime_id), do: true

  defp runtime_assignable?(%{assignee_type: "runtime", assignee_ref: assigned}, runtime_id)
       when is_binary(runtime_id),
       do: assigned in [nil, runtime_id]

  defp runtime_assignable?(_item, _runtime_id), do: true

  defp matches_filter?(_value, nil), do: true
  defp matches_filter?(value, allowed) when is_list(allowed), do: value in allowed

  defp upsert_work_item(repo_path, work_item, opts) do
    board = board_module(opts)
    board.create_work_item(repo_path, work_item, board_opts(opts))
  end

  defp resolve_work_item(repo_path, work_item, opts) do
    workflow_module(opts).resolve_work_item(repo_path, work_item, workflow_opts(opts))
  end

  defp next_attempt_number([]), do: 1

  defp next_attempt_number(attempts),
    do: attempts |> Enum.map(& &1.attempt_number) |> Enum.max(fn -> 0 end) |> Kernel.+(1)

  defp retryable_failure?(failure_class), do: failure_class in @retryable_failure_classes

  defp can_retry?(work_item, attempts) do
    max_attempts =
      case work_item.retry_policy do
        %{"max_attempts" => max} -> normalize_integer(max, 1)
        %{max_attempts: max} -> normalize_integer(max, 1)
        _ -> 1
      end

    length(attempts) < max_attempts
  end

  defp list_latest_gate(repo_path, work_item_id, board, opts) do
    with {:ok, gates} <- board.list_human_gates(repo_path, work_item_id, board_opts(opts)) do
      {:ok, Enum.reverse(gates)}
    end
  end

  defp workflow_opts(opts), do: Keyword.drop(opts, [:board, :workflow])

  defp lease_expired?(lease_iso8601, now_iso8601) do
    with {:ok, lease, _} <- DateTime.from_iso8601(lease_iso8601),
         {:ok, now, _} <- DateTime.from_iso8601(now_iso8601) do
      DateTime.compare(lease, now) in [:lt, :eq]
    else
      _ -> false
    end
  end

  defp iso_plus_seconds(now_iso8601, seconds) do
    {:ok, now, _} = DateTime.from_iso8601(now_iso8601)
    now |> DateTime.add(seconds, :second) |> DateTime.to_iso8601()
  end

  defp generated_id(prefix) do
    "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"
  end

  defp now_iso8601 do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end

  defp normalize_integer(nil, default), do: default
  defp normalize_integer(value, _default) when is_integer(value), do: value

  defp normalize_integer(value, default) do
    case Integer.parse(to_string(value)) do
      {parsed, _} -> parsed
      :error -> default
    end
  end
end

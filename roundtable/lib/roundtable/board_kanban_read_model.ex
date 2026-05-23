defmodule Roundtable.BoardKanbanReadModel do
  @moduledoc """
  Browse-first kanban projection over canonical board tables.

  This module derives current lane placement, card summaries, and recent
  attempt context without mutating or collapsing the underlying board lineage.
  """

  alias Roundtable.Board

  @queued_statuses ~w(queued retry_scheduled resumable)
  @active_statuses ~w(claimed running)
  @healthy_terminal_exit_classes ~w(success cancelled)
  @lane_order ~w(gated attention running queued closed_with_issue done)

  @spec snapshot(String.t() | nil, keyword()) :: {:ok, map()} | {:error, term()}
  def snapshot(repo_path, opts \\ []) do
    board = Keyword.get(opts, :board, Board)
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with {:ok, items} <- board.list_work_items(repo_path, board_opts(opts)),
         {:ok, runtimes} <- board.list_runtime_heartbeats(repo_path, board_opts(opts)) do
      runtime_index = Map.new(runtimes, &{&1.runtime_id, &1})

      cards =
        items
        |> Enum.map(&build_card(&1, repo_path, board, runtime_index, now, opts))
        |> Enum.sort_by(&{lane_rank(&1.lane), &1.priority, &1.updated_at || "", &1.work_item_id})

      {:ok,
       %{
         repo_path: repo_path,
         generated_at: DateTime.to_iso8601(now),
         lanes: build_lanes(cards),
         cards: cards,
         filters: build_filters(cards),
         counts: lane_counts(cards)
       }}
    end
  end

  defp build_card(item, repo_path, board, runtime_index, now, opts) do
    {:ok, attempts} = board.list_attempts(repo_path, item.id, board_opts(opts))
    {:ok, gates} = board.list_human_gates(repo_path, item.id, board_opts(opts))

    current_attempt = current_attempt(attempts)
    runtime = runtime_for_attempt(current_attempt, runtime_index)
    open_gate = Enum.find(gates, &(&1.state == "open"))
    gate_state = derive_gate_state(gates)
    {events, recent_event} = current_attempt_events(repo_path, current_attempt, board, opts)
    lease_state = derive_lease_state(item, current_attempt, now)
    runtime_status = derive_runtime_status(runtime)
    status_conflict? = status_conflict?(item, current_attempt)
    superseded? = superseded_attempt?(current_attempt)
    owner_ref = derive_owner_ref(item, current_attempt)
    desired_outcome = desired_outcome_summary(item)
    next_signal = derive_next_signal(open_gate, recent_event, current_attempt, desired_outcome)
    freshness_state = derive_freshness_state(item, current_attempt, open_gate, runtime, recent_event, now)
    evidence_links = derive_evidence_links(item)

    alert_refs =
      []
      |> maybe_add_alert(open_gate && "open_human_gate")
      |> maybe_add_alert(lease_state in ["stale", "expired", "missing"] && "stale_lease")
      |> maybe_add_alert(runtime_status == "offline" && "runtime_offline")
      |> maybe_add_alert(runtime_status == "degraded" && "runtime_degraded")
      |> maybe_add_alert(status_conflict? && "status_conflict")
      |> maybe_add_alert(superseded? && "attempt_superseded")
      |> maybe_add_alert(
        current_attempt && current_attempt.exit_class not in [nil | @healthy_terminal_exit_classes] &&
          current_attempt.status in ["failed", "superseded"] && "terminal_failure"
      )

    lane = derive_lane(item, current_attempt, open_gate, lease_state, runtime_status, alert_refs)

    %{
      work_item_id: item.id,
      lane: lane,
      title: item.title,
      repo_ref: item.repo_ref,
      branch_ref: item.branch_ref,
      task_type: item.task_type,
      priority: item.priority,
      status: item.status,
      source_ref: item.source_ref,
      owner_ref: owner_ref,
      desired_outcome: desired_outcome,
      next_signal: next_signal,
      gate_prompt: open_gate && open_gate.prompt,
      freshness_state: freshness_state,
      evidence_links: evidence_links,
      current_attempt_ref: current_attempt && current_attempt.id,
      attempt_number: current_attempt && current_attempt.attempt_number,
      attempt_status: current_attempt && current_attempt.status,
      runtime_ref: runtime && runtime.runtime_id,
      runtime_status: runtime_status,
      open_gate_ref: open_gate && open_gate.id,
      gate_type: open_gate && open_gate.gate_type,
      gate_state: gate_state,
      lease_state: lease_state,
      superseded_by_attempt_ref: nil,
      summary: derive_summary(item, current_attempt, open_gate, runtime, recent_event, alert_refs),
      badge_refs:
        build_badges(item, current_attempt, runtime_status, gate_state, lease_state, alert_refs),
      alert_refs: alert_refs,
      updated_at: freshness_timestamp(item, current_attempt, open_gate, runtime, recent_event),
      recent_events: Enum.take(Enum.reverse(events), 5),
      attempts: attempts,
      gates: gates,
      runtime: runtime
    }
  end

  defp board_opts(opts), do: Keyword.drop(opts, [:board, :now])

  defp current_attempt([]), do: nil

  defp current_attempt(attempts) do
    attempts
    |> Enum.sort_by(fn attempt ->
      {attempt.attempt_number || 0, attempt.started_at || "", attempt.id || ""}
    end, :desc)
    |> List.first()
  end

  defp runtime_for_attempt(nil, _runtime_index), do: nil
  defp runtime_for_attempt(attempt, runtime_index), do: Map.get(runtime_index, attempt.runtime_id)

  defp current_attempt_events(_repo_path, nil, _board, _opts), do: {[], nil}

  defp current_attempt_events(repo_path, attempt, board, opts) do
    case board.list_attempt_events(repo_path, attempt.id, board_opts(opts)) do
      {:ok, events} -> {events, List.last(events)}
      {:error, _} -> {[], nil}
    end
  end

  defp derive_gate_state([]), do: "none"

  defp derive_gate_state(gates) do
    cond do
      Enum.any?(gates, &(&1.state == "open")) -> "open"
      Enum.any?(gates, &(&1.state == "resolved")) -> "resolved"
      true -> "closed"
    end
  end

  defp derive_lease_state(item, attempt, now) do
    cond do
      is_nil(attempt) ->
        if item.status in @queued_statuses, do: "not_required", else: "missing"

      attempt.status not in @active_statuses ->
        "not_required"

      is_nil(attempt.lease_expires_at) ->
        "missing"

      true ->
        case parse_datetime(attempt.lease_expires_at) do
          nil ->
            "missing"

          expires_at ->
            diff = DateTime.diff(expires_at, now, :second)

            cond do
              diff < 0 -> "expired"
              diff <= 60 -> "stale"
              true -> "healthy"
            end
        end
    end
  end

  defp derive_runtime_status(nil), do: "unknown"
  defp derive_runtime_status(runtime), do: runtime.status || "unknown"

  defp status_conflict?(item, attempt) do
    case attempt do
      nil -> false
      %{status: attempt_status} -> item.status in @queued_statuses and attempt_status in @active_statuses
    end
  end

  defp superseded_attempt?(nil), do: false
  defp superseded_attempt?(attempt), do: attempt.status == "superseded"

  defp derive_lane(item, attempt, open_gate, lease_state, runtime_status, alert_refs) do
    cond do
      open_gate ->
        "gated"

      attention?(attempt, lease_state, runtime_status, alert_refs) ->
        "attention"

      active?(item, attempt) ->
        "running"

      item.status in @queued_statuses ->
        "queued"

      terminal_issue?(item, attempt) ->
        "closed_with_issue"

      true ->
        "done"
    end
  end

  defp attention?(attempt, lease_state, runtime_status, alert_refs) do
    attempt && attempt.status in @active_statuses &&
      (lease_state in ["stale", "expired", "missing"] ||
         runtime_status in ["offline", "degraded"] ||
         alert_refs != [])
  end

  defp active?(item, attempt) do
    item.status in @active_statuses || (attempt && attempt.status in @active_statuses)
  end

  defp terminal_issue?(item, attempt) do
    item.status == "failed" ||
      (attempt &&
         (attempt.status == "failed" ||
            attempt.exit_class not in [nil | @healthy_terminal_exit_classes]))
  end

  defp derive_summary(item, attempt, open_gate, runtime, recent_event, alert_refs) do
    cond do
      open_gate ->
        "Awaiting #{open_gate.gate_type} gate"

      "stale_lease" in alert_refs ->
        "Attempt lease needs attention"

      "runtime_offline" in alert_refs ->
        "Owning runtime is offline"

      recent_event && recent_event.summary not in [nil, ""] ->
        recent_event.summary

      attempt && attempt.summary not in [nil, ""] ->
        attempt.summary

      runtime ->
        "Owned by #{runtime.host_label || runtime.runtime_id}"

      true ->
        item.title
    end
  end

  defp derive_owner_ref(item, nil), do: item.assignee_ref

  defp derive_owner_ref(item, attempt) do
    Map.get(attempt, :agent_id) || item.assignee_ref
  end

  defp desired_outcome_summary(item) do
    outcome = item.desired_outcome

    cond do
      is_map(outcome) and is_binary(outcome["result"]) -> outcome["result"]
      is_map(outcome) and is_binary(outcome[:result]) -> outcome[:result]
      is_binary(outcome) -> outcome
      true -> nil
    end
  end

  defp derive_next_signal(open_gate, recent_event, current_attempt, desired_outcome) do
    cond do
      open_gate && open_gate.prompt not in [nil, ""] ->
        open_gate.prompt

      recent_event && recent_event.summary not in [nil, ""] ->
        recent_event.summary

      current_attempt && Map.get(current_attempt, :error_excerpt) not in [nil, ""] ->
        Map.get(current_attempt, :error_excerpt)

      desired_outcome not in [nil, ""] ->
        desired_outcome

      true ->
        nil
    end
  end

  defp derive_evidence_links(item) do
    []
    |> Kernel.++(surface_links(item))
    |> Kernel.++(declared_evidence_links(item))
    |> Enum.uniq_by(& &1.href)
  end

  defp surface_links(item) do
    [surface_link(Map.get(item, :surface_route) || Map.get(item, "surface_route"))]
    |> Enum.reject(&is_nil/1)
  end

  defp surface_link(path) when is_binary(path) do
    if String.starts_with?(path, "/") do
      %{label: surface_label(path), href: path, kind: "surface"}
    end
  end

  defp surface_link(_path), do: nil

  defp surface_label("/forgejo-shell/reports"), do: "Open reports"
  defp surface_label("/forgejo-shell"), do: "Open Forgejo shell"
  defp surface_label("/board"), do: "Open board"
  defp surface_label(path), do: "Open #{path}"

  defp declared_evidence_links(item) do
    explicit_links = Map.get(item, :evidence_links) || Map.get(item, "evidence_links") || []
    public_demo_id = Map.get(item, :public_demo_id) || Map.get(item, "public_demo_id")

    explicit_links(explicit_links) ++ public_demo_links(public_demo_id)
  end

  defp explicit_links(links) when is_list(links) do
    links
    |> Enum.map(&normalize_explicit_link/1)
    |> Enum.reject(&is_nil/1)
  end

  defp explicit_links(_links), do: []

  defp normalize_explicit_link(%{href: href} = link) when is_binary(href) do
    %{
      label: Map.get(link, :label) || "Open evidence",
      href: href,
      kind: Map.get(link, :kind) || "evidence"
    }
  end

  defp normalize_explicit_link(%{"href" => href} = link) when is_binary(href) do
    %{
      label: Map.get(link, "label") || "Open evidence",
      href: href,
      kind: Map.get(link, "kind") || "evidence"
    }
  end

  defp normalize_explicit_link(_link), do: nil

  defp public_demo_links(nil), do: []
  defp public_demo_links(""), do: []

  defp public_demo_links(demo_id) when is_binary(demo_id) do
    [
      %{label: "Open #{demo_id} demo", href: "/forgejo-shell?demo=#{demo_id}", kind: "demo"},
      %{label: "Open #{demo_id} report", href: "/forgejo-shell/reports#report-#{demo_id}", kind: "report"}
    ]
  end

  defp build_badges(item, attempt, runtime_status, gate_state, lease_state, alert_refs) do
    []
    |> add_badge("priority:high", item.priority && item.priority <= 25)
    |> add_badge("task:#{item.task_type}", item.task_type)
    |> add_badge("runtime:#{runtime_status}", runtime_status not in [nil, "unknown"])
    |> add_badge("gate:#{gate_state}", gate_state != "none")
    |> add_badge("lease:#{lease_state}", lease_state not in ["not_required", nil])
    |> add_badge("attempt:superseded", attempt && attempt.status == "superseded")
    |> add_badge("retry:scheduled", item.status == "retry_scheduled")
    |> add_badge("result:failed", terminal_issue?(item, attempt))
    |> add_badge("result:succeeded", item.status == "succeeded")
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
    |> Kernel.++(Enum.map(alert_refs, &"alert:#{&1}"))
  end

  defp freshness_timestamp(item, attempt, gate, runtime, recent_event) do
    [
      item.updated_at,
      attempt && Map.get(attempt, :finished_at),
      attempt && Map.get(attempt, :started_at),
      gate && gate.created_at,
      runtime && runtime.last_seen_at,
      recent_event && recent_event.created_at
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.max(fn -> item.updated_at || item.created_at end)
  end

  defp derive_freshness_state(item, attempt, gate, runtime, recent_event, now) do
    case freshness_timestamp(item, attempt, gate, runtime, recent_event) |> parse_datetime() do
      nil ->
        "unknown"

      timestamp ->
        age_seconds = DateTime.diff(now, timestamp, :second)

        cond do
          age_seconds <= 900 -> "fresh"
          age_seconds <= 3600 -> "watch"
          true -> "stale"
        end
    end
  end

  defp add_badge(list, _badge, false), do: list
  defp add_badge(list, _badge, nil), do: list
  defp add_badge(list, badge, _truthy), do: [badge | list]

  defp maybe_add_alert(list, false), do: list
  defp maybe_add_alert(list, nil), do: list
  defp maybe_add_alert(list, alert), do: [alert | list]

  defp build_lanes(cards) do
    @lane_order
    |> Enum.map(fn lane ->
      %{
        id: lane,
        title: lane_title(lane),
        cards: Enum.filter(cards, &(&1.lane == lane))
      }
    end)
  end

  defp build_filters(cards) do
    %{
      repos: cards |> Enum.map(& &1.repo_ref) |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort(),
      statuses: cards |> Enum.map(& &1.status) |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort(),
      runtimes:
        cards |> Enum.map(& &1.runtime_ref) |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort(),
      gates:
        cards
        |> Enum.map(& &1.gate_state)
        |> Enum.reject(&(&1 in [nil, "none"]))
        |> Enum.uniq()
        |> Enum.sort()
    }
  end

  defp lane_counts(cards) do
    Enum.reduce(@lane_order, %{}, fn lane, acc ->
      Map.put(acc, lane, Enum.count(cards, &(&1.lane == lane)))
    end)
  end

  defp lane_rank(lane), do: Enum.find_index(@lane_order, &(&1 == lane)) || length(@lane_order)

  defp lane_title("queued"), do: "Queued"
  defp lane_title("running"), do: "Running"
  defp lane_title("gated"), do: "Gated"
  defp lane_title("attention"), do: "Attention"
  defp lane_title("done"), do: "Done"
  defp lane_title("closed_with_issue"), do: "Closed With Issue"
  defp lane_title(other), do: other

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  defp parse_datetime(_value), do: nil
end

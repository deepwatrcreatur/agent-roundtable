defmodule RoundtableWeb.BoardLive do
  @moduledoc """
  Browse-first board surface backed by the kanban read model.
  """

  use Phoenix.LiveView

  alias Roundtable.BoardKanbanReadModel

  @impl true
  def mount(params, _session, socket) do
    {:ok, load_board(socket, normalize_params(params))}
  end

  defp load_board(socket, params) do
    repo_path = board_repo_path()
    board_module = board_module()

    socket =
      socket
      |> assign(:params, params)
      |> assign(:repo_path, repo_path)
      |> assign(:filters, %{})
      |> assign(:counts, %{})
      |> assign(:selected_card, nil)
      |> assign(:lanes, [])
      |> assign(:cards, [])
      |> assign(:error, nil)

    case BoardKanbanReadModel.snapshot(repo_path, board: board_module) do
      {:ok, snapshot} ->
        cards = filter_cards(snapshot.cards, params)
        selected_card = find_selected_card(cards, params)

        socket
        |> assign(:snapshot_generated_at, snapshot.generated_at)
        |> assign(:filters, snapshot.filters)
        |> assign(:counts, snapshot.counts)
        |> assign(:cards, cards)
        |> assign(:lanes, filter_lanes(snapshot.lanes, cards))
        |> assign(:selected_card, selected_card)

      {:error, :no_local_repo} ->
        assign(socket, :error, "No local board repo is configured. Set ROUNDTABLE_BOARD_REPO_PATH or ROUNDTABLE_LOCAL_PATH.")

      {:error, reason} ->
        assign(socket, :error, "Failed to load board state: #{inspect(reason)}")
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 1320px; margin: 0 auto; padding: 2rem 1rem 4rem;">
      <header style="display: grid; grid-template-columns: minmax(0, 1.8fr) minmax(320px, 1fr); gap: 1rem; align-items: start; margin-bottom: 1.5rem;">
        <div>
          <div style="display: inline-flex; align-items: center; gap: 0.45rem; border: 1px solid #30363d; border-radius: 999px; padding: 0.35rem 0.75rem; color: #58a6ff; font-size: 0.76rem; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.85rem;">
            Browse-first board
          </div>
          <h1 style="font-size: clamp(2rem, 4vw, 3rem); line-height: 1.04; color: #f0f6fc; margin-bottom: 0.55rem;">
            Vaglio Board
          </h1>
          <p style="color: #8b949e; line-height: 1.6; max-width: 54rem; margin-bottom: 1rem;">
            This surface renders the derived kanban view over canonical board state. Lanes and badges are convenience projections; the underlying attempts, gates, and runtime heartbeats remain authoritative.
          </p>
          <div style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
            <a href="/" style={cta_style(:secondary)}>Landing</a>
            <a href="/forgejo-shell" style={cta_style(:secondary)}>Forgejo Shell</a>
            <span :if={@repo_path not in [nil, ""]} style="display: inline-flex; align-items: center; border: 1px solid #30363d; border-radius: 999px; padding: 0.72rem 1rem; color: #8b949e; font-size: 0.82rem;">
              Repo: {@repo_path}
            </span>
          </div>
        </div>

        <div style="background: linear-gradient(180deg, rgba(22,27,34,0.96), rgba(13,17,23,0.96)); border: 1px solid #30363d; border-radius: 16px; padding: 1rem;">
          <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.5rem;">Operator questions</div>
          <ul style="margin: 0; padding-left: 1rem; color: #8b949e; line-height: 1.6;">
            <li>What is running right now?</li>
            <li>What needs a human or operator decision?</li>
            <li>What looks stale or unsafe?</li>
            <li>Which runtime owns the latest attempt?</li>
          </ul>
        </div>
      </header>

      <.error_banner :if={@error} msg={@error} />

      <section :if={!@error} style="margin-bottom: 1.25rem;">
        <div style="display: grid; gap: 0.75rem;">
          <div style="display: flex; gap: 0.55rem; flex-wrap: wrap;">
            <.filter_group
              label="Repo"
              param="repo"
              current={Map.get(@params, "repo")}
              values={@filters.repos}
              params={@params}
            />
            <.filter_group
              label="Status"
              param="status"
              current={Map.get(@params, "status")}
              values={@filters.statuses}
              params={@params}
            />
            <.filter_group
              label="Runtime"
              param="runtime"
              current={Map.get(@params, "runtime")}
              values={@filters.runtimes}
              params={@params}
            />
            <.filter_group
              label="Gate"
              param="gate"
              current={Map.get(@params, "gate")}
              values={@filters.gates}
              params={@params}
            />
          </div>

          <div style="display: flex; gap: 0.65rem; flex-wrap: wrap; align-items: center;">
            <.count_chip :for={{lane, count} <- @counts} lane={lane} count={count} />
            <span :if={@snapshot_generated_at} style="color: #8b949e; font-size: 0.8rem; margin-left: auto;">
              Snapshot {@snapshot_generated_at}
            </span>
          </div>
        </div>
      </section>

      <section :if={!@error} style="display: grid; grid-template-columns: minmax(0, 2fr) minmax(320px, 1fr); gap: 1rem; align-items: start;">
        <div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 0.85rem; align-items: start;">
          <div :for={lane <- @lanes} style="background: #0d1117; border: 1px solid #30363d; border-radius: 14px; padding: 0.85rem; min-height: 18rem;">
            <div style="display: flex; justify-content: space-between; gap: 0.75rem; align-items: baseline; margin-bottom: 0.75rem;">
              <h2 style="margin: 0; color: #f0f6fc; font-size: 0.95rem;">{lane.title}</h2>
              <span style="color: #8b949e; font-size: 0.82rem;">{length(lane.cards)}</span>
            </div>

            <div style="display: grid; gap: 0.65rem;">
              <a
                :for={card <- lane.cards}
                href={board_path(@params, %{"work_item_id" => card.work_item_id})}
                style={card_style(@selected_card && @selected_card.work_item_id == card.work_item_id, card.lane)}
              >
                <div style="display: flex; justify-content: space-between; gap: 0.75rem; margin-bottom: 0.35rem;">
                  <div style="color: #f0f6fc; font-weight: 600; line-height: 1.35;">{card.title}</div>
                  <div style="color: #8b949e; font-size: 0.78rem; white-space: nowrap;">{card.work_item_id}</div>
                </div>
                <div style="color: #58a6ff; font-size: 0.78rem; margin-bottom: 0.35rem;">{card.repo_ref}</div>
                <div style="display: flex; gap: 0.45rem; flex-wrap: wrap; color: #8b949e; font-size: 0.76rem; margin-bottom: 0.35rem;">
                  <span :if={card.owner_ref}>Owner {card.owner_ref}</span>
                  <span :if={card.source_ref}>Source {card.source_ref}</span>
                  <span>Freshness {freshness_label(card.freshness_state)}</span>
                </div>
                <div style="color: #8b949e; font-size: 0.83rem; line-height: 1.45; margin-bottom: 0.55rem;">{card.summary}</div>
                <div :if={card.next_signal} style="color: #c9d1d9; font-size: 0.8rem; line-height: 1.4; margin-bottom: 0.55rem;">
                  Next signal: {card.next_signal}
                </div>
                <div :if={card.evidence_links != []} style="display: flex; gap: 0.45rem; flex-wrap: wrap; margin-bottom: 0.55rem;">
                  <a
                    :for={link <- Enum.take(card.evidence_links, 2)}
                    href={link.href}
                    style={evidence_link_style(link.kind)}
                  >
                    {link.label}
                  </a>
                </div>
                <div style="display: flex; gap: 0.35rem; flex-wrap: wrap;">
                  <span :for={badge <- Enum.take(card.badge_refs, 4)} style={badge_style(badge)}>{badge}</span>
                </div>
              </a>
            </div>
          </div>
        </div>

        <aside style="background: linear-gradient(180deg, rgba(22,27,34,0.96), rgba(13,17,23,0.96)); border: 1px solid #30363d; border-radius: 14px; padding: 1rem; position: sticky; top: 1rem;">
          <%= if @selected_card do %>
            <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.45rem;">Selected card</div>
            <h2 style="margin: 0 0 0.35rem; color: #f0f6fc; font-size: 1.05rem;">{@selected_card.title}</h2>
            <div style="color: #8b949e; font-size: 0.82rem; margin-bottom: 0.75rem;">
              {@selected_card.work_item_id} · {@selected_card.repo_ref}
            </div>

            <div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 0.55rem; margin-bottom: 0.9rem;">
              <.detail_metric label="Lane" value={@selected_card.lane} />
              <.detail_metric label="Status" value={@selected_card.status} />
              <.detail_metric label="Owner" value={@selected_card.owner_ref || "unassigned"} />
              <.detail_metric label="Source" value={@selected_card.source_ref || "n/a"} />
              <.detail_metric label="Runtime" value={@selected_card.runtime_ref || "unassigned"} />
              <.detail_metric label="Lease" value={@selected_card.lease_state} />
              <.detail_metric label="Gate" value={@selected_card.gate_type || @selected_card.gate_state} />
              <.detail_metric label="Attempt" value={detail_attempt(@selected_card)} />
              <.detail_metric label="Freshness" value={freshness_label(@selected_card.freshness_state)} />
              <.detail_metric label="Updated" value={@selected_card.updated_at || "unknown"} />
            </div>

            <div style="margin-bottom: 0.9rem;">
              <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.4rem;">Next signal</div>
              <div style="background: rgba(13,17,23,0.86); border: 1px solid #30363d; border-radius: 10px; padding: 0.75rem; color: #c9d1d9; font-size: 0.84rem; line-height: 1.5;">
                {@selected_card.next_signal || "No immediate signal recorded"}
              </div>
            </div>

            <div :if={@selected_card.desired_outcome} style="margin-bottom: 0.9rem;">
              <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.4rem;">Desired outcome</div>
              <div style="background: rgba(13,17,23,0.86); border: 1px solid #30363d; border-radius: 10px; padding: 0.75rem; color: #c9d1d9; font-size: 0.84rem; line-height: 1.5;">
                {@selected_card.desired_outcome}
              </div>
            </div>

            <div :if={@selected_card.evidence_links != []} style="margin-bottom: 0.9rem;">
              <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.4rem;">Related evidence</div>
              <div style="display: flex; gap: 0.45rem; flex-wrap: wrap;">
                <a :for={link <- @selected_card.evidence_links} href={link.href} style={evidence_link_style(link.kind)}>
                  {link.label}
                </a>
              </div>
            </div>

            <div style="margin-bottom: 0.9rem;">
              <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.4rem;">Alerts</div>
              <div style="display: flex; gap: 0.4rem; flex-wrap: wrap;">
                <span :for={alert <- @selected_card.alert_refs} style="background: rgba(248,81,73,0.12); border: 1px solid rgba(248,81,73,0.3); color: #ff7b72; border-radius: 999px; padding: 0.25rem 0.55rem; font-size: 0.76rem;">
                  {alert}
                </span>
                <span :if={@selected_card.alert_refs == []} style="color: #8b949e; font-size: 0.84rem;">No active alerts</span>
              </div>
            </div>

            <div style="margin-bottom: 0.9rem;">
              <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.4rem;">Recent events</div>
              <div style="display: grid; gap: 0.45rem;">
                <div :for={event <- @selected_card.recent_events} style="background: rgba(13,17,23,0.86); border: 1px solid #30363d; border-radius: 10px; padding: 0.65rem;">
                  <div style="display: flex; justify-content: space-between; gap: 0.75rem; margin-bottom: 0.2rem;">
                    <span style="color: #f0f6fc; font-weight: 600; font-size: 0.84rem;">{event.event_type}</span>
                    <span style="color: #8b949e; font-size: 0.76rem;">{event.created_at}</span>
                  </div>
                  <div style="color: #8b949e; font-size: 0.82rem; line-height: 1.4;">{event.summary || "No summary"}</div>
                </div>
                <span :if={@selected_card.recent_events == []} style="color: #8b949e; font-size: 0.84rem;">No recent attempt events</span>
              </div>
            </div>

            <div>
              <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.4rem;">Lineage</div>
              <div style="display: grid; gap: 0.45rem;">
                <div :for={attempt <- Enum.reverse(@selected_card.attempts)} style="background: rgba(13,17,23,0.86); border: 1px solid #30363d; border-radius: 10px; padding: 0.65rem;">
                  <div style="display: flex; justify-content: space-between; gap: 0.75rem; margin-bottom: 0.2rem;">
                    <span style="color: #f0f6fc; font-weight: 600; font-size: 0.84rem;">Attempt #{attempt.attempt_number}</span>
                    <span style="color: #8b949e; font-size: 0.76rem;">{attempt.status}</span>
                  </div>
                  <div style="color: #8b949e; font-size: 0.82rem; line-height: 1.4;">
                    {attempt.summary || "No summary"}<%= if attempt.exit_class, do: " · #{attempt.exit_class}" %>
                  </div>
                </div>
              </div>
            </div>
          <% else %>
            <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.45rem;">Card detail</div>
            <h2 style="margin: 0 0 0.55rem; color: #f0f6fc; font-size: 1.05rem;">Select a work item</h2>
            <p style="margin: 0; color: #8b949e; line-height: 1.55;">
              Pick any card to inspect its latest attempt, runtime ownership, gate state, and recent execution history without digging through raw board rows.
            </p>
          <% end %>
        </aside>
      </section>
    </div>
    """
  end

  attr :msg, :string, required: true
  defp error_banner(assigns) do
    ~H"""
    <div style="background: rgba(248,81,73,0.12); border: 1px solid rgba(248,81,73,0.3); border-radius: 12px; padding: 0.95rem 1rem; color: #ff7b72; margin-bottom: 1rem;">
      {@msg}
    </div>
    """
  end

  attr :label, :string, required: true
  attr :param, :string, required: true
  attr :current, :string, default: nil
  attr :values, :list, default: []
  attr :params, :map, required: true
  defp filter_group(assigns) do
    ~H"""
    <div style="display: flex; gap: 0.35rem; flex-wrap: wrap; align-items: center;">
      <span style="color: #8b949e; font-size: 0.8rem;">{@label}</span>
      <a href={board_path(@params, Map.delete(@params, @param))} style={filter_style(is_nil(@current) || @current == "")}>all</a>
      <a :for={value <- @values} href={board_path(@params, %{@param => value})} style={filter_style(@current == value)}>{value}</a>
    </div>
    """
  end

  attr :lane, :string, required: true
  attr :count, :integer, required: true
  defp count_chip(assigns) do
    ~H"""
    <span style="display: inline-flex; align-items: center; gap: 0.35rem; background: #161b22; border: 1px solid #30363d; border-radius: 999px; padding: 0.32rem 0.65rem; color: #c9d1d9; font-size: 0.8rem;">
      {assigns.lane} <strong style="color: #f0f6fc;">{@count}</strong>
    </span>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true
  defp detail_metric(assigns) do
    ~H"""
    <div style="background: rgba(13,17,23,0.86); border: 1px solid #30363d; border-radius: 10px; padding: 0.65rem;">
      <div style="color: #58a6ff; font-size: 0.75rem; text-transform: uppercase; margin-bottom: 0.2rem;">{@label}</div>
      <div style="color: #f0f6fc; font-size: 0.88rem; line-height: 1.35;">{@value}</div>
    </div>
    """
  end

  defp board_module do
    Application.get_env(:roundtable, :board_module, Roundtable.Board)
  end

  defp normalize_params(params) when is_map(params), do: params
  defp normalize_params(_params), do: %{}

  defp board_repo_path do
    Application.get_env(:roundtable, :board_repo_path) ||
      System.get_env("ROUNDTABLE_BOARD_REPO_PATH") ||
      System.get_env("ROUNDTABLE_LOCAL_PATH")
  end

  defp filter_cards(cards, params) do
    Enum.filter(cards, fn card ->
      matches?(card.repo_ref, params["repo"]) and
        matches?(card.status, params["status"]) and
        matches?(card.runtime_ref, params["runtime"]) and
        matches?(card.gate_state, params["gate"])
    end)
  end

  defp matches?(_value, nil), do: true
  defp matches?(_value, ""), do: true
  defp matches?(value, filter), do: value == filter

  defp filter_lanes(lanes, cards) do
    ids = MapSet.new(Enum.map(cards, & &1.work_item_id))

    Enum.map(lanes, fn lane ->
      %{lane | cards: Enum.filter(lane.cards, &MapSet.member?(ids, &1.work_item_id))}
    end)
  end

  defp find_selected_card(cards, %{"work_item_id" => work_item_id}) do
    Enum.find(cards, &(&1.work_item_id == work_item_id))
  end

  defp find_selected_card(cards, _params), do: List.first(cards)

  defp board_path(params, overrides) do
    merged =
      params
      |> Map.merge(overrides)
      |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Enum.into(%{})

    query = URI.encode_query(merged)
    if query == "", do: "/board", else: "/board?#{query}"
  end

  defp detail_attempt(card) do
    case {card.current_attempt_ref, card.attempt_number} do
      {nil, _} -> "none"
      {_, nil} -> card.current_attempt_ref
      {_, n} -> "##{n}"
    end
  end

  defp cta_style(:secondary) do
    "display: inline-flex; align-items: center; justify-content: center; text-decoration: none; background: transparent; color: #c9d1d9; border-radius: 999px; padding: 0.72rem 1rem; font-weight: 600; border: 1px solid #30363d;"
  end

  defp filter_style(true) do
    "display: inline-flex; align-items: center; text-decoration: none; background: #1f6feb; color: #f0f6fc; border-radius: 999px; padding: 0.25rem 0.55rem; font-size: 0.78rem; border: 1px solid #1f6feb;"
  end

  defp filter_style(false) do
    "display: inline-flex; align-items: center; text-decoration: none; background: #161b22; color: #8b949e; border-radius: 999px; padding: 0.25rem 0.55rem; font-size: 0.78rem; border: 1px solid #30363d;"
  end

  defp card_style(true, lane) do
    base_card_style(lane) <> " box-shadow: 0 0 0 1px rgba(88,166,255,0.6);"
  end

  defp card_style(false, lane), do: base_card_style(lane)

  defp base_card_style(lane) do
    accent =
      case lane do
        "gated" -> "#d29922"
        "attention" -> "#ff7b72"
        "running" -> "#3fb950"
        "queued" -> "#58a6ff"
        "closed_with_issue" -> "#f85149"
        _ -> "#30363d"
      end

    "display: block; text-decoration: none; background: linear-gradient(180deg, rgba(22,27,34,0.96), rgba(13,17,23,0.96)); border: 1px solid #{accent}; border-radius: 12px; padding: 0.8rem;"
  end

  defp badge_style(_badge) do
    "display: inline-flex; align-items: center; background: rgba(88,166,255,0.1); border: 1px solid rgba(88,166,255,0.22); color: #8ec7ff; border-radius: 999px; padding: 0.18rem 0.45rem; font-size: 0.72rem;"
  end

  defp evidence_link_style("report") do
    "display: inline-flex; align-items: center; text-decoration: none; background: rgba(210,153,34,0.12); border: 1px solid rgba(210,153,34,0.3); color: #f2cc60; border-radius: 999px; padding: 0.22rem 0.55rem; font-size: 0.74rem;"
  end

  defp evidence_link_style("demo") do
    "display: inline-flex; align-items: center; text-decoration: none; background: rgba(88,166,255,0.12); border: 1px solid rgba(88,166,255,0.28); color: #8ec7ff; border-radius: 999px; padding: 0.22rem 0.55rem; font-size: 0.74rem;"
  end

  defp evidence_link_style(_kind) do
    "display: inline-flex; align-items: center; text-decoration: none; background: rgba(63,185,80,0.12); border: 1px solid rgba(63,185,80,0.28); color: #7ee787; border-radius: 999px; padding: 0.22rem 0.55rem; font-size: 0.74rem;"
  end

  defp freshness_label("fresh"), do: "Fresh"
  defp freshness_label("watch"), do: "Watch"
  defp freshness_label("stale"), do: "Stale"
  defp freshness_label(_other), do: "Unknown"
end

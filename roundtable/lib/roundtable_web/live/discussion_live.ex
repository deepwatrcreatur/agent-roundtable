defmodule RoundtableWeb.DiscussionLive do
  @moduledoc """
  Owner dashboard for the roundtable discussion.

  Reads `ROUNDTABLE_REPO` env var for the GitHub repo slug.
  Polls GitHub Issues every 30s to show current discussion state.

  Owner actions:
  - Inject new question → creates a GitHub Issue
  - Trigger next round → starts the orchestrator for unsatisfied questions
  - View each question's satisfaction state and comment thread
  """

  use Phoenix.LiveView

  alias Roundtable.CLI

  @poll_interval_ms 30_000

  @impl true
  def mount(_params, _session, socket) do
    repo = System.get_env("ROUNDTABLE_REPO", "")
    brief_path = System.get_env("ROUNDTABLE_BRIEF", "docs/design/BRIEF.md")

    if connected?(socket), do: schedule_poll()

    socket =
      socket
      |> assign(:repo, repo)
      |> assign(:brief_path, brief_path)
      |> assign(:inject_text, "")
      |> assign(:running, false)
      |> assign(:flash_msg, nil)
      |> assign(:conflicts, [])
      |> assign(:selected_number, nil)
      |> assign(:expanded_claim, nil)
      |> load_state(repo)

    {:ok, socket}
  end

  @impl true
  def handle_info(:poll, socket) do
    schedule_poll()
    {:noreply, load_state(socket, socket.assigns.repo)}
  end

  @impl true
  def handle_info({:roundtable_event, {:round_complete, _n} = event}, socket) do
    msg = format_event(event)
    {:noreply, assign(socket, running: false, flash_msg: msg)}
  end

  @impl true
  def handle_info({:roundtable_event, event}, socket) do
    msg = format_event(event)
    {:noreply, assign(socket, :flash_msg, msg)}
  end

  @impl true
  def handle_event("inject_question", %{"text" => text}, socket) when byte_size(text) > 0 do
    repo = socket.assigns.repo

    case CLI.inject_question(repo, text) do
      {:ok, number} ->
        socket =
          socket
          |> assign(:inject_text, "")
          |> assign(:flash_msg, "Created issue ##{number}")
          |> load_state(repo)

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, assign(socket, :flash_msg, "Error: #{inspect(reason)}")}
    end
  end

  def handle_event("inject_question", _params, socket) do
    {:noreply, assign(socket, :flash_msg, "Question text cannot be empty.")}
  end

  @impl true
  def handle_event("trigger_round", _params, socket) do
    if socket.assigns.running do
      {:noreply, assign(socket, :flash_msg, "A round is already running.")}
    else
      repo = socket.assigns.repo
      brief_path = socket.assigns.brief_path
      lv_pid = self()

      Task.start(fn ->
        questions = open_questions(socket.assigns.questions)

        CLI.start_discussion(brief_path,
          repo: repo,
          on_event: fn event ->
            send(lv_pid, {:roundtable_event, event})
          end
        )

        send(lv_pid, {:roundtable_event, {:round_complete, length(questions)}})
      end)

      {:noreply, assign(socket, running: true, flash_msg: "Round started…")}
    end
  end

  @impl true
  def handle_event("dismiss_flash", _params, socket) do
    {:noreply, assign(socket, :flash_msg, nil)}
  end

  @impl true
  def handle_event("select_question", %{"number" => number}, socket) do
    number = String.to_integer(number)

    {:noreply,
     socket
     |> assign(:selected_number, number)
     |> assign(:expanded_claim, nil)}
  end

  @impl true
  def handle_event("toggle_claim_detail", %{"index" => index}, socket) do
    index = String.to_integer(index)

    expanded =
      if socket.assigns.expanded_claim == index,
        do: nil,
        else: index

    {:noreply, assign(socket, :expanded_claim, expanded)}
  end

  @impl true
  def handle_event("resolve_conflict", %{"path" => path, "vcs" => vcs}, socket) do
    local_path = System.get_env("ROUNDTABLE_LOCAL_PATH")
    vcs_atom = String.to_existing_atom(vcs)

    case CLI.resolve_conflict(local_path, path, vcs_atom) do
      :ok ->
        socket =
          socket
          |> assign(:flash_msg, "Resolved #{path} in #{vcs}")
          |> load_state(socket.assigns.repo)

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, assign(socket, :flash_msg, "Failed to resolve: #{inspect(reason)}")}
    end
  end

  # ----- render -----

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 900px; margin: 0 auto; padding: 2rem 1rem;">
      <header style="margin-bottom: 2rem;">
        <h1 style="font-size: 1.4rem; color: #f0f6fc; margin-bottom: 0.25rem;">
          Roundtable
        </h1>
        <p style="color: #8b949e; font-size: 0.85rem;">
          {@repo}
          <span :if={@running} style="color: #d29922; margin-left: 1rem;">● running</span>
        </p>
      </header>

      <.flash_banner :if={@flash_msg} msg={@flash_msg} />

      <section style="margin-bottom: 2rem;">
        <h2 style="font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;">
          Questions
        </h2>

        <div :if={map_size(@questions) == 0} style="color: #8b949e; font-style: italic;">
          No roundtable issues found. Create one below or push a BRIEF.md.
        </div>

        <.question_card :for={{number, q} <- Enum.sort(@questions)} number={number} q={q} />
      </section>

      <section :if={selected_question(@questions, @selected_number)} style="margin-bottom: 2rem;">
        <h2 style="font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;">
          Evidence Map
        </h2>
        <.claim_panel
          question={selected_question(@questions, @selected_number)}
          issue_number={@selected_number}
          expanded_claim={@expanded_claim}
        />
      </section>

      <section :if={length(@conflicts) > 0} style="margin-bottom: 2rem;">
        <h2 style="font-size: 1rem; color: #f78166; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;">
          Logical Conflicts
        </h2>
        <.conflict_card :for={c <- @conflicts} c={c} />
      </section>

      <section style="margin-bottom: 2rem;">
        <h2 style="font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;">
          Inject Question
        </h2>
        <form phx-submit="inject_question" style="display: flex; gap: 0.5rem; align-items: flex-start;">
          <textarea
            name="text"
            placeholder="New question text…"
            rows="3"
            style="flex: 1; background: #161b22; border: 1px solid #30363d; border-radius: 6px;
                   color: #c9d1d9; padding: 0.5rem 0.75rem; font-family: inherit; font-size: 0.9rem; resize: vertical;"
          >{@inject_text}</textarea>
          <button type="submit" style={btn_style(:primary)}>Add</button>
        </form>
      </section>

      <section>
        <h2 style="font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;">
          Controls
        </h2>
        <div style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
          <button phx-click="trigger_round" disabled={@running} style={btn_style(:action)}>
            <%= if @running, do: "Running…", else: "Trigger round" %>
          </button>
        </div>
      </section>
    </div>
    """
  end

  # ----- components -----

  defp flash_banner(assigns) do
    ~H"""
    <div style="background: #1c2128; border: 1px solid #30363d; border-radius: 6px;
                padding: 0.75rem 1rem; margin-bottom: 1.5rem; display: flex;
                justify-content: space-between; align-items: center;">
      <span style="color: #c9d1d9; font-size: 0.9rem;">{@msg}</span>
      <button phx-click="dismiss_flash" style="background: none; border: none; color: #8b949e;
                cursor: pointer; font-size: 1.1rem; line-height: 1;">×</button>
    </div>
    """
  end

  defp question_card(assigns) do
    ~H"""
    <div style={"border: 1px solid #{border_color(@q.satisfaction)}; border-radius: 6px;
                 padding: 1rem; margin-bottom: 0.75rem; background: #161b22;"}>
      <div style="display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 0.5rem;">
        <a href={@q.url} target="_blank" style="font-weight: 600; font-size: 0.95rem; color: #f0f6fc;">
          #{@number} {@q.title}
        </a>
        <.satisfaction_badge sat={@q.satisfaction} />
      </div>
      <div :if={length(@q.claims || []) > 0} style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem;">
        <div style="font-size: 0.78rem; color: #8b949e;">
          {length(@q.claims)} provenance-tagged claim(s)
        </div>
        <button phx-click="select_question" phx-value-number={@number} style={btn_style(:ghost)}>
          View evidence
        </button>
      </div>
      <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-top: 0.5rem;">
        <.label_chip :for={l <- @q.labels} label={l} />
      </div>
      <div style="font-size: 0.8rem; color: #8b949e; margin-top: 0.5rem;">
        {@q.comment_count} comment(s) ·
        <span style={"color: #{if @q.state == :open, do: "#3fb950", else: "#8b949e"};"}>
          {if @q.state == :open, do: "open", else: "closed"}
        </span>
      </div>
    </div>
    """
  end

  defp claim_panel(assigns) do
    ~H"""
    <div style="border: 1px solid #30363d; border-radius: 6px; background: #161b22; padding: 1rem;">
      <div style="margin-bottom: 0.75rem;">
        <div style="font-weight: 600; color: #f0f6fc;">Issue ##{@issue_number}: {@question.title}</div>
        <div style="font-size: 0.78rem; color: #8b949e;">
          Evidence chain from current transcript comments and provenance markers
        </div>
      </div>

      <div :if={@question.claims == []} style="color: #8b949e; font-style: italic;">
        No provenance-tagged claims found yet. Look for `[observed]`, `[testimony]`, or `[inferred]` markers in agent turns.
      </div>

      <div :for={{claim, idx} <- Enum.with_index(@question.claims)} style="border-top: 1px solid #21262d; padding: 0.75rem 0;">
        <div style="display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap;">
          <.provenance_badge tag={claim.tag} />
          <span :if={claim.agent} style="font-size: 0.72rem; color: #8b949e; text-transform: uppercase;">
            {claim.agent}
          </span>
          <span style="color: #c9d1d9; font-size: 0.9rem;">{claim.claim}</span>
        </div>
        <div style="font-size: 0.75rem; color: #8b949e; margin-top: 0.35rem;">
          {chain_text(claim)}
        </div>
        <button
          :if={claim.detail}
          phx-click="toggle_claim_detail"
          phx-value-index={idx}
          style={btn_style(:ghost)}
        >
          <%= if @expanded_claim == idx, do: "Hide raw detail", else: "View raw detail" %>
        </button>
        <pre
          :if={claim.detail && @expanded_claim == idx}
          style="margin-top: 0.5rem; background: #0d1117; border: 1px solid #30363d; border-radius: 6px; padding: 0.75rem; color: #c9d1d9; overflow-x: auto; white-space: pre-wrap;"
        ><%= claim.detail %></pre>
      </div>
    </div>
    """
  end

  defp provenance_badge(assigns) do
    {text, color, bg} =
      case assigns.tag do
        :observed -> {"observed", "#3fb950", "rgba(63,185,80,0.12)"}
        :testimony -> {"testimony", "#58a6ff", "rgba(88,166,255,0.12)"}
        :inferred -> {"inferred", "#bc8cff", "rgba(188,140,255,0.12)"}
        _ -> {"unknown", "#8b949e", "rgba(139,148,158,0.12)"}
      end

    assigns = assign(assigns, text: text, color: color, bg: bg)

    ~H"""
    <span style={"border: 1px solid #{@color}; background: #{@bg}; color: #{@color}; font-size: 0.7rem;
                 padding: 0.1rem 0.45rem; border-radius: 999px; text-transform: uppercase; font-weight: 600;"}>
      {@text}
    </span>
    """
  end

  defp satisfaction_badge(assigns) do
    {text, color} =
      case assigns.sat do
        :satisfied -> {"✓ satisfied", "#3fb950"}
        :satisfied_conditional -> {"~ conditional", "#d29922"}
        :no_objection -> {"· no objection", "#58a6ff"}
        :needs_more_evidence -> {"○ needs evidence", "#f78166"}
        _ -> {"– unknown", "#8b949e"}
      end

    assigns = assign(assigns, text: text, color: color)

    ~H"""
    <span style={"font-size: 0.75rem; color: #{@color}; font-weight: 600;"}>{@text}</span>
    """
  end

  defp label_chip(assigns) do
    ~H"""
    <span style="background: #21262d; border: 1px solid #30363d; border-radius: 12px;
                 padding: 0.1rem 0.6rem; font-size: 0.75rem; color: #8b949e;">
      {@label}
    </span>
    """
  end

  defp conflict_card(assigns) do
    ~H"""
    <div style="border: 1px solid #da3633; border-radius: 6px; padding: 1rem;
                margin-bottom: 0.75rem; background: #161b22; display: flex;
                justify-content: space-between; align-items: center;">
      <div>
        <div style="color: #f0f6fc; font-weight: 600; font-size: 0.9rem;">
          {@c.path}
        </div>
        <div style="color: #8b949e; font-size: 0.75rem; margin-top: 0.25rem;">
          Unresolved evolution in {@c.vcs |> Atom.to_string() |> String.upcase()}
        </div>
      </div>
      <div style="display: flex; align-items: center; gap: 0.75rem;">
        <button phx-click="resolve_conflict" phx-value-path={@c.path} phx-value-vcs={@c.vcs}
                style={btn_style(:action)}>
          Resolve
        </button>
        <.vcs_badge vcs={@c.vcs} />
      </div>
    </div>
    """
  end

  defp vcs_badge(assigns) do
    {text, color} =
      case assigns.vcs do
        :jj -> {"jj", "#58a6ff"}
        :dolt -> {"dolt", "#3fb950"}
        _ -> {"vcs", "#8b949e"}
      end

    assigns = assign(assigns, text: text, color: color)

    ~H"""
    <span style={"border: 1px solid #{@color}; color: #{@color}; font-size: 0.65rem;
                  padding: 0.1rem 0.4rem; border-radius: 4px; text-transform: uppercase;
                  font-weight: bold;"}>{@text}</span>
    """
  end

  # ----- helpers -----

  defp load_state(socket, "") do
    socket
    |> assign(:questions, %{})
    |> assign(:conflicts, [])
    |> assign(:selected_number, nil)
  end

  defp load_state(socket, repo) do
    # Fetch GitHub issues
    socket =
      case CLI.get_discussion_state(repo) do
        {:ok, state} ->
          socket
          |> assign(:questions, state)
          |> preserve_selected_question(state)

        {:error, _} -> assign(socket, :questions, %{})
      end

    # Fetch logical conflicts if a local path is configured
    # (In v1 we use ROUNDTABLE_LOCAL_PATH env var)
    local_path = System.get_env("ROUNDTABLE_LOCAL_PATH")

    case CLI.get_conflicts(local_path) do
      {:ok, conflicts} -> assign(socket, :conflicts, conflicts)
      {:error, _} -> assign(socket, :conflicts, [])
    end
  end

  defp open_questions(questions) do
    questions
    |> Enum.filter(fn {_, q} -> q.state == :open end)
    |> Enum.map(fn {number, q} -> %{id: q.title, issue_number: number, state: :open} end)
  end

  defp schedule_poll, do: Process.send_after(self(), :poll, @poll_interval_ms)

  defp border_color(:satisfied), do: "#238636"
  defp border_color(:satisfied_conditional), do: "#9e6a03"
  defp border_color(:no_objection), do: "#1f6feb"
  defp border_color(:needs_more_evidence), do: "#da3633"
  defp border_color(_), do: "#30363d"

  defp btn_style(:primary) do
    "background: #238636; color: #fff; border: none; border-radius: 6px; padding: 0.5rem 1rem;
     cursor: pointer; font-family: inherit; font-size: 0.9rem;"
  end

  defp btn_style(:action) do
    "background: #1f6feb; color: #fff; border: none; border-radius: 6px; padding: 0.5rem 1rem;
     cursor: pointer; font-family: inherit; font-size: 0.9rem;"
  end

  defp btn_style(:ghost) do
    "background: transparent; color: #58a6ff; border: none; padding: 0.25rem 0;
     cursor: pointer; font-family: inherit; font-size: 0.8rem;"
  end

  defp format_event({:round_start, id, n}), do: "#{id}: round #{n} started"
  defp format_event({:agent_done, agent, _issue}), do: "#{agent} posted"
  defp format_event({:question_satisfied, id, n}), do: "#{id} satisfied after #{n} round(s)"
  defp format_event({:question_max_rounds, id}), do: "#{id} needs human review"
  defp format_event({:round_complete, n}), do: "Round complete — #{n} question(s) processed"
  defp format_event(_), do: nil

  defp selected_question(questions, selected_number) when is_integer(selected_number),
    do: Map.get(questions, selected_number)

  defp selected_question(_questions, _selected_number), do: nil

  defp preserve_selected_question(socket, state) do
    selected = socket.assigns[:selected_number]

    if is_integer(selected) and Map.has_key?(state, selected) do
      socket
    else
      assign(socket, :selected_number, default_selected_number(state))
    end
  end

  defp default_selected_number(state) do
    case Enum.sort(Map.keys(state)) do
      [first | _] -> first
      [] -> nil
    end
  end

  defp chain_text(%{tag: :observed, detail: detail}) when is_binary(detail),
    do: "Epistemic chain: observed fact -> raw detail"

  defp chain_text(%{tag: :observed}), do: "Epistemic chain: observed fact"
  defp chain_text(%{tag: :testimony}), do: "Epistemic chain: testimony -> reported claim"
  defp chain_text(%{tag: :inferred}), do: "Epistemic chain: inferred claim -> synthesis"
  defp chain_text(_claim), do: "Epistemic chain unavailable"
end

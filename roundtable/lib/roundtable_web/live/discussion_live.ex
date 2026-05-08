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
    <div class="rt-shell">
      <header class="rt-header">
        <div class="rt-header-copy">
          <div class="rt-code-chip">[+] vaglio / live roundtable</div>
          <div class="rt-terminal">
            <div class="rt-terminal-title">opencode-style deliberation console</div>
            <div class="rt-title">Discussion Control Surface</div>
            <p class="rt-meta rt-meta--header">{@repo}</p>
          </div>
        </div>
        <span class={run_status_class(@running)}>
          <%= if @running, do: "[·] round running", else: "[+] idle" %>
        </span>
      </header>

      <.flash_banner :if={@flash_msg} msg={@flash_msg} />

      <section class="rt-section">
        <div class="rt-section-head">
          <h2 class="rt-section-title">[+] Questions</h2>
          <p class="rt-section-note">Live GitHub issue state, labels, and satisfaction markers.</p>
        </div>

        <div :if={map_size(@questions) == 0} class="rt-panel rt-panel--empty">
          No roundtable issues found. Create one below or push a BRIEF.md.
        </div>

        <div class="rt-stack">
          <.question_card :for={{number, q} <- Enum.sort(@questions)} number={number} q={q} />
        </div>
      </section>

      <section :if={length(@conflicts) > 0} class="rt-section">
        <div class="rt-section-head">
          <h2 class="rt-section-title">[-] Logical Conflicts</h2>
          <p class="rt-section-note">Local VCS paths that still need manual reconciliation.</p>
        </div>
        <div class="rt-stack">
          <.conflict_card :for={c <- @conflicts} c={c} />
        </div>
      </section>

      <section class="rt-section">
        <div class="rt-section-head">
          <h2 class="rt-section-title">[+] Inject Question</h2>
          <p class="rt-section-note">Open a new discussion issue without leaving Vaglio.</p>
        </div>
        <form phx-submit="inject_question" class="rt-form">
          <label class="rt-field">
            <span class="rt-field-label">Prompt</span>
            <textarea
              class="rt-textarea"
              name="text"
              placeholder="New question text..."
              rows="4"
            >{@inject_text}</textarea>
          </label>
          <div class="rt-actions">
            <button type="submit" class={button_class(:primary)}>[+] add issue</button>
          </div>
        </form>
      </section>

      <section class="rt-section">
        <div class="rt-section-head">
          <h2 class="rt-section-title">[x] Controls</h2>
          <p class="rt-section-note">Start the next orchestrated pass for unsatisfied questions.</p>
        </div>
        <div class="rt-actions rt-actions--wrap">
          <button phx-click="trigger_round" disabled={@running} class={button_class(:action)}>
            <%= if @running, do: "[·] running...", else: "[>] trigger round" %>
          </button>
        </div>
      </section>
    </div>
    """
  end

  # ----- components -----

  defp flash_banner(assigns) do
    ~H"""
    <div class="rt-panel rt-banner">
      <span class="rt-banner-text">{@msg}</span>
      <button phx-click="dismiss_flash" class="rt-banner-close" aria-label="Dismiss message">
        [x]
      </button>
    </div>
    """
  end

  defp question_card(assigns) do
    ~H"""
    <article class={question_card_class(@q.satisfaction)}>
      <div class="rt-card-head">
        <a href={@q.url} target="_blank" class="rt-card-link">
          <span class="rt-card-index">#{@number}</span>
          <span>{@q.title}</span>
        </a>
        <.satisfaction_badge sat={@q.satisfaction} />
      </div>
      <div :if={@q.labels != []} class="rt-chip-row">
        <.label_chip :for={l <- @q.labels} label={l} />
      </div>
      <div class="rt-meta rt-meta--card">
        {@q.comment_count} comment(s) ·
        <span class={state_class(@q.state)}>
          {if @q.state == :open, do: "open", else: "closed"}
        </span>
      </div>
    </article>
    """
  end

  defp satisfaction_badge(assigns) do
    text =
      case assigns.sat do
        :satisfied -> "[+] satisfied"
        :satisfied_conditional -> "[~] conditional"
        :no_objection -> "[·] no objection"
        :needs_more_evidence -> "[-] needs evidence"
        _ -> "[ ] unknown"
      end

    assigns =
      assigns
      |> assign(:text, text)
      |> assign(:class, satisfaction_badge_class(assigns.sat))

    ~H"""
    <span class={@class}>{@text}</span>
    """
  end

  defp label_chip(assigns) do
    ~H"""
    <span class="rt-code-chip">
      {@label}
    </span>
    """
  end

  defp conflict_card(assigns) do
    ~H"""
    <article class="rt-panel rt-panel--conflict">
      <div class="rt-card-head rt-card-head--conflict">
        <div class="rt-conflict-copy">
          <div class="rt-conflict-path">
            {@c.path}
          </div>
          <div class="rt-conflict-meta">
            Unresolved evolution in {@c.vcs |> Atom.to_string() |> String.upcase()}
          </div>
        </div>
        <div class="rt-actions">
          <button
            phx-click="resolve_conflict"
            phx-value-path={@c.path}
            phx-value-vcs={@c.vcs}
            class={button_class(:action)}
          >
            [>] resolve
          </button>
          <.vcs_badge vcs={@c.vcs} />
        </div>
      </div>
    </article>
    """
  end

  defp vcs_badge(assigns) do
    text =
      case assigns.vcs do
        :jj -> "jj"
        :dolt -> "dolt"
        _ -> "vcs"
      end

    assigns =
      assigns
      |> assign(:text, text)
      |> assign(:class, vcs_badge_class(assigns.vcs))

    ~H"""
    <span class={@class}>{@text}</span>
    """
  end

  # ----- helpers -----

  defp load_state(socket, "") do
    socket
    |> assign(:questions, %{})
    |> assign(:conflicts, [])
  end

  defp load_state(socket, repo) do
    # Fetch GitHub issues
    socket =
      case CLI.get_discussion_state(repo) do
        {:ok, state} -> assign(socket, :questions, state)
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

  defp question_card_class(:satisfied), do: "rt-panel rt-panel--question rt-panel--satisfied"

  defp question_card_class(:satisfied_conditional),
    do: "rt-panel rt-panel--question rt-panel--conditional"

  defp question_card_class(:no_objection),
    do: "rt-panel rt-panel--question rt-panel--no-objection"

  defp question_card_class(:needs_more_evidence),
    do: "rt-panel rt-panel--question rt-panel--needs-evidence"

  defp question_card_class(_), do: "rt-panel rt-panel--question"

  defp satisfaction_badge_class(:satisfied), do: "rt-badge rt-badge--satisfied"

  defp satisfaction_badge_class(:satisfied_conditional),
    do: "rt-badge rt-badge--conditional"

  defp satisfaction_badge_class(:no_objection), do: "rt-badge rt-badge--no-objection"

  defp satisfaction_badge_class(:needs_more_evidence),
    do: "rt-badge rt-badge--needs-evidence"

  defp satisfaction_badge_class(_), do: "rt-badge rt-badge--unknown"

  defp state_class(:open), do: "rt-state rt-state--open"
  defp state_class(_), do: "rt-state rt-state--closed"

  defp button_class(:primary), do: "rt-button rt-button--primary"
  defp button_class(:action), do: "rt-button rt-button--action"

  defp run_status_class(true), do: "rt-status-pill rt-status-pill--running"
  defp run_status_class(false), do: "rt-status-pill rt-status-pill--idle"

  defp vcs_badge_class(:jj), do: "rt-vcs-badge rt-vcs-badge--jj"
  defp vcs_badge_class(:dolt), do: "rt-vcs-badge rt-vcs-badge--dolt"
  defp vcs_badge_class(_), do: "rt-vcs-badge rt-vcs-badge--default"

  defp format_event({:round_start, id, n}), do: "#{id}: round #{n} started"
  defp format_event({:agent_done, agent, _issue}), do: "#{agent} posted"
  defp format_event({:question_satisfied, id, n}), do: "#{id} satisfied after #{n} round(s)"
  defp format_event({:question_max_rounds, id}), do: "#{id} needs human review"
  defp format_event({:round_complete, n}), do: "Round complete — #{n} question(s) processed"
  defp format_event(_), do: nil
end

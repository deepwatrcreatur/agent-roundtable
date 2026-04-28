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
      |> load_state(repo)

    {:ok, socket}
  end

  @impl true
  def handle_info(:poll, socket) do
    schedule_poll()
    {:noreply, load_state(socket, socket.assigns.repo)}
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

      {:noreply, assign(socket, :running, true, :flash_msg, "Round started…")}
    end
  end

  @impl true
  def handle_event("set_inject_text", %{"value" => v}, socket) do
    {:noreply, assign(socket, :inject_text, v)}
  end

  @impl true
  def handle_event("dismiss_flash", _params, socket) do
    {:noreply, assign(socket, :flash_msg, nil)}
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

      <section style="margin-bottom: 2rem;">
        <h2 style="font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;">
          Inject Question
        </h2>
        <form phx-submit="inject_question" style="display: flex; gap: 0.5rem; align-items: flex-start;">
          <textarea
            name="text"
            value={@inject_text}
            phx-keyup="set_inject_text"
            placeholder="New question text…"
            rows="3"
            style="flex: 1; background: #161b22; border: 1px solid #30363d; border-radius: 6px;
                   color: #c9d1d9; padding: 0.5rem 0.75rem; font-family: inherit; font-size: 0.9rem; resize: vertical;"
          />
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

  defp satisfaction_badge(assigns) do
    {text, color} =
      case assigns.sat do
        :satisfied -> {"✓ satisfied", "#3fb950"}
        :satisfied_conditional -> {"~ conditional", "#d29922"}
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

  # ----- helpers -----

  defp load_state(socket, "") do
    assign(socket, :questions, %{})
  end

  defp load_state(socket, repo) do
    case CLI.get_discussion_state(repo) do
      {:ok, state} -> assign(socket, :questions, state)
      {:error, _} -> assign(socket, :questions, %{})
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

  defp format_event({:round_start, id, n}), do: "#{id}: round #{n} started"
  defp format_event({:agent_done, agent, _issue}), do: "#{agent} posted"
  defp format_event({:question_satisfied, id, n}), do: "#{id} satisfied after #{n} round(s)"
  defp format_event({:question_max_rounds, id}), do: "#{id} needs human review"
  defp format_event({:round_complete, n}), do: "Round complete — #{n} question(s) processed"
  defp format_event(_), do: nil
end

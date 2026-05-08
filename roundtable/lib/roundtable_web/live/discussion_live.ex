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
    local_path = System.get_env("ROUNDTABLE_LOCAL_PATH", "")
    source_mode = if repo == "", do: "brief", else: "repo"
    candidate_repos = load_candidate_repos()

    if connected?(socket), do: schedule_poll()

    socket =
      socket
      |> assign(:repo, repo)
      |> assign(:brief_path, brief_path)
      |> assign(:local_path, local_path)
      |> assign(:source_mode, source_mode)
      |> assign(:candidate_repos, candidate_repos)
      |> assign(:inject_text, "")
      |> assign(:running, false)
      |> assign(:flash_msg, nil)
      |> assign(:conflicts, [])
      |> load_state(repo, local_path)

    {:ok, socket}
  end

  @impl true
  def handle_info(:poll, socket) do
    schedule_poll()
    {:noreply, load_state(socket, socket.assigns.repo, socket.assigns.local_path)}
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
    case require_repo(socket) do
      {:ok, repo} ->
        case CLI.inject_question(repo, text) do
          {:ok, number} ->
            socket =
              socket
              |> assign(:inject_text, "")
              |> assign(:flash_msg, "Created issue ##{number}")
              |> load_state(repo, socket.assigns.local_path)

            {:noreply, socket}

          {:error, reason} ->
            {:noreply, assign(socket, :flash_msg, "Error: #{inspect(reason)}")}
        end

      {:error, message} ->
        {:noreply, assign(socket, :flash_msg, message)}
    end
  end

  def handle_event("inject_question", _params, socket) do
    {:noreply, assign(socket, :flash_msg, "Question text cannot be empty.")}
  end

  def handle_event("set_source", params, socket) do
    repo = String.trim(Map.get(params, "repo", socket.assigns.repo))
    brief_path = String.trim(Map.get(params, "brief_path", socket.assigns.brief_path))
    local_path = String.trim(Map.get(params, "local_path", socket.assigns.local_path))
    source_mode = Map.get(params, "source_mode", socket.assigns.source_mode)

    socket =
      socket
      |> assign(:repo, repo)
      |> assign(:brief_path, brief_path)
      |> assign(:local_path, local_path)
      |> assign(:source_mode, source_mode)
      |> assign(:flash_msg, "Updated discussion source")
      |> load_state(repo, local_path)

    {:noreply, socket}
  end

  def handle_event("select_candidate_repo", %{"repo" => repo}, socket) do
    socket =
      socket
      |> assign(:repo, repo)
      |> assign(:source_mode, "repo")
      |> assign(:flash_msg, "Selected #{repo}")
      |> load_state(repo, socket.assigns.local_path)

    {:noreply, socket}
  end

  @impl true
  def handle_event("trigger_round", _params, socket) do
    if socket.assigns.running do
      {:noreply, assign(socket, :flash_msg, "A round is already running.")}
    else
      with {:ok, repo} <- require_repo(socket),
           {:ok, source} <- validate_discussion_source(socket) do
        local_path = blank_to_nil(socket.assigns.local_path)
        lv_pid = self()

        Task.start(fn ->
          questions = open_questions(socket.assigns.questions)

          CLI.start_discussion(source,
            repo: repo,
            local_path: local_path,
            on_event: fn event ->
              send(lv_pid, {:roundtable_event, event})
            end
          )

          send(lv_pid, {:roundtable_event, {:round_complete, length(questions)}})
        end)

        {:noreply, assign(socket, running: true, flash_msg: "Round started…")}
      else
        {:error, message} ->
          {:noreply, assign(socket, :flash_msg, message)}
      end
    end
  end

  @impl true
  def handle_event("dismiss_flash", _params, socket) do
    {:noreply, assign(socket, :flash_msg, nil)}
  end

  @impl true
  def handle_event("resolve_conflict", %{"path" => path, "vcs" => vcs}, socket) do
    local_path = socket.assigns.local_path
    vcs_atom = String.to_existing_atom(vcs)

    case CLI.resolve_conflict(local_path, path, vcs_atom) do
      :ok ->
        socket =
          socket
          |> assign(:flash_msg, "Resolved #{path} in #{vcs}")
          |> load_state(socket.assigns.repo, socket.assigns.local_path)

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
          Discussion Source
        </h2>

        <div :if={length(@candidate_repos) > 0} style="margin-bottom: 1rem; display: flex; gap: 0.5rem; flex-wrap: wrap;">
          <button
            :for={candidate <- @candidate_repos}
            type="button"
            phx-click="select_candidate_repo"
            phx-value-repo={candidate.slug}
            style={btn_style(:secondary)}
            title={candidate.description || candidate.slug}
          >
            {candidate.slug}
          </button>
        </div>

        <form phx-submit="set_source" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 0.75rem; align-items: end; margin-bottom: 0.5rem;">
          <label style="display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;">
            Source mode
            <select name="source_mode" style={input_style()}>
              <option value="repo" selected={@source_mode == "repo"}>Discussion repo</option>
              <option value="brief" selected={@source_mode == "brief"}>Legacy BRIEF path</option>
            </select>
          </label>

          <label style="display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;">
            GitHub repo
            <input type="text" name="repo" value={@repo} placeholder="owner/repo" style={input_style()} />
          </label>

          <label style="display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;">
            BRIEF path
            <input type="text" name="brief_path" value={@brief_path} placeholder="docs/design/BRIEF.md" style={input_style()} />
          </label>

          <label style="display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;">
            Local checkout
            <input type="text" name="local_path" value={@local_path} placeholder="/path/to/repo" style={input_style()} />
          </label>

          <button type="submit" style={btn_style(:primary)}>Apply</button>
        </form>

        <p style="color: #8b949e; font-size: 0.8rem; margin: 0;">
          Current source: {discussion_source(assigns)}
        </p>
      </section>

      <section style="margin-bottom: 2rem;">
        <h2 style="font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;">
          Questions
        </h2>

        <div :if={map_size(@questions) == 0} style="color: #8b949e; font-style: italic;">
          No roundtable issues found. Create one below or push a BRIEF.md.
        </div>

        <.question_card :for={{number, q} <- Enum.sort(@questions)} number={number} q={q} />
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

  defp load_state(socket, "", local_path) do
    socket
    |> assign(:questions, %{})
    |> assign(:conflicts, load_conflicts(local_path))
  end

  defp load_state(socket, repo, local_path) do
    # Fetch GitHub issues
    socket =
      case CLI.get_discussion_state(repo) do
        {:ok, state} -> assign(socket, :questions, state)
        {:error, _} -> assign(socket, :questions, %{})
      end

    assign(socket, :conflicts, load_conflicts(local_path))
  end

  defp open_questions(questions) do
    questions
    |> Enum.filter(fn {_, q} -> q.state == :open end)
    |> Enum.map(fn {number, q} -> %{id: q.title, issue_number: number, state: :open} end)
  end

  defp schedule_poll, do: Process.send_after(self(), :poll, @poll_interval_ms)

  defp load_candidate_repos do
    case CLI.list_candidate_repos() do
      {:ok, repos} -> repos
      {:error, _} -> []
    end
  end

  defp load_conflicts(local_path) do
    {:ok, conflicts} = CLI.get_conflicts(blank_to_nil(local_path))
    conflicts
  end

  defp discussion_source(%{assigns: assigns}), do: discussion_source(assigns)

  defp discussion_source(assigns) do
    case assigns.source_mode do
      "repo" -> assigns.repo
      _ -> assigns.brief_path
    end
  end

  defp require_repo(socket) do
    case blank_to_nil(socket.assigns.repo) do
      nil -> {:error, "Configure a GitHub repo before injecting questions or running rounds."}
      repo -> {:ok, repo}
    end
  end

  defp validate_discussion_source(socket) do
    case blank_to_nil(discussion_source(socket)) do
      nil -> {:error, "Configure a repo or BRIEF path before triggering a round."}
      source -> {:ok, source}
    end
  end

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value

  defp input_style do
    "background: #161b22; border: 1px solid #30363d; border-radius: 6px; color: #c9d1d9; padding: 0.5rem 0.75rem; font-family: inherit; font-size: 0.9rem;"
  end

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

  defp btn_style(:secondary) do
    "background: #21262d; color: #c9d1d9; border: 1px solid #30363d; border-radius: 6px; padding: 0.4rem 0.8rem;
     cursor: pointer; font-family: inherit; font-size: 0.8rem;"
  end

  defp format_event({:round_start, id, n}), do: "#{id}: round #{n} started"
  defp format_event({:agent_done, agent, _issue}), do: "#{agent} posted"
  defp format_event({:question_satisfied, id, n}), do: "#{id} satisfied after #{n} round(s)"
  defp format_event({:question_max_rounds, id}), do: "#{id} needs human review"
  defp format_event({:round_complete, n}), do: "Round complete — #{n} question(s) processed"
  defp format_event(_), do: nil
end

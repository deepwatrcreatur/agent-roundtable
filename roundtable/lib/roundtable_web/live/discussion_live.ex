defmodule RoundtableWeb.DiscussionLive do
  @moduledoc """
  Owner dashboard for the roundtable discussion.

  Supports selecting a GitHub discussion repo owned by the authenticated
  GitHub account, or falling back to a legacy local BRIEF path.
  """

  use Phoenix.LiveView

  alias Roundtable.CLI

  @poll_interval_ms 30_000

  @impl true
  def mount(_params, _session, socket) do
    repo = System.get_env("ROUNDTABLE_REPO", "")
    brief_path = System.get_env("ROUNDTABLE_BRIEF", "docs/design/BRIEF.md")
    local_path = System.get_env("ROUNDTABLE_LOCAL_PATH", "")
    discussion_path = System.get_env("ROUNDTABLE_DISCUSSION_PATH", "")
    source_mode = if repo == "", do: "brief", else: "repo"
    candidate_repos = load_candidate_repos()

    if connected?(socket), do: schedule_poll()

    socket =
      socket
      |> assign(:repo, repo)
      |> assign(:brief_path, brief_path)
      |> assign(:local_path, local_path)
      |> assign(:discussion_path, discussion_path)
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
        case CLI.inject_question(repo, text,
               discussion_path: blank_to_nil(socket.assigns.discussion_path)
             ) do
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

  @impl true
  def handle_event("set_source", params, socket) do
    repo = String.trim(Map.get(params, "repo", socket.assigns.repo))
    brief_path = String.trim(Map.get(params, "brief_path", socket.assigns.brief_path))
    local_path = String.trim(Map.get(params, "local_path", socket.assigns.local_path))

    discussion_path =
      String.trim(Map.get(params, "discussion_path", socket.assigns.discussion_path))

    source_mode = Map.get(params, "source_mode", socket.assigns.source_mode)

    socket =
      socket
      |> assign(:repo, repo)
      |> assign(:brief_path, brief_path)
      |> assign(:local_path, local_path)
      |> assign(:discussion_path, discussion_path)
      |> assign(:source_mode, source_mode)
      |> assign(:flash_msg, "Updated discussion source")
      |> load_state(repo, local_path)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_candidate_repo", %{"repo" => repo}, socket) do
    discussion_path =
      socket.assigns.candidate_repos
      |> Enum.find(&(Map.get(&1, :slug) == repo))
      |> default_discussion_path()

    socket =
      socket
      |> assign(:repo, repo)
      |> assign(:discussion_path, discussion_path)
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
        discussion_path = blank_to_nil(socket.assigns.discussion_path)
        lv_pid = self()

        Task.start(fn ->
          questions = open_questions(socket.assigns.questions)

          CLI.start_discussion(source,
            repo: repo,
            local_path: local_path,
            discussion_path: discussion_path,
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

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 960px; margin: 0 auto; padding: 2rem 1rem;">
      <header style="margin-bottom: 2rem;">
        <h1 style="font-size: 1.4rem; color: #f0f6fc; margin-bottom: 0.25rem;">
          Roundtable
        </h1>
        <p style="color: #8b949e; font-size: 0.85rem;">
          {current_source_label(assigns)}
          <span :if={@running} style="color: #d29922; margin-left: 1rem;">● running</span>
        </p>
      </header>

      <.flash_banner :if={@flash_msg} msg={@flash_msg} />

      <section style="margin-bottom: 2rem;">
        <h2 style="font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;">
          Discussion Source
        </h2>

        <div :if={length(@candidate_repos) > 0} style="display: grid; gap: 0.75rem; margin-bottom: 1rem;">
          <button
            :for={candidate <- @candidate_repos}
            type="button"
            phx-click="select_candidate_repo"
            phx-value-repo={candidate.slug}
            style={candidate_card_style(candidate.slug == @repo)}
            title={candidate.description || candidate.slug}
          >
            <span style="display: block; font-size: 0.95rem; font-weight: 600; color: #f0f6fc;">
              {candidate.slug}
            </span>
            <span :if={candidate.description} style="display: block; margin-top: 0.35rem; color: #8b949e; font-size: 0.82rem;">
              {candidate.description}
            </span>
            <span style="display: block; margin-top: 0.45rem; color: #58a6ff; font-size: 0.75rem;">
              {candidate_topic_line(candidate)}
            </span>
          </button>
        </div>

        <form phx-submit="set_source" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 0.75rem; align-items: end; margin-bottom: 0.5rem;">
          <label style="display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;">
            Source mode
            <select name="source_mode" style={input_style()}>
              <option value="repo" selected={@source_mode == "repo"}>GitHub discussion repo</option>
              <option value="brief" selected={@source_mode == "brief"}>Legacy BRIEF path</option>
            </select>
          </label>

          <label style="display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;">
            GitHub repo
            <input type="text" name="repo" value={@repo} placeholder="owner/repo" style={input_style()} />
          </label>

          <label style="display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;">
            Discussion path
            <input type="text" name="discussion_path" value={@discussion_path} placeholder="repo root or embedded folder" style={input_style()} />
          </label>

          <label style="display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;">
            Legacy BRIEF path
            <input type="text" name="brief_path" value={@brief_path} placeholder="docs/design/BRIEF.md" style={input_style()} />
          </label>

          <label style="display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;">
            Local checkout
            <input type="text" name="local_path" value={@local_path} placeholder="/path/to/repo" style={input_style()} />
          </label>

          <button type="submit" style={btn_style(:primary)}>Apply</button>
        </form>
      </section>

      <section style="margin-bottom: 2rem;">
        <h2 style="font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;">
          Questions
        </h2>

        <div :if={map_size(@questions) == 0} style="color: #8b949e; font-style: italic;">
          No roundtable issues found for the selected repo.
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
            rows="4"
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
    <div style="border: 1px solid #f78166; border-radius: 6px; padding: 1rem; margin-bottom: 0.75rem; background: #161b22;">
      <div style="display: flex; justify-content: space-between; align-items: center; gap: 1rem;">
        <div>
          <div style="font-weight: 600; color: #f0f6fc;">{@c.path}</div>
          <div style="font-size: 0.8rem; color: #8b949e;">{String.upcase(to_string(@c.vcs))} conflict</div>
        </div>
        <button phx-click="resolve_conflict" phx-value-path={@c.path} phx-value-vcs={@c.vcs} style={btn_style(:secondary)}>
          Resolve
        </button>
      </div>
    </div>
    """
  end

  defp load_state(socket, "", local_path) do
    socket
    |> assign(:questions, %{})
    |> assign(:conflicts, load_conflicts(local_path))
  end

  defp load_state(socket, repo, local_path) do
    socket =
      case CLI.get_discussion_state(repo) do
        {:ok, qs} -> assign(socket, :questions, qs)
        {:error, _} -> assign(socket, :questions, %{})
      end

    assign(socket, :conflicts, load_conflicts(local_path))
  end

  defp open_questions(questions) do
    questions
    |> Enum.filter(fn {_number, q} -> q.satisfaction in [:unknown, :needs_more_evidence] end)
    |> Enum.map(&elem(&1, 1))
  end

  defp schedule_poll, do: Process.send_after(self(), :poll, @poll_interval_ms)

  defp load_candidate_repos do
    case CLI.list_candidate_repos(["discussion", "vaglio", "roundtable-discussion"]) do
      {:ok, repos} -> repos
      {:error, _} -> []
    end
  end

  defp load_conflicts(local_path) do
    {:ok, conflicts} = CLI.get_conflicts(blank_to_nil(local_path))
    conflicts
  end

  defp require_repo(socket) do
    case blank_to_nil(socket.assigns.repo) do
      nil -> {:error, "Configure a GitHub repo before injecting questions or running rounds."}
      repo -> {:ok, repo}
    end
  end

  defp validate_discussion_source(socket) do
    case socket.assigns.source_mode do
      "repo" ->
        require_repo(socket)

      _ ->
        case blank_to_nil(socket.assigns.brief_path) do
          nil -> {:error, "Configure a BRIEF path before triggering a legacy round."}
          brief_path -> {:ok, brief_path}
        end
    end
  end

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value

  defp current_source_label(assigns) do
    case assigns.source_mode do
      "repo" ->
        path_suffix =
          case blank_to_nil(assigns.discussion_path) do
            nil -> ""
            discussion_path -> " · #{discussion_path}"
          end

        assigns.repo <> path_suffix

      _ ->
        assigns.brief_path
    end
  end

  defp default_discussion_path(nil), do: ""

  defp default_discussion_path(repo) do
    if Enum.any?(repo.topics, &String.contains?(&1, "embedded")) do
      "docs/design"
    else
      ""
    end
  end

  defp candidate_topic_line(candidate) do
    candidate.topics
    |> Enum.join(" · ")
    |> case do
      "" -> if(candidate.private, do: "private repo", else: "public repo")
      topics -> topics
    end
  end

  defp input_style do
    "background: #161b22; border: 1px solid #30363d; border-radius: 6px; color: #c9d1d9; padding: 0.5rem 0.75rem; font-family: inherit; font-size: 0.9rem;"
  end

  defp border_color(:satisfied), do: "#238636"
  defp border_color(:satisfied_conditional), do: "#9e6a03"
  defp border_color(:no_objection), do: "#1f6feb"
  defp border_color(:needs_more_evidence), do: "#f78166"
  defp border_color(:unknown), do: "#30363d"

  defp btn_style(:primary) do
    "background: #238636; color: #f0f6fc; border: none; border-radius: 6px; padding: 0.6rem 1rem;
     cursor: pointer; font-family: inherit; font-size: 0.9rem;"
  end

  defp btn_style(:action) do
    "background: #1f6feb; color: #f0f6fc; border: none; border-radius: 6px; padding: 0.7rem 1rem;
     cursor: pointer; font-family: inherit; font-size: 0.9rem;"
  end

  defp btn_style(:secondary) do
    "background: #21262d; color: #c9d1d9; border: 1px solid #30363d; border-radius: 6px; padding: 0.4rem 0.8rem;
     cursor: pointer; font-family: inherit; font-size: 0.8rem;"
  end

  defp candidate_card_style(true) do
    "text-align: left; width: 100%; background: #161b22; border: 1px solid #58a6ff; border-radius: 8px; padding: 0.9rem 1rem; cursor: pointer;"
  end

  defp candidate_card_style(false) do
    "text-align: left; width: 100%; background: #0d1117; border: 1px solid #30363d; border-radius: 8px; padding: 0.9rem 1rem; cursor: pointer;"
  end

  defp format_event({:round_start, id, n}), do: "#{id}: round #{n} started"
  defp format_event({:agent_done, agent, _issue}), do: "#{agent} posted"
  defp format_event({:question_satisfied, id, n}), do: "#{id} satisfied after #{n} round(s)"
  defp format_event({:question_done, id, state}), do: "#{id} finished with #{state}"
  defp format_event({:question_injected, number, title}), do: "Created issue ##{number}: #{title}"
  defp format_event({:round_complete, n}), do: "Round complete for #{n} question(s)"
  defp format_event(other), do: inspect(other)
end

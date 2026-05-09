defmodule RoundtableWeb.ForgejoShellLive do
  @moduledoc """
  Thin prototype surface for the Forgejo-based code server shell.
  """

  use Phoenix.LiveView

  alias Roundtable.{ForgejoShell, InvestorDemo}

  @impl true
  def mount(params, _session, socket) do
    demo_catalog = InvestorDemo.catalog()
    selected_demo = Map.get(params, "demo", InvestorDemo.default_id())

    demo_inputs =
      case InvestorDemo.import(selected_demo) do
        {:ok, demo} -> demo.shell_inputs
        {:error, _} -> %{}
      end

    inputs =
      ForgejoShell.defaults()
      |> Map.merge(env_defaults())
      |> Map.merge(demo_inputs)
      |> Map.merge(normalize_params(params))

    socket =
      socket
      |> assign(:demo_catalog, demo_catalog)
      |> assign(:selected_demo, selected_demo)
      |> assign(:inputs, inputs)
      |> assign_demo(selected_demo, inputs)
      |> assign_shell(inputs)

    {:ok, socket}
  end

  @impl true
  def handle_event("preview", params, socket) do
    selected_demo = Map.get(params, "selected_demo", socket.assigns.selected_demo)

    inputs =
      socket.assigns.inputs
      |> Map.merge(normalize_params(params))

    {:noreply,
     socket
     |> assign(:selected_demo, selected_demo)
     |> assign(:inputs, inputs)
     |> assign_demo(selected_demo, inputs)
     |> assign_shell(inputs)}
  end

  @impl true
  def handle_event("select_demo_repo", %{"demo" => selected_demo}, socket) do
    case InvestorDemo.import(selected_demo, base_url: socket.assigns.inputs.base_url) do
      {:ok, demo} ->
        inputs =
          socket.assigns.inputs
          |> Map.merge(demo.shell_inputs)

        {:noreply,
         socket
         |> assign(:selected_demo, selected_demo)
         |> assign(:inputs, inputs)
         |> assign(:demo, demo)
         |> assign_shell(inputs)}

      {:error, reason} ->
        {:noreply, assign(socket, :error, "Failed to load demo profile: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 1100px; margin: 0 auto; padding: 2rem 1rem 4rem;">
      <header style="margin-bottom: 2rem;">
        <h1 style="font-size: 1.6rem; color: #f0f6fc; margin-bottom: 0.35rem;">Forgejo Code Server Shell</h1>
        <p style="color: #8b949e; max-width: 760px; line-height: 1.5;">
          Forgejo owns the Git-facing shell. Vaglio stays `jj`-first behind the gateway and surfaces
          analysis beside the Forgejo edge instead of forking Forgejo core.
        </p>
      </header>

      <.flash_banner :if={@error} msg={@error} />

      <section style="margin-bottom: 2rem;">
        <h2 style={section_heading_style()}>Curated Investor Demos</h2>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 0.75rem; margin-bottom: 1rem;">
          <button
            :for={demo <- @demo_catalog}
            type="button"
            phx-click="select_demo_repo"
            phx-value-demo={demo.id}
            style={demo_card_style(demo.id == @selected_demo)}
          >
            <span style="display: block; color: #f0f6fc; font-weight: 600;">{demo.name}</span>
            <span style="display: block; color: #58a6ff; font-size: 0.78rem; margin-top: 0.35rem;">{demo.source_label}</span>
            <span style="display: block; color: #8b949e; font-size: 0.82rem; margin-top: 0.55rem; line-height: 1.45;">{demo.teaser}</span>
          </button>
        </div>
      </section>

      <section style="margin-bottom: 2rem;">
        <h2 style={section_heading_style()}>Prototype Source</h2>
        <form phx-change="preview" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 0.75rem; align-items: end;">
          <input type="hidden" name="selected_demo" value={@selected_demo} />

          <label style={label_style()}>
            Forgejo base URL
            <input type="text" name="base_url" value={@inputs.base_url} style={input_style()} />
          </label>

          <label style={label_style()}>
            Repository slug
            <input type="text" name="repo_slug" value={@inputs.repo_slug} style={input_style()} />
          </label>

          <label style={label_style()}>
            Default branch
            <input type="text" name="default_branch" value={@inputs.default_branch} style={input_style()} />
          </label>

          <label style={label_style()}>
            PR head ref
            <input type="text" name="head_ref" value={@inputs.head_ref} style={input_style()} />
          </label>

          <label style={label_style()}>
            Commit SHA
            <input type="text" name="commit_sha" value={@inputs.commit_sha} style={input_style()} />
          </label>

          <label style={label_style()}>
            Pull request number
            <input type="number" name="pull_number" value={@inputs.pull_number} style={input_style()} />
          </label>

          <label style={label_style()}>
            Merge strategy
            <select name="merge_strategy" style={input_style()}>
              <option value="merge" selected={@inputs.merge_strategy == :merge}>merge</option>
              <option value="squash" selected={@inputs.merge_strategy == :squash}>squash</option>
              <option value="rebase" selected={@inputs.merge_strategy == :rebase}>rebase</option>
            </select>
          </label>
        </form>
      </section>

      <section :if={@demo} style="margin-bottom: 2rem;">
        <h2 style={section_heading_style()}>End-to-End Import Flow</h2>
        <div style="display: grid; gap: 0.75rem;">
          <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 0.75rem;">
              <div>
                <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase;">Public source</div>
                <a href={@demo.source.url} style="color: #f0f6fc; text-decoration: none; font-weight: 600;">{@demo.source.slug}</a>
              </div>
              <div>
                <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase;">Imported Forgejo target</div>
                <a href={@demo.imported_repo.repo_url} style="color: #f0f6fc; text-decoration: none; font-weight: 600;">{@demo.imported_repo.slug}</a>
              </div>
            </div>
          </div>

          <.import_step_card :for={step <- @demo.import_steps} step={step} />
        </div>
      </section>

      <section :if={@shell} style="margin-bottom: 2rem;">
        <h2 style={section_heading_style()}>Forgejo Edge</h2>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 0.75rem;">
          <.nav_card :for={nav <- @shell.navigation} nav={nav} />
        </div>
      </section>

      <section :if={@shell} style="margin-bottom: 2rem;">
        <h2 style={section_heading_style()}>Reuse vs Replace Boundary</h2>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 0.75rem;">
          <.boundary_card :for={boundary <- @shell.boundaries} boundary={boundary} />
        </div>
      </section>

      <section :if={@shell} id="analysis-surface" style="margin-bottom: 2rem;">
        <h2 style={section_heading_style()}>Vaglio Analysis Surface</h2>
        <div style="display: grid; gap: 0.75rem;">
          <.analysis_card title="Branch projection" payload={@shell.analysis.branch_projection} />
          <.analysis_card title="Commit projection" payload={@shell.analysis.commit_projection} />
          <.analysis_card title="Review projection" payload={@shell.analysis.review_projection} />
          <.analysis_card title="Merge projection" payload={@shell.analysis.merge_projection} />
        </div>
      </section>

      <section :if={@demo} style="margin-bottom: 2rem;">
        <h2 style={section_heading_style()}>Investor Dashboard</h2>
        <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem; margin-bottom: 0.75rem;">
          <div style="color: #f0f6fc; font-weight: 600; margin-bottom: 0.45rem;">{@demo.dashboard.headline}</div>
          <p style="margin: 0; color: #8b949e; line-height: 1.5;">{@demo.dashboard.narrative}</p>
        </div>

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 0.75rem; margin-bottom: 0.75rem;">
          <.metric_card :for={metric <- @demo.dashboard.metrics} metric={metric} />
        </div>

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 0.75rem;">
          <.detail_list_card title="Expertise signals" items={@demo.dashboard.expertise_signals} />
          <.detail_list_card title="Subsystem hotspots" items={@demo.dashboard.hotspots} />
          <.detail_list_card title="Provenance overlays" items={@demo.dashboard.provenance} />
        </div>
      </section>

      <section :if={@shell}>
        <h2 style={section_heading_style()}>Extension Seams</h2>
        <div style="display: grid; gap: 0.75rem;">
          <.seam_card :for={seam <- @shell.extension_seams} seam={seam} />
        </div>
      </section>
    </div>
    """
  end

  defp assign_shell(socket, inputs) do
    case ForgejoShell.build(inputs) do
      {:ok, shell} ->
        socket
        |> assign(:shell, shell)
        |> assign(:error, nil)

      {:error, reason} ->
        socket
        |> assign(:shell, nil)
        |> assign(:error, "Invalid Forgejo shell configuration: #{inspect(reason)}")
    end
  end

  defp assign_demo(socket, selected_demo, inputs) do
    case InvestorDemo.import(selected_demo, base_url: inputs.base_url) do
      {:ok, demo} -> assign(socket, :demo, demo)
      {:error, _reason} -> assign(socket, :demo, nil)
    end
  end

  defp env_defaults do
    %{
      base_url: System.get_env("FORGEJO_BASE_URL", ForgejoShell.defaults().base_url),
      repo_slug:
        System.get_env(
          "FORGEJO_REPO",
          System.get_env("ROUNDTABLE_REPO", ForgejoShell.defaults().repo_slug)
        ),
      default_branch: System.get_env("FORGEJO_BRANCH", ForgejoShell.defaults().default_branch),
      head_ref: System.get_env("FORGEJO_HEAD_REF", ForgejoShell.defaults().head_ref),
      commit_sha: System.get_env("FORGEJO_COMMIT_SHA", ForgejoShell.defaults().commit_sha),
      pull_number:
        System.get_env(
          "FORGEJO_PULL_NUMBER",
          Integer.to_string(ForgejoShell.defaults().pull_number)
        ),
      merge_strategy: parse_strategy(System.get_env("FORGEJO_MERGE_STRATEGY", "merge"))
    }
  end

  defp normalize_params(params) do
    %{
      base_url: Map.get(params, "base_url", nil),
      repo_slug: Map.get(params, "repo_slug", nil),
      default_branch: Map.get(params, "default_branch", nil),
      head_ref: Map.get(params, "head_ref", nil),
      commit_sha: Map.get(params, "commit_sha", nil),
      pull_number: Map.get(params, "pull_number", nil),
      merge_strategy: parse_strategy(Map.get(params, "merge_strategy", nil))
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp parse_strategy("squash"), do: :squash
  defp parse_strategy("rebase"), do: :rebase
  defp parse_strategy(:squash), do: :squash
  defp parse_strategy(:rebase), do: :rebase
  defp parse_strategy(_), do: :merge

  defp flash_banner(assigns) do
    ~H"""
    <div style="background: #2d1117; border: 1px solid #f85149; color: #ffdcd7; border-radius: 8px; padding: 0.85rem 1rem; margin-bottom: 1.5rem;">
      {@msg}
    </div>
    """
  end

  defp nav_card(assigns) do
    ~H"""
    <a href={@nav.href} style="display: block; background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem; text-decoration: none;">
      <span style="display: block; color: #58a6ff; font-size: 0.8rem; margin-bottom: 0.35rem;">navigation</span>
      <span style="display: block; color: #f0f6fc; font-weight: 600;">{@nav.label}</span>
      <span style="display: block; color: #8b949e; font-size: 0.8rem; margin-top: 0.45rem;">{@nav.href}</span>
    </a>
    """
  end

  defp import_step_card(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <div style="display: flex; justify-content: space-between; gap: 0.75rem; align-items: baseline;">
        <strong style="color: #f0f6fc;">{@step.step}</strong>
        <span style="color: #3fb950; font-size: 0.78rem; text-transform: uppercase;">{status_label(@step.status)}</span>
      </div>
      <p style="margin-top: 0.6rem; color: #8b949e; line-height: 1.5;">{@step.detail}</p>
    </div>
    """
  end

  defp boundary_card(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <div style="display: flex; justify-content: space-between; gap: 0.75rem; align-items: baseline;">
        <strong style="color: #f0f6fc;">{@boundary.capability}</strong>
        <span style={"color: #{owner_color(@boundary.owner)}; font-size: 0.78rem; text-transform: uppercase;"}>{owner_label(@boundary.owner)}</span>
      </div>
      <p style="margin-top: 0.6rem; color: #8b949e; line-height: 1.5;">{@boundary.seam}</p>
    </div>
    """
  end

  defp analysis_card(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <h3 style="margin: 0 0 0.75rem; color: #f0f6fc; font-size: 0.95rem;">{@title}</h3>
      <pre style="margin: 0; white-space: pre-wrap; color: #8b949e; font-size: 0.82rem; line-height: 1.5;"><%= inspect(@payload, pretty: true) %></pre>
    </div>
    """
  end

  defp metric_card(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase;">{@metric.label}</div>
      <div style="color: #f0f6fc; font-size: 1.4rem; font-weight: 700; margin-top: 0.45rem;">{@metric.value}</div>
      <p style="margin: 0.6rem 0 0; color: #8b949e; line-height: 1.45;">{@metric.note}</p>
    </div>
    """
  end

  defp detail_list_card(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <h3 style="margin: 0 0 0.75rem; color: #f0f6fc; font-size: 0.95rem;">{@title}</h3>
      <div style="display: grid; gap: 0.75rem;">
        <div :for={item <- @items}>
          <div style="color: #58a6ff; font-size: 0.82rem; font-weight: 600;">
            {detail_item_title(item)}
          </div>
          <div style="color: #8b949e; line-height: 1.45; margin-top: 0.3rem;">
            {detail_item_detail(item)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp seam_card(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <div style="display: flex; justify-content: space-between; gap: 0.75rem;">
        <strong style="color: #f0f6fc;">{@seam.surface}</strong>
        <code style="color: #58a6ff; font-size: 0.78rem;">{@seam.module}</code>
      </div>
      <p style="margin-top: 0.6rem; color: #8b949e; line-height: 1.5;">{@seam.role}</p>
    </div>
    """
  end

  defp detail_item_title(%{title: title}), do: title
  defp detail_item_title(%{area: area, signal: signal}), do: area <> " — " <> signal

  defp detail_item_detail(%{detail: detail}), do: detail
  defp detail_item_detail(%{note: note}), do: note

  defp demo_card_style(true) do
    "text-align: left; background: #1f2937; border: 1px solid #58a6ff; border-radius: 8px; padding: 1rem;"
  end

  defp demo_card_style(false) do
    "text-align: left; background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;"
  end

  defp owner_label(:forgejo), do: "Forgejo"
  defp owner_label(:vaglio), do: "Vaglio"

  defp owner_color(:forgejo), do: "#3fb950"
  defp owner_color(:vaglio), do: "#d2a8ff"

  defp status_label(:done), do: "done"
  defp status_label(other), do: to_string(other)

  defp section_heading_style do
    "font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;"
  end

  defp label_style do
    "display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;"
  end

  defp input_style do
    "background: #0d1117; border: 1px solid #30363d; border-radius: 6px; color: #c9d1d9; padding: 0.55rem 0.7rem; font-size: 0.9rem;"
  end
end

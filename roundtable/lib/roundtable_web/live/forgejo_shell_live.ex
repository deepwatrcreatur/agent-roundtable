defmodule RoundtableWeb.ForgejoShellLive do
  @moduledoc """
  Thin prototype surface for the Forgejo-based code server shell.
  """

  use Phoenix.LiveView

  alias Roundtable.{ArchitectureBenchmark, ForgejoShell, InvestorDemo}

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
      |> assign_benchmark(selected_demo)
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
     |> assign_benchmark(selected_demo)
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
         |> assign_benchmark(selected_demo)
         |> assign_shell(inputs)}

      {:error, reason} ->
        {:noreply, assign(socket, :error, "Failed to load demo profile: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 1100px; margin: 0 auto; padding: 2rem 1rem 4rem;">
      <header style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.25rem; align-items: start; margin-bottom: 2rem;">
        <div>
          <div style="display: inline-flex; align-items: center; gap: 0.45rem; border: 1px solid #30363d; border-radius: 999px; padding: 0.35rem 0.75rem; color: #58a6ff; font-size: 0.76rem; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.85rem;">
            Public demo shell
          </div>
          <h1 style="font-size: clamp(2rem, 5vw, 3.2rem); line-height: 1.02; color: #f0f6fc; margin-bottom: 0.6rem;">
            Forgejo Code Server Shell
          </h1>
          <p style="color: #8b949e; max-width: 760px; line-height: 1.6; margin-bottom: 1rem;">
            This is the fastest way to understand the product: Forgejo keeps the code-hosting surface recognizable,
            while Vaglio adds analysis, provenance, and investor-readable repository narratives beside it.
          </p>
          <div style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
            <a href={"#demo-#{@selected_demo}"} style={cta_style(:primary)}>Start with this demo</a>
            <a :if={@demo} href={@demo.source.url} style={cta_style(:secondary)}>Open public source</a>
            <a :if={@demo} href={@demo.imported_repo.repo_url} style={cta_style(:secondary)}>Open imported Forgejo target</a>
          </div>
        </div>

        <div :if={@demo} style="background: linear-gradient(180deg, rgba(22,27,34,0.96), rgba(13,17,23,0.96)); border: 1px solid #30363d; border-radius: 16px; padding: 1.1rem;">
          <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.6rem;">
            Recommended first view
          </div>
          <div style="color: #f0f6fc; font-size: 1.05rem; font-weight: 700; margin-bottom: 0.4rem;">
            {@demo.name}
          </div>
          <p style="color: #8b949e; line-height: 1.55; margin-bottom: 0.8rem;">
            {@demo.teaser}
          </p>
          <ul style="margin: 0; padding-left: 1rem; color: #8b949e; line-height: 1.65;">
            <li>Shows the Forgejo shell and Vaglio boundary immediately.</li>
            <li>Highlights a curated dashboard instead of starting with infrastructure controls.</li>
            <li>Gives an outsider an obvious first click without verbal narration.</li>
          </ul>
        </div>
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
            id={"demo-#{demo.id}"}
            style={demo_card_style(demo.id == @selected_demo)}
          >
            <span :if={demo.id == @selected_demo} style="display: inline-flex; margin-bottom: 0.55rem; color: #3fb950; font-size: 0.74rem; text-transform: uppercase; letter-spacing: 0.08em;">
              Recommended first click
            </span>
            <span style="display: block; color: #f0f6fc; font-weight: 600;">{demo.name}</span>
            <span style="display: block; color: #58a6ff; font-size: 0.78rem; margin-top: 0.35rem;">{demo.source_label}</span>
            <span style="display: block; color: #8b949e; font-size: 0.82rem; margin-top: 0.55rem; line-height: 1.45;">{demo.teaser}</span>
          </button>
        </div>
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

      <section :if={@benchmark} style="margin-bottom: 2rem;">
        <h2 style={section_heading_style()}>JJ vs Git Infrastructure Benchmark</h2>
        <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem; margin-bottom: 0.75rem;">
          <div style="color: #f0f6fc; font-weight: 600; margin-bottom: 0.45rem;">{@benchmark.title}</div>
          <p style="margin: 0; color: #8b949e; line-height: 1.5;">
            {@benchmark.recommendation.summary}
          </p>
        </div>

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 0.75rem; margin-bottom: 0.75rem;">
          <.workload_metric_card label="Concurrent changes" value={@benchmark.workload.concurrent_changes} />
          <.workload_metric_card label="Ephemeral workspaces" value={@benchmark.workload.ephemeral_workspaces} />
          <.workload_metric_card label="Conflict recovery cases" value={@benchmark.workload.conflict_recovery_cases} />
          <.workload_metric_card label="Ingest window" value={@benchmark.workload.ingest_window} />
        </div>

        <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem; margin-bottom: 0.75rem;">
          <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; margin-bottom: 0.5rem;">Reproducible workload hooks</div>
          <ul style="margin: 0; padding-left: 1.1rem; color: #8b949e; line-height: 1.6;">
            <li :for={hook <- @benchmark.workload.provenance_hooks}>{hook}</li>
          </ul>
        </div>

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 0.75rem; margin-bottom: 0.75rem;">
          <.benchmark_path_card :for={path <- @benchmark.paths} path={path} />
        </div>

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 0.75rem;">
          <.detail_list_card title="Keep native in jj" items={Enum.map(@benchmark.recommendation.native_zone, &%{title: &1, detail: "Best handled inside the native Vaglio core."})} />
          <.detail_list_card title="Keep compatible at the edge" items={Enum.map(@benchmark.recommendation.compatible_zone, &%{title: &1, detail: "Expose through the Forgejo/Git-facing shell for adoption."})} />
        </div>
      </section>

      <section :if={@shell}>
        <h2 style={section_heading_style()}>Extension Seams</h2>
        <div style="display: grid; gap: 0.75rem;">
          <.seam_card :for={seam <- @shell.extension_seams} seam={seam} />
        </div>
      </section>

      <section style="margin-top: 2.5rem;">
        <h2 style={section_heading_style()}>Advanced Prototype Source Controls</h2>
        <p style="color: #8b949e; line-height: 1.55; margin-bottom: 0.9rem; max-width: 44rem;">
          These controls are here for operators and demo preparation. Most visitors should start with the recommended curated demo above instead of changing the shell inputs first.
        </p>
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

  defp assign_benchmark(socket, selected_demo) do
    case ArchitectureBenchmark.compare(selected_demo) do
      {:ok, benchmark} -> assign(socket, :benchmark, benchmark)
      {:error, _reason} -> assign(socket, :benchmark, nil)
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

  defp workload_metric_card(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase;">{@label}</div>
      <div style="color: #f0f6fc; font-size: 1.35rem; font-weight: 700; margin-top: 0.45rem;">{@value}</div>
    </div>
    """
  end

  defp benchmark_path_card(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <div style="display: flex; justify-content: space-between; gap: 0.75rem; align-items: baseline; margin-bottom: 0.75rem;">
        <strong style="color: #f0f6fc;">{@path.label}</strong>
        <span style={"color: #{owner_color(path_owner(@path.posture))}; font-size: 0.78rem; text-transform: uppercase;"}>{path_posture_label(@path.posture)}</span>
      </div>

      <div style="display: grid; gap: 0.55rem; margin-bottom: 0.75rem;">
        <div :for={metric <- @path.metrics} style="display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 0.5rem; align-items: baseline;">
          <span style="color: #58a6ff; font-size: 0.82rem;">{metric.label}</span>
          <span style="color: #f0f6fc; font-weight: 700;">{metric.value}</span>
          <span style="grid-column: 1 / -1; color: #8b949e; font-size: 0.8rem; line-height: 1.45;">{metric.note}</span>
        </div>
      </div>

      <ul style="margin: 0; padding-left: 1.1rem; color: #8b949e; line-height: 1.6;">
        <li :for={tradeoff <- @path.tradeoffs}>{tradeoff}</li>
      </ul>
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

  defp path_owner(:native), do: :vaglio
  defp path_owner("native"), do: :vaglio
  defp path_owner(:compatible), do: :forgejo
  defp path_owner("compatible"), do: :forgejo

  defp path_posture_label(:native), do: "native"
  defp path_posture_label("native"), do: "native"
  defp path_posture_label(:compatible), do: "compatible"
  defp path_posture_label("compatible"), do: "compatible"

  defp status_label(:done), do: "done"
  defp status_label(other), do: to_string(other)

  defp section_heading_style do
    "font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;"
  end

  defp cta_style(:primary) do
    "display: inline-flex; align-items: center; justify-content: center; text-decoration: none; background: #238636; color: #f0f6fc; border-radius: 999px; padding: 0.72rem 1rem; font-weight: 600; border: 1px solid #2ea043;"
  end

  defp cta_style(:secondary) do
    "display: inline-flex; align-items: center; justify-content: center; text-decoration: none; background: transparent; color: #c9d1d9; border-radius: 999px; padding: 0.72rem 1rem; font-weight: 600; border: 1px solid #30363d;"
  end

  defp label_style do
    "display: flex; flex-direction: column; gap: 0.35rem; color: #8b949e; font-size: 0.8rem;"
  end

  defp input_style do
    "background: #0d1117; border: 1px solid #30363d; border-radius: 6px; color: #c9d1d9; padding: 0.55rem 0.7rem; font-size: 0.9rem;"
  end
end

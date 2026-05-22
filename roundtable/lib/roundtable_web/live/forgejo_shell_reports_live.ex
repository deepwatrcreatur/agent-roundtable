defmodule RoundtableWeb.ForgejoShellReportsLive do
  @moduledoc """
  Shareable reports surface for cached public repo demo snapshots.
  """

  use Phoenix.LiveView

  alias Roundtable.PublicRepoDemo

  @impl true
  def mount(_params, _session, socket) do
    reports = PublicRepoDemo.report_entries(report_opts())
    {:ok, assign(socket, :reports, reports)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 1180px; margin: 0 auto; padding: 2rem 1rem 4rem;">
      <header style="display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 1.25rem; align-items: start; margin-bottom: 2rem;">
        <div>
          <div style="display: inline-flex; align-items: center; gap: 0.45rem; border: 1px solid #30363d; border-radius: 999px; padding: 0.35rem 0.75rem; color: #58a6ff; font-size: 0.76rem; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.85rem;">
            Shareable report surface
          </div>
          <h1 style="font-size: clamp(2rem, 5vw, 3rem); line-height: 1.02; color: #f0f6fc; margin-bottom: 0.6rem;">
            Public Repo Snapshot Reports
          </h1>
          <p style="color: #8b949e; max-width: 760px; line-height: 1.6; margin-bottom: 1rem;">
            These reports are built from the cached public repo snapshots that power the Forgejo shell demo. They are easier to share than the interactive shell and make the computed evidence visible at a glance.
          </p>
          <div style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
            <a href="/forgejo-shell" style={cta_style(:primary)}>Back to live demo</a>
            <a href="#report-forgejo" style={cta_style(:secondary)}>Jump to first report</a>
          </div>
        </div>

        <div style="background: linear-gradient(180deg, rgba(22,27,34,0.96), rgba(13,17,23,0.96)); border: 1px solid #30363d; border-radius: 16px; padding: 1.1rem;">
          <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.6rem;">
            What this proves
          </div>
          <ul style="margin: 0; padding-left: 1rem; color: #8b949e; line-height: 1.65;">
            <li>Each report is tied to a named public source and imported Forgejo target.</li>
            <li>Contributor, commit, and hotspot tables come from cached sampled history when available.</li>
            <li>Cached report state makes the page easier to share than the interactive shell alone.</li>
          </ul>
        </div>
      </header>

      <section style="margin-bottom: 2rem;">
        <h2 style={section_heading_style()}>Available Reports</h2>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 0.75rem;">
          <a
            :for={report <- @reports}
            href={"#report-#{report.demo.id}"}
            style="display: block; text-decoration: none; background: #161b22; border: 1px solid #30363d; border-radius: 10px; padding: 1rem;"
          >
            <div style="display: flex; justify-content: space-between; gap: 0.75rem; align-items: baseline; margin-bottom: 0.5rem;">
              <span style="color: #f0f6fc; font-weight: 600;">{report.demo.name}</span>
              <span style={"color: #{cache_status_color(report.cache_status)}; font-size: 0.75rem; text-transform: uppercase;"}>{cache_status_label(report.cache_status)}</span>
            </div>
            <div style="color: #58a6ff; font-size: 0.8rem;">{report.demo.source_label}</div>
            <div style="color: #8b949e; font-size: 0.82rem; margin-top: 0.5rem; line-height: 1.45;">{report.demo.teaser}</div>
          </a>
        </div>
      </section>

      <section :for={report <- @reports} id={"report-#{report.demo.id}"} style="margin-bottom: 2rem;">
        <div style="display: flex; justify-content: space-between; gap: 1rem; align-items: baseline; margin-bottom: 0.85rem; flex-wrap: wrap;">
          <div>
            <h2 style="margin: 0; color: #f0f6fc; font-size: 1.25rem;">{report.demo.name}</h2>
            <div style="color: #58a6ff; font-size: 0.82rem; margin-top: 0.35rem;">{report.demo.source_label}</div>
          </div>
          <div style="color: #8b949e; font-size: 0.82rem;">
            <span style={"color: #{cache_status_color(report.cache_status)}; text-transform: uppercase; margin-right: 0.6rem;"}>{cache_status_label(report.cache_status)}</span>
            <span :if={report.generated_at}>Generated {format_generated_at(report.generated_at)}</span>
          </div>
        </div>

        <div style="background: #161b22; border: 1px solid #30363d; border-radius: 10px; padding: 1rem; margin-bottom: 0.75rem;">
          <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 0.75rem;">
            <div>
              <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase;">Public source</div>
              <a :if={report.source} href={report.source.url} style="color: #f0f6fc; text-decoration: none; font-weight: 600;">{report.source.slug}</a>
              <span :if={!report.source} style="color: #8b949e;">Cached source metadata unavailable</span>
            </div>
            <div>
              <div style="color: #58a6ff; font-size: 0.78rem; text-transform: uppercase;">Imported Forgejo target</div>
              <a :if={report.imported_repo} href={report.imported_repo.repo_url} style="color: #f0f6fc; text-decoration: none; font-weight: 600;">{report.imported_repo.slug}</a>
              <span :if={!report.imported_repo} style="color: #8b949e;">Imported target unavailable</span>
            </div>
          </div>
        </div>

        <div :if={report.source && report.source.history_summary} style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 0.75rem; margin-bottom: 0.75rem;">
          <.metric_card metric={metric("Sampled commits", to_string(report.source.history_summary.sampled_commit_count), "Shallow history sample cached from the tracked branch.")} />
          <.metric_card metric={metric("Contributor count", to_string(report.source.history_summary.contributor_count), "Unique contributors observed in the cached sample.")} />
          <.metric_card metric={metric("Top author share", derived_percentage(report.source.history_summary.derived_signals.top_author_share), "Share of sampled commits attributable to the top three contributors.")} accent={:heat} />
          <.metric_card metric={metric("Commit cadence", "#{report.source.history_summary.derived_signals.commits_per_day_window}/day", "Recent sampled commits per day across the cached window.")} />
        </div>

        <div :if={report.source && report.source.history_summary} style="display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 0.75rem;">
          <.contributors_table contributors={report.source.history_summary.top_contributors} />
          <.commit_log_table commits={report.source.history_summary.recent_commits} />
          <.path_hotspots_table hotspots={report.source.history_summary.path_hotspots} />
        </div>

        <div :if={!report.source} style="background: #161b22; border: 1px solid #59343b; border-radius: 10px; padding: 1rem; color: #c9d1d9; line-height: 1.55;">
          Cached sampled evidence was unavailable when this page loaded, so this report is currently limited to the curated demo shell. Re-open the interactive demo to refresh the cache path before sharing this report.
        </div>
      </section>
    </div>
    """
  end

  defp metric(label, value, note), do: %{label: label, value: value, note: note}

  defp cache_status_label(:cached), do: "cached"
  defp cache_status_label(:fallback), do: "fallback"

  defp cache_status_color(:cached), do: "#3fb950"
  defp cache_status_color(:fallback), do: "#d29922"

  defp format_generated_at(value) do
    with {:ok, datetime, _offset} <- DateTime.from_iso8601(value) do
      Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")
    else
      _ -> value
    end
  end

  defp metric_card(assigns) do
    assigns = assign_new(assigns, :accent, fn -> :default end)

    ~H"""
    <div style={"background: #161b22; border: 1px solid #{metric_border(@accent)}; border-radius: 8px; padding: 1rem;"}>
      <div style={"color: #{metric_accent(@accent)}; font-size: 0.78rem; text-transform: uppercase;"}>{@metric.label}</div>
      <div style="color: #f0f6fc; font-size: 1.4rem; font-weight: 700; margin-top: 0.45rem;">{@metric.value}</div>
      <p style="margin: 0.6rem 0 0; color: #8b949e; line-height: 1.45;">{@metric.note}</p>
    </div>
    """
  end

  defp contributors_table(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <h3 style="margin: 0 0 0.75rem; color: #f0f6fc; font-size: 0.95rem;">Top sampled contributors</h3>
      <table style="width: 100%; border-collapse: collapse; font-size: 0.84rem;">
        <thead>
          <tr style="text-align: left; color: #58a6ff; border-bottom: 1px solid #30363d;">
            <th style="padding: 0.45rem 0;">Author</th>
            <th style="padding: 0.45rem 0;">Email</th>
            <th style="padding: 0.45rem 0; text-align: right;">Commits</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={contributor <- @contributors} style="border-bottom: 1px solid #21262d;">
            <td style="padding: 0.5rem 0; color: #f0f6fc;">{contributor.author}</td>
            <td style="padding: 0.5rem 0; color: #8b949e;">{contributor.email}</td>
            <td style="padding: 0.5rem 0; color: #f0f6fc; text-align: right;">{contributor.commits}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp commit_log_table(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <h3 style="margin: 0 0 0.75rem; color: #f0f6fc; font-size: 0.95rem;">Recent sampled commits</h3>
      <table style="width: 100%; border-collapse: collapse; font-size: 0.84rem;">
        <thead>
          <tr style="text-align: left; color: #58a6ff; border-bottom: 1px solid #30363d;">
            <th style="padding: 0.45rem 0;">When</th>
            <th style="padding: 0.45rem 0;">Author</th>
            <th style="padding: 0.45rem 0;">SHA</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={commit <- @commits} style="border-bottom: 1px solid #21262d;">
            <td style="padding: 0.5rem 0; color: #8b949e;">{format_commit_day(commit.committed_at_unix)}</td>
            <td style="padding: 0.5rem 0; color: #f0f6fc;">{commit.author}</td>
            <td style="padding: 0.5rem 0; color: #8b949e;"><code>{short_sha(commit.sha)}</code></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp path_hotspots_table(assigns) do
    ~H"""
    <div style="background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem;">
      <h3 style="margin: 0 0 0.75rem; color: #f0f6fc; font-size: 0.95rem;">Sampled path hotspots</h3>
      <table style="width: 100%; border-collapse: collapse; font-size: 0.84rem;">
        <thead>
          <tr style="text-align: left; color: #58a6ff; border-bottom: 1px solid #30363d;">
            <th style="padding: 0.45rem 0;">Path</th>
            <th style="padding: 0.45rem 0; text-align: right;">Mentions</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={hotspot <- @hotspots} style="border-bottom: 1px solid #21262d;">
            <td style="padding: 0.5rem 0; color: #f0f6fc;"><code>{hotspot.path}</code></td>
            <td style="padding: 0.5rem 0; color: #f0f6fc; text-align: right;">{hotspot.mentions}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp derived_percentage(value) when is_float(value), do: "#{Float.round(value * 100, 0)}%"
  defp derived_percentage(value), do: to_string(value)

  defp format_commit_day(unix) when is_integer(unix) do
    unix
    |> DateTime.from_unix!()
    |> Calendar.strftime("%Y-%m-%d")
  end

  defp short_sha(sha) when is_binary(sha), do: String.slice(sha, 0, 8)

  defp metric_accent(:heat), do: "#ff7b72"
  defp metric_accent(_), do: "#58a6ff"

  defp metric_border(:heat), do: "#59343b"
  defp metric_border(_), do: "#30363d"

  defp section_heading_style do
    "font-size: 1rem; color: #8b949e; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;"
  end

  defp cta_style(:primary) do
    "display: inline-flex; align-items: center; justify-content: center; text-decoration: none; background: #238636; color: #f0f6fc; border-radius: 999px; padding: 0.72rem 1rem; font-weight: 600; border: 1px solid #2ea043;"
  end

  defp cta_style(:secondary) do
    "display: inline-flex; align-items: center; justify-content: center; text-decoration: none; background: transparent; color: #c9d1d9; border-radius: 999px; padding: 0.72rem 1rem; font-weight: 600; border: 1px solid #30363d;"
  end

  defp report_opts do
    Keyword.merge([timeout_ms: 2_000, ttl_ms: 15 * 60_000], Application.get_env(:roundtable, __MODULE__, []))
  end
end

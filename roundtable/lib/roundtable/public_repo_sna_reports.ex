defmodule Roundtable.PublicRepoSnaReports do
  @moduledoc """
  Builds shareable markdown reports for the public repo demo snapshots.
  """

  alias Roundtable.PublicRepoDemo

  @type options :: keyword()

  @default_output_root "reports/public-repo-sna"

  @spec export_all(options()) :: {:ok, [Path.t()]} | {:error, term()}
  def export_all(opts \\ []) do
    output_root = Keyword.get(opts, :output_root, @default_output_root)

    with :ok <- File.mkdir_p(output_root),
         {:ok, report_exports} <- export_repo_reports(output_root, opts),
         {:ok, index_path} <- export_index(output_root, report_exports) do
      report_paths = Enum.map(report_exports, & &1.path)
      {:ok, [index_path | report_paths]}
    end
  end

  @spec render_report(map()) :: String.t()
  def render_report(snapshot) do
    history_summary = snapshot.source.history_summary
    signals = history_summary.derived_signals

    [
      "# ", snapshot.demo.name, " — Project Mind Report\n\n",
      "> Generated ", snapshot.generated_at, "\n\n",
      snapshot.dashboard.headline, "\n\n",
      "## Executive Summary\n\n",
      snapshot.dashboard.narrative, "\n\n",
      "## Shareable Observations\n\n",
      observation_bullets(snapshot),
      "\n",
      "## Stress Surface\n\n",
      "- Branch stress: `", metric_value(snapshot.dashboard.stress.metrics, "Branch stress"), "`\n",
      "- History heat: `", metric_value(snapshot.dashboard.stress.metrics, "History heat"), "`\n",
      "- Active-inference confidence: `", metric_value(snapshot.dashboard.stress.metrics, "Active-inference confidence"), "`\n",
      "- Sampled contributor concentration: `", signals.contributor_concentration, "`\n",
      "- Sampled top-author share: `", percentage(signals.top_author_share), "`\n\n",
      "## Project Mind Heatmap\n\n",
      "| Surface | Stress | Heat | Appraisal |\n",
      "| --- | --- | --- | --- |\n",
      heatmap_rows(snapshot),
      "\n",
      "## Contributor Concentration\n\n",
      "| Author | Commits | Share |\n",
      "| --- | ---: | ---: |\n",
      contributor_rows(history_summary),
      "\n",
      "## Path Hotspots\n\n",
      "| Path | Mentions |\n",
      "| --- | ---: |\n",
      hotspot_rows(history_summary.path_hotspots),
      "\n",
      "## Recent Commit Sample\n\n",
      "| When | Author | SHA |\n",
      "| --- | --- | --- |\n",
      commit_rows(history_summary.recent_commits),
      "\n",
      "## Maintainer Bottleneck Notes\n\n",
      bottleneck_notes(snapshot)
    ]
    |> IO.iodata_to_binary()
  end

  defp export_repo_reports(output_root, opts) do
    opts = Keyword.put_new(opts, :output_root, "reports/public-repo-demos")

    report_exports =
      for demo <- demo_ids() do
        with {:ok, snapshot} <- PublicRepoDemo.snapshot(demo, opts),
             :ok <- maybe_export_snapshot(snapshot, opts),
             path <- Path.join(output_root, "#{demo}.md"),
             :ok <- File.write(path, render_report(snapshot)) do
          {:ok,
           %{
             id: snapshot.demo.id,
             name: snapshot.demo.name,
             generated_at: snapshot.generated_at,
             path: path
           }}
        end
      end

    case Enum.find(report_exports, &match?({:error, _}, &1)) do
      nil -> {:ok, Enum.map(report_exports, fn {:ok, report} -> report end)}
      {:error, _reason} = error -> error
    end
  end

  defp export_index(output_root, report_exports) do
    body =
      [
        "# Public Repo SNA Reports\n\n",
        "This directory contains shareable markdown artifacts derived from the same public repo snapshots that drive `/forgejo-shell` and `/forgejo-shell/reports`.\n\n",
        "| Repo | Generated | Report |\n",
        "| --- | --- | --- |\n",
        Enum.map(Enum.sort_by(report_exports, & &1.name), fn report ->
          [
            "| ",
            report.name,
            " | ",
            report.generated_at,
            " | [",
            report.id,
            "](./",
            report.id,
            ".md) |\n"
          ]
        end)
      ]
      |> IO.iodata_to_binary()

    path = Path.join(output_root, "README.md")
    File.write(path, body)
    {:ok, path}
  end

  defp maybe_export_snapshot(snapshot, opts) do
    output_root = Keyword.get(opts, :snapshot_output_root, "reports/public-repo-demos")
    path = Path.join(output_root, "#{snapshot.demo.id}.json")

    with :ok <- File.mkdir_p(output_root),
         {:ok, encoded} <- Jason.encode_to_iodata(snapshot, pretty: true),
         :ok <- File.write(path, encoded) do
      :ok
    end
  end

  defp observation_bullets(snapshot) do
    history_summary = snapshot.source.history_summary
    signals = history_summary.derived_signals
    hotspot = List.first(history_summary.path_hotspots)
    contributor = List.first(history_summary.top_contributors)

    [
      "- `", snapshot.demo.name, "` shows `", signals.contributor_concentration,
      "` sampled contributor concentration, with the top three authors accounting for ",
      percentage(signals.top_author_share), " of sampled commits.\n",
      "- The hottest sampled path is `", hotspot.path, "` with `", to_string(hotspot.mentions),
      "` mentions in the shallow branch window.\n",
      "- `", contributor.author, "` leads the sampled window, indicating a repeat maintainer anchor rather than flatly distributed ownership.\n"
    ]
  end

  defp heatmap_rows(snapshot) do
    history_summary = snapshot.source.history_summary
    derived = derived_heatmap_rows(history_summary)

    curated =
      snapshot.dashboard.stress.hotspots
      |> Enum.map(fn hotspot ->
        [
          "| ",
          hotspot.title,
          " | ",
          hotspot.stress,
          " | ",
          to_string(hotspot.heat),
          " | ",
          appraisal_for(hotspot.stress),
          " |\n"
        ]
      end)

    IO.iodata_to_binary([curated, derived])
  end

  defp derived_heatmap_rows(%{path_hotspots: hotspots, derived_signals: signals}) do
    max_mentions =
      hotspots
      |> Enum.map(& &1.mentions)
      |> Enum.max(fn -> 1 end)
      |> max(1)

    hotspots
    |> Enum.take(3)
    |> Enum.map(fn hotspot ->
      heat = Float.round(hotspot.mentions / max_mentions, 2)
      stress = derived_stress(heat, signals.contributor_concentration)

      [
        "| ",
        hotspot.path,
        " | ",
        stress,
        " | ",
        Float.to_string(heat),
        " | ",
        appraisal_for(stress),
        " |\n"
      ]
    end)
  end

  defp contributor_rows(history_summary) do
    total = max(history_summary.sampled_commit_count, 1)

    history_summary.top_contributors
    |> Enum.map(fn contributor ->
      [
        "| ",
        contributor.author,
        " | ",
        to_string(contributor.commits),
        " | ",
        percentage(contributor.commits / total),
        " |\n"
      ]
    end)
    |> IO.iodata_to_binary()
  end

  defp hotspot_rows(hotspots) do
    hotspots
    |> Enum.map(fn hotspot ->
      ["| `", hotspot.path, "` | ", to_string(hotspot.mentions), " |\n"]
    end)
    |> IO.iodata_to_binary()
  end

  defp commit_rows(commits) do
    commits
    |> Enum.map(fn commit ->
      ["| ", commit_day(commit.committed_at_unix), " | ", commit.author, " | `", short_sha(commit.sha), "` |\n"]
    end)
    |> IO.iodata_to_binary()
  end

  defp bottleneck_notes(snapshot) do
    history_summary = snapshot.source.history_summary
    hotspot = List.first(history_summary.path_hotspots)
    contributor = List.first(history_summary.top_contributors)

    [
      "- The strongest likely maintenance anchor in the sampled window is **", contributor.author,
      "**, which makes continuity risk visible even before any explicit social graph is modeled.\n",
      "- The hottest code surface is `", hotspot.path,
      "`, which is a plausible place to focus future vouch-graph or review-latency instrumentation.\n",
      "- This first PoC still uses sampled commit topology and concentration signals as a stand-in for a fuller vouch network; it is meant to be shareable now, not final theory-complete infrastructure.\n"
    ]
  end

  defp metric_value(metrics, label) do
    metrics
    |> Enum.find(%{}, &(&1.label == label))
    |> Map.get(:value, "n/a")
    |> to_string()
  end

  defp derived_stress(heat, "high") when heat >= 0.66, do: "high"
  defp derived_stress(heat, _) when heat >= 0.85, do: "high"
  defp derived_stress(heat, _) when heat >= 0.45, do: "medium"
  defp derived_stress(_, _), do: "low"

  defp appraisal_for("high"), do: "Investigate and adversarially review"
  defp appraisal_for("medium"), do: "Track and gather more evidence"
  defp appraisal_for("low"), do: "Low urgency, preserve context"
  defp appraisal_for(_), do: "Track and gather more evidence"

  defp percentage(value) when is_float(value), do: "#{Float.round(value * 100, 0)}%"

  defp commit_day(unix) do
    unix
    |> DateTime.from_unix!()
    |> Calendar.strftime("%Y-%m-%d")
  end

  defp short_sha(sha), do: String.slice(sha, 0, 8)

  defp demo_ids do
    ["forgejo", "kubernetes", "nixpkgs"]
  end
end

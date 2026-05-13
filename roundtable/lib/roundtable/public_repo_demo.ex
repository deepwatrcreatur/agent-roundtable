defmodule Roundtable.PublicRepoDemo do
  @moduledoc """
  Builds reproducible public-repo demo snapshots from the curated investor demo
  catalog.

  The first pass does not clone full repositories. Instead, it resolves the
  public source's advertised refs with `git ls-remote`, then combines that live
  source metadata with the curated Vaglio analysis payload.
  """

  alias Roundtable.{InvestorDemo, SystemCmdRunner}

  @type options :: keyword()

  @spec snapshot(String.t(), options()) :: {:ok, map()} | {:error, term()}
  def snapshot(id, opts \\ []) do
    runner = Keyword.get(opts, :runner, SystemCmdRunner)
    base_url = Keyword.get(opts, :base_url, "https://codeberg.org")

    with {:ok, demo} <- InvestorDemo.import(id, base_url: base_url),
         {:ok, source_snapshot} <- source_snapshot(demo, runner: runner) do
      {:ok,
       %{
         generated_at: Keyword.get(opts, :generated_at, DateTime.utc_now() |> DateTime.to_iso8601()),
         demo: %{
           id: demo.id,
           name: demo.name,
           teaser: demo.teaser
         },
         source: source_snapshot,
         imported_repo: demo.imported_repo,
         shell_inputs: demo.shell_inputs,
         import_steps: demo.import_steps,
         dashboard: demo.dashboard
       }}
    end
  end

  @spec export_snapshot(String.t(), options()) :: {:ok, Path.t()} | {:error, term()}
  def export_snapshot(id, opts \\ []) do
    output_root = Keyword.get(opts, :output_root, "reports/public-repo-demos")

    with {:ok, snapshot} <- snapshot(id, opts) do
      File.mkdir_p!(output_root)
      path = Path.join(output_root, "#{id}.json")
      File.write!(path, Jason.encode_to_iodata!(snapshot, pretty: true))
      {:ok, path}
    end
  end

  defp source_snapshot(demo, opts) do
    runner = Keyword.fetch!(opts, :runner)
    source = demo.source
    clone_url = clone_url(source.url)
    tracked_ref = "refs/heads/#{demo.shell_inputs.default_branch}"

    case runner.cmd("git", ["ls-remote", clone_url, "HEAD", tracked_ref], stderr_to_stdout: true) do
      {output, 0} ->
        {:ok,
         %{
           label: source.label,
           slug: source.slug,
           url: source.url,
           clone_url: clone_url,
           tracked_ref: tracked_ref,
           refs: parse_ls_remote(output)
         }}

      {output, status} ->
        {:error, {:ls_remote_failed, status, output}}
    end
  end

  defp parse_ls_remote(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      case String.split(line, "\t", parts: 2) do
        [sha, ref] -> %{ref: ref, sha: sha}
        [sha] -> %{ref: "unknown", sha: sha}
      end
    end)
  end

  defp clone_url(url) do
    if String.ends_with?(url, ".git"), do: url, else: url <> ".git"
  end
end

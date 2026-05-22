defmodule Mix.Tasks.Roundtable.SnaReports do
  @shortdoc "Export markdown SNA-style reports for the public demo repos"

  use Mix.Task

  alias Roundtable.PublicRepoSnaReports

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    opts = parse_args(args)

    case PublicRepoSnaReports.export_all(opts) do
      {:ok, paths} ->
        Enum.each(paths, &Mix.shell().info("wrote #{&1}"))

      {:error, reason} ->
        Mix.raise("failed to export SNA reports: #{inspect(reason)}")
    end
  end

  def parse_args(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [output_root: :string, snapshot_output_root: :string, base_url: :string]
      )

    if invalid != [] or positional != [] do
      raise usage("unexpected arguments")
    end

    opts
  end

  defp usage(reason) do
    "#{reason}\nusage: mix roundtable.sna_reports [--output-root <dir>] [--snapshot-output-root <dir>] [--base-url <url>]"
  end
end

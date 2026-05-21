defmodule Mix.Tasks.Roundtable.DemoSnapshot do
  @shortdoc "Export a reproducible public-repo demo snapshot"

  use Mix.Task

  alias Roundtable.PublicRepoDemo

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    {demo_id, opts} = parse_args(args)

    case PublicRepoDemo.export_snapshot(demo_id, opts) do
      {:ok, path} ->
        Mix.shell().info("wrote #{path}")

      {:error, reason} ->
        Mix.raise("failed to export #{demo_id}: #{inspect(reason)}")
    end
  end

  def parse_args(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [output_root: :string, base_url: :string]
      )

    if invalid != [] do
      raise usage("invalid arguments: #{inspect(invalid)}")
    end

    demo_id =
      case positional do
        [id] -> id
        _ -> raise usage("expected exactly one demo id")
      end

    {demo_id, opts}
  end

  defp usage(reason) do
    "#{reason}\nusage: mix roundtable.demo_snapshot <demo-id> [--output-root <dir>] [--base-url <url>]"
  end
end

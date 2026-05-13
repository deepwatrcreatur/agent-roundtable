defmodule Mix.Tasks.Roundtable.DemoSnapshot do
  @shortdoc "Export a reproducible public-repo demo snapshot"

  use Mix.Task

  alias Roundtable.PublicRepoDemo

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, positional, _invalid} =
      OptionParser.parse(args,
        strict: [output_root: :string, base_url: :string]
      )

    demo_id =
      case positional do
        [id | _] -> id
        _ -> raise "usage: mix roundtable.demo_snapshot <demo-id> [--output-root <dir>] [--base-url <url>]"
      end

    case PublicRepoDemo.export_snapshot(demo_id, opts) do
      {:ok, path} ->
        Mix.shell().info("wrote #{path}")

      {:error, reason} ->
        Mix.raise("failed to export #{demo_id}: #{inspect(reason)}")
    end
  end
end

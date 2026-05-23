defmodule Mix.Tasks.Roundtable.SeedBoardDemo do
  @shortdoc "Seed a small browseable board demo into a local board repo"

  use Mix.Task

  alias Roundtable.BoardDemoSeed

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    repo_path = parse_args(args)

    case BoardDemoSeed.seed(repo_path) do
      :ok ->
        Mix.shell().info("seeded board demo into #{repo_path}")

      {:error, reason} ->
        Mix.raise("failed to seed board demo: #{inspect(reason)}")
    end
  end

  @doc false
  def parse_args(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [repo_path: :string]
      )

    if invalid != [] do
      raise usage("invalid arguments: #{inspect(invalid)}")
    end

    case positional do
      [] ->
        Keyword.get(opts, :repo_path) ||
          System.get_env("ROUNDTABLE_BOARD_REPO_PATH") ||
          System.get_env("ROUNDTABLE_LOCAL_PATH") ||
          raise usage("board repo path is required")

      [repo_path] ->
        repo_path

      _ ->
        raise usage("expected at most one positional repo path")
    end
  end

  defp usage(reason) do
    "#{reason}\nusage: mix roundtable.seed_board_demo [<repo-path>] [--repo-path <dir>]"
  end
end

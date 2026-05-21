defmodule Mix.Tasks.Roundtable.PrewarmPublicRepoCache do
  @shortdoc "Prewarm cached public-repo demo snapshots"

  use Mix.Task

  alias Roundtable.{InvestorDemo, PublicRepoDemo}

  @impl true
  def run(args) do
    {demo_ids, opts} = parse_args(args)
    PublicRepoDemo.prewarm(demo_ids, opts)
  end

  @doc false
  def parse_args(args) do
    {opts, positional, _invalid} =
      OptionParser.parse(args,
        strict: [base_url: :string, timeout_ms: :integer, ttl_ms: :integer, cache_root: :string]
      )

    demo_ids =
      case positional do
        [] -> Enum.map(InvestorDemo.catalog(), & &1.id)
        ids -> ids
      end

    {demo_ids, opts}
  end
end

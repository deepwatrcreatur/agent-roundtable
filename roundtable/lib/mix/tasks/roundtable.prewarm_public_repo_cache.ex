defmodule Mix.Tasks.Roundtable.PrewarmPublicRepoCache do
  @shortdoc "Prewarm cached public-repo demo snapshots"

  use Mix.Task

  alias Roundtable.{InvestorDemo, PublicRepoDemo}

  @impl true
  def run(args) do
    {opts, positional, _invalid} =
      OptionParser.parse(args,
        strict: [base_url: :string, timeout_ms: :integer, ttl_ms: :integer, cache_root: :string]
      )

    demo_ids =
      case positional do
        [] -> Enum.map(InvestorDemo.catalog(), & &1.id)
        ids -> ids
      end

    Enum.each(demo_ids, fn demo_id ->
      case PublicRepoDemo.cached_snapshot(demo_id, opts) do
        {:ok, snapshot} ->
          Mix.shell().info(
            "warmed #{demo_id} -> #{snapshot.source.slug} (#{snapshot.source.history_summary.sampled_commit_count} sampled commits)"
          )

        {:error, reason} ->
          Mix.shell().error("failed to warm #{demo_id}: #{inspect(reason)}")
      end
    end)
  end
end

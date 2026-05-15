defmodule Mix.Tasks.Roundtable.PrewarmPublicRepoCacheTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Roundtable.PrewarmPublicRepoCache

  test "parse_args keeps options out of demo ids" do
    assert {["forgejo", "nixpkgs"], opts} =
             PrewarmPublicRepoCache.parse_args([
               "--timeout-ms",
               "30000",
               "--ttl-ms",
               "60000",
               "forgejo",
               "nixpkgs"
             ])

    assert opts[:timeout_ms] == 30_000
    assert opts[:ttl_ms] == 60_000
  end

  test "parse_args defaults to all catalog demos when none are provided" do
    {demo_ids, opts} = PrewarmPublicRepoCache.parse_args([])

    assert demo_ids != []
    assert is_list(demo_ids)
    assert opts == []
  end
end

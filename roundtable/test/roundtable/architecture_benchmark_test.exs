defmodule Roundtable.ArchitectureBenchmarkTest do
  use ExUnit.Case, async: true

  alias Roundtable.ArchitectureBenchmark

  describe "compare/1" do
    test "returns a reproducible workload with two benchmarked paths" do
      assert {:ok, benchmark} = ArchitectureBenchmark.compare("nixpkgs")

      assert benchmark.title =~ "Nixpkgs"
      assert benchmark.workload.concurrent_changes > 0
      assert benchmark.workload.ephemeral_workspaces > 0
      assert length(benchmark.workload.provenance_hooks) >= 2
      assert Enum.map(benchmark.paths, & &1.id) == [:jj_native, :git_compatible]
      assert benchmark.recommendation.summary =~ "`jj`"
      assert "change identity" in benchmark.recommendation.native_zone
      assert "repo browsing" in benchmark.recommendation.compatible_zone
    end

    test "rejects unknown profiles" do
      assert {:error, {:unknown_benchmark_profile, "missing"}} =
               ArchitectureBenchmark.compare("missing")
    end
  end
end

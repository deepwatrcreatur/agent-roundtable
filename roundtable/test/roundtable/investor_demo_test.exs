defmodule Roundtable.InvestorDemoTest do
  use ExUnit.Case, async: true

  alias Roundtable.InvestorDemo

  describe "catalog/0" do
    test "ships multiple public repo demos" do
      catalog = InvestorDemo.catalog()

      assert length(catalog) >= 2
      assert Enum.any?(catalog, &(&1.id == "nixpkgs"))
      assert Enum.any?(catalog, &(&1.id == "kubernetes"))
    end
  end

  describe "import/2" do
    test "builds an end-to-end demo payload for a curated repo" do
      assert {:ok, demo} = InvestorDemo.import("nixpkgs", base_url: "https://forgejo.example.org")

      assert demo.source.slug == "NixOS/nixpkgs"
      assert demo.imported_repo.slug == "vaglio-demos/nixpkgs"
      assert demo.imported_repo.repo_url == "https://forgejo.example.org/vaglio-demos/nixpkgs"
      assert demo.shell_inputs.repo_slug == "vaglio-demos/nixpkgs"
      assert demo.shell_inputs.pull_number == 1204
      assert length(demo.import_steps) == 3
      assert length(demo.dashboard.metrics) >= 3
      assert length(demo.dashboard.hotspots) >= 2
      assert length(demo.dashboard.provenance) >= 2
    end

    test "rejects unknown demo ids" do
      assert {:error, {:unknown_demo_repo, "missing"}} = InvestorDemo.import("missing")
    end
  end
end

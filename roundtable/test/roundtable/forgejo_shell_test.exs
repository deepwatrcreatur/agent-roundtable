defmodule Roundtable.ForgejoShellTest do
  use ExUnit.Case, async: true

  alias Roundtable.Adapters.Forgejo
  alias Roundtable.ForgejoShell

  describe "build/1" do
    test "builds a Forgejo-edge shell model with Vaglio analysis projections" do
      assert {:ok, shell} =
               ForgejoShell.build(
                 base_url: "https://forgejo.example.org",
                 repo_slug: "acme/platform",
                 default_branch: "main",
                 head_ref: "feature/vaglio",
                 commit_sha: "deadbeef",
                 pull_number: 42,
                 merge_strategy: :squash
               )

      assert shell.repo.repo_url == "https://forgejo.example.org/acme/platform"
      assert shell.repo.tree_url == "https://forgejo.example.org/acme/platform/src/branch/main"
      assert shell.repo.pulls_url == "https://forgejo.example.org/acme/platform/pulls"
      assert shell.discussion_repo.backend == Forgejo
      assert shell.discussion_repo.config == %{base_url: "https://forgejo.example.org"}
      assert shell.analysis.branch_projection.jj.bookmark == "git/heads/main"
      assert shell.analysis.review_projection.jj.change_key == "git/pr/42"
      assert shell.analysis.merge_projection.provenance.lossy == true
      assert Enum.any?(shell.boundaries, &(&1.owner == :forgejo))
      assert Enum.any?(shell.boundaries, &(&1.owner == :vaglio))
    end

    test "rejects invalid Forgejo base URLs" do
      assert {:error, {:invalid_base_url, "forgejo.example.org"}} =
               ForgejoShell.build(base_url: "forgejo.example.org")
    end

    test "rejects invalid repo slugs" do
      assert {:error, {:invalid_repo_slug, "not-a-slug"}} =
               ForgejoShell.build(repo_slug: "not-a-slug")
    end

    test "normalizes merge strategy strings" do
      assert {:ok, shell} = ForgejoShell.build(merge_strategy: "rebase")
      assert shell.analysis.merge_projection.jj.merge_strategy == :rebase
      assert shell.analysis.merge_projection.provenance.lossy == true
    end
  end
end

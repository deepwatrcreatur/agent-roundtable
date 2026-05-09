defmodule Roundtable.DiscussionRepoTest do
  use ExUnit.Case, async: true

  alias Roundtable.DiscussionRepo
  alias Roundtable.TestSupport.StubBackend

  defp repo(files \\ %{}) do
    Process.put(:stub_files, files)
    Process.put(:stub_written, %{})
    DiscussionRepo.new("owner/test-discussion", backend: StubBackend)
  end

  describe "new/2" do
    test "sets defaults" do
      r = DiscussionRepo.new("owner/repo")
      assert r.gh_slug == "owner/repo"
      assert r.issues_enabled == false
      assert r.token == nil
      assert r.head_sha == nil
      assert r.backend == Roundtable.Adapters.GitHub
    end

    test "accepts all options" do
      r =
        DiscussionRepo.new("owner/repo",
          token: "tok",
          local_path: "/tmp/repo",
          issues_enabled: true,
          backend: StubBackend,
          config: %{base_url: "https://forgejo.example.org"}
        )

      assert r.token == "tok"
      assert r.local_path == "/tmp/repo"
      assert r.issues_enabled == true
      assert r.backend == StubBackend
      assert r.config == %{base_url: "https://forgejo.example.org"}
    end
  end

  describe "read_file/2" do
    test "returns content for existing file" do
      r = repo(%{"BRIEF.md" => "# Brief\n\nQ1 — test"})
      assert {:ok, "# Brief\n\nQ1 — test"} = DiscussionRepo.read_file(r, "BRIEF.md")
    end

    test "returns error for missing file" do
      r = repo(%{})
      assert {:error, {:api_failed, 404, _}} = DiscussionRepo.read_file(r, "BRIEF.md")
    end
  end

  describe "write_file/4" do
    test "returns updated repo and records the write" do
      r = repo()
      {:ok, updated} = DiscussionRepo.write_file(r, "rounds/round-01.md", "content", "msg")
      assert %DiscussionRepo{} = updated
      assert Process.get(:stub_written)["rounds/round-01.md"] == "content"
    end
  end

  describe "list_files/2" do
    test "returns entry names at path" do
      r =
        repo(%{
          "rounds/round-01-q1.md" => "a",
          "rounds/round-02-q2.md" => "b",
          "BRIEF.md" => "c"
        })

      {:ok, names} = DiscussionRepo.list_files(r, "rounds")
      assert Enum.sort(names) == ["round-01-q1.md", "round-02-q2.md"]
    end

    test "returns empty list when path has no entries" do
      r = repo(%{})
      assert {:ok, []} = DiscussionRepo.list_files(r, "rounds")
    end
  end

  describe "valid?/1" do
    test "returns true when roundtable.toml exists" do
      r = repo(%{"roundtable.toml" => "schema_version = 1"})
      assert DiscussionRepo.valid?(r)
    end

    test "returns false when roundtable.toml is absent" do
      r = repo(%{})
      refute DiscussionRepo.valid?(r)
    end
  end
end

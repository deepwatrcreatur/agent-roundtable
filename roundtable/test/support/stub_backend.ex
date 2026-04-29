defmodule Roundtable.TestSupport.StubBackend do
  @moduledoc """
  In-memory `DiscussionRepo.Backend` for unit tests.

  Seed files via the process dictionary before each test:

      Process.put(:stub_files, %{"BRIEF.md" => "# Brief", "roundtable.toml" => "..."})

  Written files are accumulated in `:stub_written` so tests can assert on them:

      assert Process.get(:stub_written)["rounds/round-01-q1.md"] =~ "satisfied"
  """

  @behaviour Roundtable.DiscussionRepo.Backend

  @impl true
  def read_file(_repo, path) do
    files = Process.get(:stub_files, %{})

    case Map.fetch(files, path) do
      {:ok, content} -> {:ok, content}
      :error -> {:error, {:api_failed, 404, "not found: #{path}"}}
    end
  end

  @impl true
  def write_file(repo, path, content, _message) do
    written = Process.get(:stub_written, %{})
    Process.put(:stub_written, Map.put(written, path, content))
    {:ok, repo}
  end

  @impl true
  def list_files(_repo, path) do
    files = Process.get(:stub_files, %{})
    prefix = path <> "/"

    names =
      files
      |> Map.keys()
      |> Enum.filter(&String.starts_with?(&1, prefix))
      |> Enum.map(&String.replace_leading(&1, prefix, ""))
      |> Enum.reject(&String.contains?(&1, "/"))

    {:ok, names}
  end

  @impl true
  def discussion_repo?(_repo) do
    files = Process.get(:stub_files, %{})
    Map.has_key?(files, "roundtable.toml")
  end
end

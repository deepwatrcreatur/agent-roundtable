defmodule Roundtable.AuthTest do
  use ExUnit.Case, async: true

  alias Roundtable.Auth

  setup do
    previous = Application.get_env(:roundtable, Roundtable.Auth)

    on_exit(fn ->
      if previous == nil do
        Application.delete_env(:roundtable, Roundtable.Auth)
      else
        Application.put_env(:roundtable, Roundtable.Auth, previous)
      end

      System.delete_env("GITHUB_SERVICE_PAT")
      System.delete_env("GH_TOKEN")
    end)

    :ok
  end

  test "repo_readable_by?/2 accepts readable permissions" do
    Application.put_env(:roundtable, Roundtable.Auth,
      http_client: fn :get, "https://api.github.com/repos/owner/repo/collaborators/deep/permission", opts ->
        assert {"authorization", "Bearer ghp_test"} in Keyword.fetch!(opts, :headers)
        {:ok, %{status: 200, body: %{"permission" => "read"}}}
      end
    )

    System.put_env("GITHUB_SERVICE_PAT", "ghp_test")

    assert Auth.repo_readable_by?("owner/repo", "deep") == {:ok, true}
  end

  test "repo_readable_by?/2 returns false for missing collaborator access" do
    Application.put_env(:roundtable, Roundtable.Auth,
      http_client: fn :get, "https://api.github.com/repos/owner/repo/collaborators/deep/permission", _opts ->
        {:ok, %{status: 404, body: %{}}}
      end
    )

    System.put_env("GITHUB_SERVICE_PAT", "ghp_test")

    assert Auth.repo_readable_by?("owner/repo", "deep") == {:ok, false}
  end
end

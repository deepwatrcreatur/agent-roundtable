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

      System.delete_env("OIDC_ISSUER_URL")
      System.delete_env("GITHUB_SERVICE_PAT")
      System.delete_env("GH_TOKEN")
    end)

    :ok
  end

  test "repo_readable_by?/2 accepts readable permissions" do
    Application.put_env(:roundtable, Roundtable.Auth,
      http_client: fn :get,
                      "https://api.github.com/repos/owner/repo/collaborators/deep/permission",
                      opts ->
        assert {"authorization", "Bearer ghp_test"} in Keyword.fetch!(opts, :headers)
        {:ok, %{status: 200, body: %{"permission" => "read"}}}
      end
    )

    System.put_env("GITHUB_SERVICE_PAT", "ghp_test")

    assert Auth.repo_readable_by?("owner/repo", "deep") == {:ok, true}
  end

  test "repo_readable_by?/2 returns false for missing collaborator access" do
    Application.put_env(:roundtable, Roundtable.Auth,
      http_client: fn :get,
                      "https://api.github.com/repos/owner/repo/collaborators/deep/permission",
                      _opts ->
        {:ok, %{status: 404, body: %{}}}
      end
    )

    System.put_env("GITHUB_SERVICE_PAT", "ghp_test")

    assert Auth.repo_readable_by?("owner/repo", "deep") == {:ok, false}
  end

  test "authorization_url/2 returns an error when discovery metadata is incomplete" do
    Application.put_env(:roundtable, Roundtable.Auth,
      http_client: fn :get, "https://issuer.example/.well-known/openid-configuration", _opts ->
        {:ok, %{status: 200, body: %{"token_endpoint" => "https://issuer.example/token"}}}
      end
    )

    System.put_env("OIDC_ISSUER_URL", "https://issuer.example")

    assert Auth.authorization_url("state", "https://app.example/auth/callback") ==
             {:error, :missing_oidc_metadata}
  end

  test "repo_readable_by?/2 rejects invalid repo slugs before making a request" do
    System.put_env("GITHUB_SERVICE_PAT", "ghp_test")

    assert Auth.repo_readable_by?("owner/repo?tab=issues", "deep") == {:error, :invalid_repo}
  end

  test "repo_readable_by?/2 rejects invalid GitHub logins before making a request" do
    System.put_env("GITHUB_SERVICE_PAT", "ghp_test")

    assert Auth.repo_readable_by?("owner/repo", "deep/user") == {:error, :invalid_github_login}
  end
end

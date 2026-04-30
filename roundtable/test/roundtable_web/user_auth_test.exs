defmodule RoundtableWeb.UserAuthTest do
  use ExUnit.Case, async: false

  alias RoundtableWeb.UserAuth

  setup do
    prev_env = Application.get_env(:roundtable, UserAuth)
    prev_oidc_issuer = System.get_env("OIDC_ISSUER_URL")
    prev_oidc_client_id = System.get_env("OIDC_CLIENT_ID")
    prev_oidc_client_secret = System.get_env("OIDC_CLIENT_SECRET")
    prev_repo = System.get_env("ROUNDTABLE_REPO")
    prev_pat = System.get_env("GITHUB_SERVICE_PAT")

    on_exit(fn ->
      if prev_env == nil do
        Application.delete_env(:roundtable, UserAuth)
      else
        Application.put_env(:roundtable, UserAuth, prev_env)
      end

      restore_env("OIDC_ISSUER_URL", prev_oidc_issuer)
      restore_env("OIDC_CLIENT_ID", prev_oidc_client_id)
      restore_env("OIDC_CLIENT_SECRET", prev_oidc_client_secret)
      restore_env("ROUNDTABLE_REPO", prev_repo)
      restore_env("GITHUB_SERVICE_PAT", prev_pat)
    end)

    :ok
  end

  test "oidc_enabled?/0 requires all three oidc env vars" do
    System.delete_env("OIDC_ISSUER_URL")
    System.delete_env("OIDC_CLIENT_ID")
    System.delete_env("OIDC_CLIENT_SECRET")
    refute UserAuth.oidc_enabled?()

    System.put_env("OIDC_ISSUER_URL", "https://auth.example.com")
    System.put_env("OIDC_CLIENT_ID", "client-id")
    System.put_env("OIDC_CLIENT_SECRET", "client-secret")
    assert UserAuth.oidc_enabled?()
  end

  test "normalize_user/1 maps preferred_username and email" do
    claims = %{"preferred_username" => "deepwatr", "email" => "user@example.com", "sub" => "123"}

    assert UserAuth.normalize_user(claims) == %{
             github_login: "deepwatr",
             email: "user@example.com",
             sub: "123"
           }
  end

  test "repo_access_allowed?/2 allows empty repo without check" do
    refute UserAuth.repo_access_allowed?(nil, "owner/repo")
    assert UserAuth.repo_access_allowed?("deepwatr", "")
  end

  test "on_mount redirects when oidc is enabled and no session user exists" do
    System.put_env("OIDC_ISSUER_URL", "https://auth.example.com")
    System.put_env("OIDC_CLIENT_ID", "client-id")
    System.put_env("OIDC_CLIENT_SECRET", "client-secret")

    socket = %Phoenix.LiveView.Socket{}

    assert {:halt, redirected} = UserAuth.on_mount(:ensure_authenticated, %{}, %{}, socket)
    assert {:redirect, %{to: "/auth/sign_in"}} = redirected.redirected
  end

  test "on_mount assigns current_user when present in session" do
    System.put_env("OIDC_ISSUER_URL", "https://auth.example.com")
    System.put_env("OIDC_CLIENT_ID", "client-id")
    System.put_env("OIDC_CLIENT_SECRET", "client-secret")

    user = %{"github_login" => "deepwatr", "email" => "user@example.com"}
    socket = %Phoenix.LiveView.Socket{}

    assert {:cont, updated} =
             UserAuth.on_mount(:ensure_authenticated, %{}, %{"current_user" => user}, socket)

    assert updated.assigns.current_user == user
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end

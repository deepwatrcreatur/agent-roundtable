defmodule RoundtableWeb.AuthControllerTest do
  use RoundtableWeb.ConnCase, async: false

  alias RoundtableWeb.{AuthController, UserAuth}

  setup %{conn: conn} do
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

    conn =
      conn
      |> Map.put(:host, "roundtable.example.com")
      |> Map.put(:port, 443)
      |> Phoenix.ConnTest.init_test_session(%{})

    :ok = enable_oidc()

    {:ok, conn: conn}
  end

  test "sign_in redirects to oidc provider and stores session params", %{conn: conn} do
    Application.put_env(:roundtable, UserAuth,
      oidc_client: %{
        authorize_url: fn _config ->
          {:ok, %{url: "https://auth.example.com/authorize", session_params: %{"state" => "abc"}}}
        end
      }
    )

    conn = AuthController.sign_in(conn, %{})

    assert redirected_to(conn, 302) == "https://auth.example.com/authorize"
    assert Plug.Conn.get_session(conn, UserAuth.oidc_session_key()) == %{"state" => "abc"}
  end

  test "callback stores current_user and redirects home when repo access is allowed", %{conn: conn} do
    Application.put_env(
      :roundtable,
      UserAuth,
      oidc_client: %{
        callback: fn _config, _params, _session_params ->
          {:ok, %{user: %{"preferred_username" => "deepwatr", "email" => "u@example.com", "sub" => "1"}}}
        end
      },
      github_client: fn "deepwatr", "owner/repo", _pat -> true end
    )

    System.put_env("ROUNDTABLE_REPO", "owner/repo")

    conn =
      conn
      |> Plug.Conn.put_session(UserAuth.oidc_session_key(), %{"state" => "abc"})
      |> AuthController.callback(%{"code" => "token", "state" => "abc"})

    assert redirected_to(conn, 302) == "/"
    assert Plug.Conn.get_session(conn, UserAuth.current_user_session_key()) == %{
             github_login: "deepwatr",
             email: "u@example.com",
             sub: "1"
           }
  end

  test "callback redirects back to sign-in when repo access is denied", %{conn: conn} do
    Application.put_env(
      :roundtable,
      UserAuth,
      oidc_client: %{
        callback: fn _config, _params, _session_params ->
          {:ok, %{user: %{"preferred_username" => "deepwatr", "email" => "u@example.com", "sub" => "1"}}}
        end
      },
      github_client: fn "deepwatr", "owner/repo", _pat -> false end
    )

    System.put_env("ROUNDTABLE_REPO", "owner/repo")

    conn =
      conn
      |> Plug.Conn.put_session(UserAuth.oidc_session_key(), %{"state" => "abc"})
      |> AuthController.callback(%{"code" => "token", "state" => "abc"})

    assert redirected_to(conn, 302) == "/auth/sign_in"
    assert Plug.Conn.get_session(conn, UserAuth.current_user_session_key()) == nil
  end

  test "sign_in falls back home when oidc is disabled", %{conn: conn} do
    System.delete_env("OIDC_ISSUER_URL")
    System.delete_env("OIDC_CLIENT_ID")
    System.delete_env("OIDC_CLIENT_SECRET")

    conn = AuthController.sign_in(conn, %{})

    assert redirected_to(conn, 302) == "/"
  end

  defp enable_oidc do
    System.put_env("OIDC_ISSUER_URL", "https://auth.example.com")
    System.put_env("OIDC_CLIENT_ID", "client-id")
    System.put_env("OIDC_CLIENT_SECRET", "client-secret")
    :ok
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end

defmodule RoundtableWeb.AuthControllerTest do
  use RoundtableWeb.ConnCase, async: true

  setup_all do
    case start_supervised(RoundtableWeb.Endpoint) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  setup do
    previous_auth = Application.get_env(:roundtable, Roundtable.Auth)

    on_exit(fn ->
      if previous_auth == nil do
        Application.delete_env(:roundtable, Roundtable.Auth)
      else
        Application.put_env(:roundtable, Roundtable.Auth, previous_auth)
      end

      System.delete_env("OIDC_ISSUER_URL")
    end)

    :ok
  end

  test "sign_in uses the configured endpoint URL for the callback", %{conn: conn} do
    Application.put_env(:roundtable, Roundtable.Auth,
      http_client: fn :get, "https://issuer.example/.well-known/openid-configuration", _opts ->
        {:ok,
         %{
           status: 200,
           body: %{
             "authorization_endpoint" => "https://issuer.example/authorize",
             "token_endpoint" => "https://issuer.example/token",
             "userinfo_endpoint" => "https://issuer.example/userinfo"
           }
         }}
      end
    )

    System.put_env("OIDC_ISSUER_URL", "https://issuer.example")

    conn = get(conn, "/auth/sign_in")

    assert redirected_to(conn, 302) ==
             "https://issuer.example/authorize?client_id=&redirect_uri=http%3A%2F%2Flocalhost%3A4002%2Fauth%2Fcallback&response_type=code&scope=openid+profile+email&state=" <>
               get_session(conn, :oidc_state)
  end

  test "callback route handles missing code or state", %{conn: conn} do
    conn = get(conn, "/auth/callback")

    assert redirected_to(conn, 302) == "/"
  end
end

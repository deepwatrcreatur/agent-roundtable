defmodule RoundtableWeb.AuthController do
  use Phoenix.Controller, formats: [:html]

  alias RoundtableWeb.UserAuth

  def sign_in(conn, _params) do
    if UserAuth.oidc_enabled?() do
      redirect_uri = callback_url(conn)

      case UserAuth.authorize_url(redirect_uri) do
        {:ok, %{url: url, session_params: session_params}} ->
          conn
          |> put_session(UserAuth.oidc_session_key(), session_params)
          |> redirect(external: url)

        {:error, reason} ->
          conn
          |> put_flash(:error, "OIDC sign-in failed: #{inspect(reason)}")
          |> redirect(to: "/")
      end
    else
      redirect(conn, to: "/")
    end
  end

  def callback(conn, params) do
    if UserAuth.oidc_enabled?() do
      redirect_uri = callback_url(conn)
      session_params = get_session(conn, UserAuth.oidc_session_key()) || %{}

      case UserAuth.exchange_code(params, session_params, redirect_uri) do
        {:ok, %{user: claims}} ->
          user = UserAuth.normalize_user(claims)
          repo = System.get_env("ROUNDTABLE_REPO", "")

          if UserAuth.repo_access_allowed?(user.github_login, repo) do
            conn
            |> delete_session(UserAuth.oidc_session_key())
            |> put_session(UserAuth.current_user_session_key(), user)
            |> redirect(to: "/")
          else
            conn
            |> delete_session(UserAuth.oidc_session_key())
            |> configure_session(drop: true)
            |> put_flash(:error, "You do not have access to this repository.")
            |> redirect(to: "/auth/sign_in")
          end

        {:error, reason} ->
          conn
          |> delete_session(UserAuth.oidc_session_key())
          |> put_flash(:error, "OIDC callback failed: #{inspect(reason)}")
          |> redirect(to: "/auth/sign_in")
      end
    else
      redirect(conn, to: "/")
    end
  end

  defp callback_url(conn) do
    "#{scheme(conn)}://#{conn.host}:#{conn.port}/auth/callback"
  end

  defp scheme(conn) do
    conn
    |> Plug.Conn.get_req_header("x-forwarded-proto")
    |> List.first()
    |> case do
      nil -> Atom.to_string(conn.scheme)
      scheme -> scheme
    end
  end
end

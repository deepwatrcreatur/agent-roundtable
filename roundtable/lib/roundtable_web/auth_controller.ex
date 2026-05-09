defmodule RoundtableWeb.AuthController do
  use Phoenix.Controller, namespace: RoundtableWeb

  import Plug.Conn

  alias Roundtable.Auth

  def sign_in(conn, _params) do
    if Auth.enabled?() do
      state = random_state()
      conn = put_session(conn, :oidc_state, state)

      case Auth.authorization_url(state, redirect_uri(conn)) do
        {:ok, url} ->
          redirect(conn, external: url)

        {:error, reason} ->
          conn
          |> put_flash(:error, "OIDC sign-in failed: #{format_reason(reason)}")
          |> redirect(to: "/")
      end
    else
      redirect(conn, to: "/")
    end
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    if get_session(conn, :oidc_state) == state do
      case Auth.exchange_code_for_user(code, redirect_uri(conn)) do
        {:ok, current_user} ->
          conn
          |> configure_session(renew: true)
          |> delete_session(:oidc_state)
          |> put_session(:current_user, current_user)
          |> redirect(to: "/")

        {:error, reason} ->
          conn
          |> configure_session(drop: true)
          |> put_flash(:error, "OIDC callback failed: #{format_reason(reason)}")
          |> redirect(to: "/")
      end
    else
      conn
      |> configure_session(drop: true)
      |> put_flash(:error, "OIDC callback rejected: invalid state.")
      |> redirect(to: "/")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "OIDC callback rejected: missing code or state.")
    |> redirect(to: "/")
  end

  def sign_out(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  defp redirect_uri(_conn) do
    RoundtableWeb.Endpoint.url()
    |> URI.merge("/auth/callback")
    |> URI.to_string()
  end

  defp random_state do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp format_reason({kind, status, body}), do: "#{kind} (#{status}): #{inspect(body)}"
  defp format_reason(reason), do: inspect(reason)
end

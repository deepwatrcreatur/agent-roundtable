defmodule RoundtableWeb.UserAuth do
  @moduledoc """
  Optional OIDC-backed auth gate for the owner dashboard.

  When `OIDC_ISSUER_URL` is unset, auth is disabled and the dashboard remains
  usable in localhost/dev mode.
  """

  import Phoenix.LiveView
  import Plug.Conn

  @session_key "current_user"
  @oidc_session_key "oidc_session_params"

  @type user :: %{
          optional(:github_login) => String.t() | nil,
          optional(:email) => String.t() | nil,
          optional(:sub) => String.t() | nil
        }

  def init(opts), do: opts

  def call(conn, opts), do: fetch_current_user(conn, opts)

  @spec fetch_current_user(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def fetch_current_user(conn, _opts) do
    Plug.Conn.assign(conn, :current_user, get_session(conn, @session_key))
  end

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:ensure_authenticated, _params, session, socket) do
    current_user = Map.get(session, @session_key)

    cond do
      not oidc_enabled?() ->
        {:cont, Phoenix.Component.assign(socket, :current_user, current_user)}

      is_map(current_user) ->
        {:cont, Phoenix.Component.assign(socket, :current_user, current_user)}

      true ->
        {:halt, redirect(socket, to: "/auth/sign_in")}
    end
  end

  @spec oidc_enabled?() :: boolean()
  def oidc_enabled? do
    present_env?("OIDC_ISSUER_URL") and
      present_env?("OIDC_CLIENT_ID") and
      present_env?("OIDC_CLIENT_SECRET")
  end

  @spec oidc_config(String.t()) :: keyword()
  def oidc_config(redirect_uri) do
    [
      base_url: System.fetch_env!("OIDC_ISSUER_URL"),
      client_id: System.fetch_env!("OIDC_CLIENT_ID"),
      client_secret: System.fetch_env!("OIDC_CLIENT_SECRET"),
      redirect_uri: redirect_uri
    ]
  end

  @spec oidc_session_key() :: String.t()
  def oidc_session_key, do: @oidc_session_key

  @spec current_user_session_key() :: String.t()
  def current_user_session_key, do: @session_key

  @spec exchange_code(map(), map(), String.t()) :: {:ok, map()} | {:error, term()}
  def exchange_code(params, session_params, redirect_uri) do
    client = oidc_client()

    case client do
      %{callback: callback} when is_function(callback, 3) ->
        callback.(oidc_config(redirect_uri), params, session_params)

      module ->
        module.callback(oidc_config(redirect_uri), params, session_params)
    end
  end

  @spec authorize_url(String.t()) :: {:ok, %{url: String.t(), session_params: map()}} | {:error, term()}
  def authorize_url(redirect_uri) do
    client = oidc_client()

    case client do
      %{authorize_url: authorize_url} when is_function(authorize_url, 1) ->
        authorize_url.(oidc_config(redirect_uri))

      module ->
        module.authorize_url(oidc_config(redirect_uri))
    end
  end

  @spec normalize_user(map()) :: user()
  def normalize_user(claims) do
    %{
      github_login:
        claims["preferred_username"] || claims["nickname"] || claims["github_login"],
      email: claims["email"],
      sub: claims["sub"]
    }
  end

  @spec repo_access_allowed?(String.t() | nil, String.t()) :: boolean()
  def repo_access_allowed?(_login, ""), do: true
  def repo_access_allowed?(nil, _repo), do: false

  def repo_access_allowed?(github_login, repo) do
    github_client().(github_login, repo, System.get_env("GITHUB_SERVICE_PAT"))
  end

  defp oidc_client do
    Application.get_env(:roundtable, __MODULE__, [])
    |> Keyword.get(:oidc_client, Assent.Strategy.OIDC)
  end

  defp github_client do
    Application.get_env(:roundtable, __MODULE__, [])
    |> Keyword.get(:github_client, &default_github_client/3)
  end

  defp default_github_client(_login, _repo, nil), do: false

  defp default_github_client(login, repo, token) do
    url = "https://api.github.com/repos/#{repo}/collaborators/#{login}"

    case Req.get(url: url, headers: [{"authorization", "Bearer #{token}"}]) do
      {:ok, %Req.Response{status: status}} when status in [200, 204] -> true
      {:ok, %Req.Response{status: _}} -> false
      {:error, _reason} -> false
    end
  end

  defp present_env?(name) do
    case System.get_env(name) do
      nil -> false
      "" -> false
      _ -> true
    end
  end
end

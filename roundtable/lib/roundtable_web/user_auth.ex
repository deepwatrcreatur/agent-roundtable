defmodule RoundtableWeb.UserAuth do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView

  alias Roundtable.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    assign(conn, :current_user, get_session(conn, :current_user))
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    current_user = session["current_user"]
    socket = assign(socket, :current_user, current_user)

    cond do
      not Auth.enabled?() ->
        {:cont, socket}

      is_map(current_user) ->
        {:cont, socket}

      true ->
        {:halt, Phoenix.LiveView.redirect(socket, to: "/auth/sign_in")}
    end
  end

  def authorize_repo(_current_user, repo) when repo in [nil, ""], do: :ok

  def authorize_repo(current_user, repo) do
    github_login = current_user && current_user["github_login"]

    cond do
      not Auth.enabled?() ->
        :ok

      github_login in [nil, ""] ->
        {:error, "GitHub identity is missing from the session."}

      true ->
        case Auth.repo_readable_by?(repo, github_login) do
          {:ok, true} ->
            :ok

          {:ok, false} ->
            {:error, "GitHub user #{github_login} does not have access to #{repo}."}

          {:error, :missing_service_pat} ->
            {:error, "The service is missing GITHUB_SERVICE_PAT/GH_TOKEN for repo access checks."}

          {:error, reason} ->
            {:error, "Repo access check failed: #{inspect(reason)}"}
        end
    end
  end
end

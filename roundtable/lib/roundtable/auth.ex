defmodule Roundtable.Auth do
  @moduledoc """
  Minimal OIDC and GitHub access helpers for the Vaglio web UI.

  When `OIDC_ISSUER_URL` is unset, the dashboard remains in unauthenticated
  mode for local development.
  """

  @github_api "https://api.github.com"
  @read_permissions ~w(admin maintain write triage read)

  def enabled? do
    issuer_url() != ""
  end

  def authorization_url(state, redirect_uri) do
    with :ok <- ensure_enabled(),
         {:ok, metadata} <- discovery_document() do
      params = %{
        "client_id" => client_id(),
        "redirect_uri" => redirect_uri,
        "response_type" => "code",
        "scope" => "openid profile email",
        "state" => state
      }

      {:ok, metadata["authorization_endpoint"] <> "?" <> URI.encode_query(params)}
    end
  end

  def exchange_code_for_user(code, redirect_uri) do
    with :ok <- ensure_enabled(),
         {:ok, metadata} <- discovery_document(),
         {:ok, tokens} <- exchange_code(metadata["token_endpoint"], code, redirect_uri),
         {:ok, userinfo} <- fetch_userinfo(metadata["userinfo_endpoint"], tokens["access_token"]),
         {:ok, current_user} <- normalize_user(userinfo) do
      {:ok, current_user}
    end
  end

  def repo_readable_by?(repo, github_login) when repo in [nil, ""] or github_login in [nil, ""] do
    {:error, :missing_repo_or_login}
  end

  def repo_readable_by?(repo, github_login) do
    case service_token() do
      nil ->
        {:error, :missing_service_pat}

      token ->
        url = "#{@github_api}/repos/#{repo}/collaborators/#{github_login}/permission"

        headers = [
          {"authorization", "Bearer #{token}"},
          {"accept", "application/vnd.github+json"},
          {"x-github-api-version", "2022-11-28"}
        ]

        with {:ok, %{status: 200, body: body}} <- request(:get, url, headers: headers) do
          permission = String.downcase(body["permission"] || "")
          {:ok, permission in @read_permissions}
        else
          {:ok, %{status: 404}} -> {:ok, false}
          {:ok, %{status: 403}} -> {:error, :github_forbidden}
          {:ok, %{status: status, body: body}} -> {:error, {:unexpected_github_status, status, body}}
          {:error, _} = err -> err
        end
    end
  end

  def filter_accessible_repos(repos, nil), do: repos

  def filter_accessible_repos(repos, github_login) do
    Enum.filter(repos, fn repo ->
      case repo_readable_by?(repo.slug, github_login) do
        {:ok, true} -> true
        _ -> false
      end
    end)
  end

  defp normalize_user(userinfo) do
    github_login =
      userinfo["preferred_username"] ||
        userinfo["nickname"] ||
        userinfo["username"] ||
        userinfo["sub"]

    if is_binary(github_login) and github_login != "" do
      {:ok,
       %{
         "github_login" => github_login,
         "email" => userinfo["email"],
         "name" => userinfo["name"]
       }}
    else
      {:error, :missing_github_login_claim}
    end
  end

  defp exchange_code(token_endpoint, code, redirect_uri) do
    form = [
      grant_type: "authorization_code",
      code: code,
      redirect_uri: redirect_uri,
      client_id: client_id(),
      client_secret: client_secret()
    ]

    with {:ok, %{status: 200, body: body}} <- request(:post, token_endpoint, form: form) do
      {:ok, body}
    else
      {:ok, %{status: status, body: body}} -> {:error, {:token_exchange_failed, status, body}}
      {:error, _} = err -> err
    end
  end

  defp fetch_userinfo(userinfo_endpoint, access_token) do
    headers = [{"authorization", "Bearer #{access_token}"}]

    with {:ok, %{status: 200, body: body}} <- request(:get, userinfo_endpoint, headers: headers) do
      {:ok, body}
    else
      {:ok, %{status: status, body: body}} -> {:error, {:userinfo_failed, status, body}}
      {:error, _} = err -> err
    end
  end

  defp discovery_document do
    url = issuer_url() <> "/.well-known/openid-configuration"

    with {:ok, %{status: 200, body: body}} <- request(:get, url) do
      {:ok, body}
    else
      {:ok, %{status: status, body: body}} -> {:error, {:discovery_failed, status, body}}
      {:error, _} = err -> err
    end
  end

  defp ensure_enabled do
    if enabled?(), do: :ok, else: {:error, :oidc_disabled}
  end

  defp issuer_url do
    config_value(:issuer_url, "OIDC_ISSUER_URL")
    |> to_string()
    |> String.trim()
    |> String.trim_trailing("/")
  end

  defp client_id do
    config_value(:client_id, "OIDC_CLIENT_ID")
    |> to_string()
  end

  defp client_secret do
    config_value(:client_secret, "OIDC_CLIENT_SECRET")
    |> to_string()
  end

  defp service_token do
    env = System.get_env("GITHUB_SERVICE_PAT") || System.get_env("GH_TOKEN")

    case String.trim(env || "") do
      "" -> nil
      token -> token
    end
  end

  defp config_value(key, env_var) do
    config = Application.get_env(:roundtable, __MODULE__, [])

    Keyword.get(config, key) || System.get_env(env_var) || ""
  end

  defp request(method, url, opts \\ []) do
    case Keyword.get(Application.get_env(:roundtable, __MODULE__, []), :http_client) do
      fun when is_function(fun, 3) ->
        fun.(method, url, opts)

      _ ->
        request_opts =
          [method: method, url: url, headers: Keyword.get(opts, :headers, [])]
          |> maybe_put(:form, Keyword.get(opts, :form))

        case Req.request(request_opts) do
          {:ok, %Req.Response{status: status, body: body}} -> {:ok, %{status: status, body: body}}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end

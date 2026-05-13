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
         {:ok, metadata} <- discovery_document(),
         {:ok, %{authorization_endpoint: authorization_endpoint}} <- endpoint_metadata(metadata) do
      params = %{
        "client_id" => client_id(),
        "redirect_uri" => redirect_uri,
        "response_type" => "code",
        "scope" => "openid profile email",
        "state" => state
      }

      {:ok, authorization_endpoint <> "?" <> URI.encode_query(params)}
    end
  end

  def exchange_code_for_user(code, redirect_uri) do
    with :ok <- ensure_enabled(),
         {:ok, metadata} <- discovery_document(),
         {:ok, %{token_endpoint: token_endpoint, userinfo_endpoint: userinfo_endpoint}} <-
           endpoint_metadata(metadata),
         {:ok, tokens} <- exchange_code(token_endpoint, code, redirect_uri),
         {:ok, access_token} <- access_token(tokens),
         {:ok, userinfo} <- fetch_userinfo(userinfo_endpoint, access_token),
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
        with {:ok, url} <- repo_permission_url(repo, github_login),
             {:ok, %{status: 200, body: body}} <-
               request(:get, url, headers: github_headers(token)),
             true <- is_map(body) or {:error, {:unexpected_github_body, body}} do
          permission = String.downcase(body["permission"] || "")
          {:ok, permission in @read_permissions}
        else
          {:ok, %{status: 404}} ->
            {:ok, false}

          {:ok, %{status: 403}} ->
            {:error, :github_forbidden}

          {:ok, %{status: status, body: body}} ->
            {:error, {:unexpected_github_status, status, body}}

          {:error, _} = err ->
            err
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

  defp endpoint_metadata(metadata) when is_map(metadata) do
    with authz when is_binary(authz) and authz != "" <- metadata["authorization_endpoint"],
         token when is_binary(token) and token != "" <- metadata["token_endpoint"],
         userinfo when is_binary(userinfo) and userinfo != "" <- metadata["userinfo_endpoint"] do
      {:ok,
       %{
         authorization_endpoint: authz,
         token_endpoint: token,
         userinfo_endpoint: userinfo
       }}
    else
      _ -> {:error, :missing_oidc_metadata}
    end
  end

  defp endpoint_metadata(_), do: {:error, :missing_oidc_metadata}

  defp access_token(%{"access_token" => token}) when is_binary(token) and token != "",
    do: {:ok, token}

  defp access_token(_), do: {:error, :missing_access_token}

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

  defp github_headers(token) do
    [
      {"authorization", "Bearer #{token}"},
      {"accept", "application/vnd.github+json"},
      {"x-github-api-version", "2022-11-28"}
    ]
  end

  defp repo_permission_url(repo, github_login) do
    with {:ok, {owner, name}} <- split_repo_slug(repo),
         {:ok, encoded_login} <- encode_github_login(github_login) do
      {:ok, "#{@github_api}/repos/#{owner}/#{name}/collaborators/#{encoded_login}/permission"}
    end
  end

  defp split_repo_slug(repo) do
    case String.split(to_string(repo), "/", parts: 2) do
      [owner, name] ->
        owner = String.trim(owner)
        name = String.trim(name)

        if valid_repo_segment?(owner) and valid_repo_segment?(name) do
          {:ok,
           {URI.encode(owner, &URI.char_unreserved?/1), URI.encode(name, &URI.char_unreserved?/1)}}
        else
          {:error, :invalid_repo}
        end

      _ ->
        {:error, :invalid_repo}
    end
  end

  defp encode_github_login(github_login) do
    login = github_login |> to_string() |> String.trim()

    if Regex.match?(~r/\A[a-zA-Z0-9-]+\z/, login) do
      {:ok, URI.encode(login, &URI.char_unreserved?/1)}
    else
      {:error, :invalid_github_login}
    end
  end

  defp valid_repo_segment?(segment) do
    segment != "" and Regex.match?(~r/\A[A-Za-z0-9._-]+\z/, segment)
  end

  defp request(method, url, opts \\ []) do
    if not is_binary(url) or url == "" do
      {:error, :invalid_url}
    else
      case Keyword.get(Application.get_env(:roundtable, __MODULE__, []), :http_client) do
        fun when is_function(fun, 3) ->
          fun.(method, url, opts)

        _ ->
          request_opts =
            [method: method, url: url, headers: Keyword.get(opts, :headers, [])]
            |> maybe_put(:form, Keyword.get(opts, :form))

          case Req.request(request_opts) do
            {:ok, %Req.Response{status: status, body: body}} ->
              {:ok, %{status: status, body: body}}

            {:error, reason} ->
              {:error, reason}
          end
      end
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end

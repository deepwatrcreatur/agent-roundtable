defmodule Roundtable.Adapters.Forgejo do
  @moduledoc """
  `DiscussionRepo.Backend` implementation using the Forgejo contents API via
  `curl`.

  Required config:

  - `:base_url` or `:api_base_url` — Forgejo host URL. When `:base_url` is
    provided, `/api/v1` is appended automatically.

  Optional config:

  - `:runner` — command runner module (defaults to `Roundtable.SystemCmdRunner`)
  - `:curl_bin` — curl executable name (defaults to `"curl"`)
  - `:auth_scheme` — `:token` (default) or `:bearer`

  Unlike GitHub's contents API, Forgejo uses `POST` to create a file and `PUT`
  to update one. This adapter keeps that distinction explicit instead of hiding
  it behind GitHub-shaped assumptions.
  """

  @behaviour Roundtable.DiscussionRepo.Backend

  alias Roundtable.{DiscussionRepo, SystemCmdRunner}

  @status_marker "__ROUNDTABLE_HTTP_STATUS__:"

  @impl true
  def read_file(%DiscussionRepo{gh_slug: slug} = repo, path) do
    path = repo_path(repo, path)

    with {:ok, json} <- forgejo_api(repo, :get, "/repos/#{slug}/contents/#{path}"),
         {:ok, decoded} <- JSON.decode(json),
         {:ok, content} <- extract_content(decoded) do
      {:ok, content}
    end
  end

  @impl true
  def write_file(%DiscussionRepo{gh_slug: slug} = repo, path, content, message) do
    path = repo_path(repo, path)

    case get_blob_sha(repo, path) do
      {:ok, sha} ->
        payload = %{"message" => message, "content" => Base.encode64(content), "sha" => sha}

        with {:ok, _json} <- forgejo_api(repo, :put, "/repos/#{slug}/contents/#{path}", payload) do
          {:ok, repo}
        end

      {:error, {:api_failed, 404, _}} ->
        payload = %{"message" => message, "content" => Base.encode64(content)}

        with {:ok, _json} <- forgejo_api(repo, :post, "/repos/#{slug}/contents/#{path}", payload) do
          {:ok, repo}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def list_files(%DiscussionRepo{gh_slug: slug} = repo, path) do
    path = repo_path(repo, path)

    case forgejo_api(repo, :get, "/repos/#{slug}/contents/#{path}") do
      {:ok, json} ->
        with {:ok, entries} <- JSON.decode(json) do
          {:ok, Enum.map(entries, & &1["name"])}
        end

      {:error, {:api_failed, 404, _}} ->
        {:ok, []}

      {:error, _} = err ->
        err
    end
  end

  @impl true
  def discussion_repo?(%DiscussionRepo{} = repo) do
    case read_file(repo, "roundtable.toml") do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp get_blob_sha(%DiscussionRepo{gh_slug: slug} = repo, path) do
    with {:ok, json} <- forgejo_api(repo, :get, "/repos/#{slug}/contents/#{path}"),
         {:ok, decoded} <- JSON.decode(json) do
      {:ok, decoded["sha"]}
    end
  end

  defp forgejo_api(repo, method, endpoint, body \\ nil) do
    with {:ok, api_base_url} <- api_base_url(repo),
         {:ok, response} <- curl(repo, method, api_base_url <> endpoint, body) do
      parse_http_response(response)
    end
  end

  defp curl(repo, method, url, body) do
    runner = get_in(repo.config, [:runner]) || SystemCmdRunner
    curl_bin = get_in(repo.config, [:curl_bin]) || "curl"

    args =
      [
        "--silent",
        "--show-error",
        "--location",
        "--write-out",
        "\\n#{@status_marker}%{http_code}",
        "-H",
        "Accept: application/json"
      ] ++ auth_args(repo) ++ build_method_args(method) ++ build_body_args(body) ++ [url]

    opts = build_opts(body)

    case runner.cmd(curl_bin, args, opts) do
      {stdout, 0} -> {:ok, stdout}
      {stdout, status} -> {:error, {:command_failed, status, stdout}}
    end
  end

  defp api_base_url(%DiscussionRepo{config: config}) do
    cond do
      is_binary(config[:api_base_url]) and config[:api_base_url] != "" ->
        {:ok, String.trim_trailing(config[:api_base_url], "/")}

      is_binary(config[:base_url]) and config[:base_url] != "" ->
        {:ok, String.trim_trailing(config[:base_url], "/") <> "/api/v1"}

      true ->
        {:error, {:missing_option, :base_url}}
    end
  end

  defp auth_args(%DiscussionRepo{token: nil}), do: []

  defp auth_args(%DiscussionRepo{token: token, config: config}) do
    scheme =
      case config[:auth_scheme] do
        :bearer -> "Bearer"
        _ -> "token"
      end

    ["-H", "Authorization: #{scheme} #{token}"]
  end

  defp build_method_args(:get), do: []
  defp build_method_args(:post), do: ["--request", "POST"]
  defp build_method_args(:put), do: ["--request", "PUT"]

  defp build_body_args(nil), do: []
  defp build_body_args(_body), do: ["-H", "Content-Type: application/json", "--data-binary", "@-"]

  defp build_opts(nil), do: [stderr_to_stdout: true]

  defp build_opts(body) do
    {:ok, json} = Jason.encode(body)
    [stderr_to_stdout: true, input: json]
  end

  defp parse_http_response(response) do
    case String.split(response, @status_marker) do
      [body, status] ->
        status_code =
          status
          |> String.trim()
          |> String.to_integer()

        case status_code do
          code when code in 200..299 -> {:ok, body}
          code -> {:error, {:api_failed, code, body}}
        end

      _ ->
        {:error, {:unexpected_response, response}}
    end
  end

  defp extract_content(%{"encoding" => "base64", "content" => content}) do
    cleaned = String.replace(content, "\n", "")
    {:ok, Base.decode64!(cleaned)}
  end

  defp extract_content(%{"content" => content}), do: {:ok, content}
  defp extract_content(_), do: {:error, :no_content_field}

  defp repo_path(%DiscussionRepo{base_path: nil}, path), do: path
  defp repo_path(%DiscussionRepo{base_path: base_path}, path), do: "#{base_path}/#{path}"
end

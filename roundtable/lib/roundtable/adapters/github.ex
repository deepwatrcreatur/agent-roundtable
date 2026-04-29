defmodule Roundtable.Adapters.GitHub do
  @moduledoc """
  `DiscussionRepo.Backend` implementation using the GitHub REST API via
  the `gh` CLI (`gh api`).

  ## Authentication

  When `repo.token` is set it is passed as a `Authorization: Bearer` header,
  overriding the CLI's ambient auth. When nil, `gh` uses its stored credentials.

  ## Write protocol

  GitHub's contents API requires the current blob SHA when updating an existing
  file. `write_file/4` fetches the SHA first (a second API call), then issues
  the PUT. New files (no existing SHA) are created in a single call.

  The JSON body is sent via stdin (`--input -`) to avoid shell-escaping issues
  with base64-encoded content.
  """

  @behaviour Roundtable.DiscussionRepo.Backend

  alias Roundtable.{DiscussionRepo, SystemCmdRunner}

  @impl true
  def read_file(%DiscussionRepo{gh_slug: slug} = repo, path) do
    with {:ok, json} <- gh_api(repo, :get, "/repos/#{slug}/contents/#{path}"),
         {:ok, decoded} <- JSON.decode(json),
         {:ok, content} <- extract_content(decoded) do
      {:ok, content}
    end
  end

  @impl true
  def write_file(%DiscussionRepo{gh_slug: slug} = repo, path, content, message) do
    blob_sha =
      case get_blob_sha(repo, path) do
        {:ok, sha} -> sha
        {:error, _} -> nil
      end

    payload =
      %{"message" => message, "content" => Base.encode64(content)}
      |> maybe_put_sha(blob_sha)

    with {:ok, _json} <-
           gh_api(repo, :put, "/repos/#{slug}/contents/#{path}", payload) do
      {:ok, repo}
    end
  end

  @impl true
  def list_files(%DiscussionRepo{gh_slug: slug} = repo, path) do
    case gh_api(repo, :get, "/repos/#{slug}/contents/#{path}") do
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

  # ----------------------------------------------------------------
  # Private helpers
  # ----------------------------------------------------------------

  defp get_blob_sha(%DiscussionRepo{gh_slug: slug} = repo, path) do
    with {:ok, json} <- gh_api(repo, :get, "/repos/#{slug}/contents/#{path}"),
         {:ok, decoded} <- JSON.decode(json) do
      {:ok, decoded["sha"]}
    end
  end

  defp gh_api(repo, method, endpoint, body \\ nil) do
    runner = get_in(repo.config, [:runner]) || SystemCmdRunner
    auth  = auth_args(repo.token)
    args  = build_args(method, endpoint)
    opts  = build_opts(body)

    case runner.cmd("gh", auth ++ ["api"] ++ args, opts) do
      {stdout, 0} -> {:ok, stdout}
      {stdout, status} -> {:error, {:api_failed, status, stdout}}
    end
  end

  defp build_args(:get, endpoint), do: [endpoint]
  defp build_args(:put, endpoint), do: ["--method", "PUT", "--input", "-", endpoint]

  defp auth_args(nil), do: []
  defp auth_args(token), do: ["-H", "Authorization: Bearer #{token}"]

  defp build_opts(nil), do: [stderr_to_stdout: true]

  defp build_opts(body) do
    {:ok, json} = Jason.encode(body)
    [stderr_to_stdout: true, input: json]
  end

  defp extract_content(%{"encoding" => "base64", "content" => content}) do
    # GitHub adds newlines every 60 chars; strip before decoding
    cleaned = String.replace(content, "\n", "")
    {:ok, Base.decode64!(cleaned)}
  end

  defp extract_content(%{"content" => content}), do: {:ok, content}
  defp extract_content(_), do: {:error, :no_content_field}

  defp maybe_put_sha(payload, nil), do: payload
  defp maybe_put_sha(payload, sha), do: Map.put(payload, "sha", sha)
end

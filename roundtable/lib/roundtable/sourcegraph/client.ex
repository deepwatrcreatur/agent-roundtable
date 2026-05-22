defmodule Roundtable.Sourcegraph.Client do
  @moduledoc """
  Thin Sourcegraph adapter that retrieves bounded context and normalizes it into
  local evidence records.
  """

  alias Roundtable.Sourcegraph.{EvidenceRecord, SubtreeBriefInput}

  @graphql_path "/.api/graphql"
  @default_result_limit 10

  @type options :: keyword()
  @type request_fun :: (keyword() -> {:ok, map()} | {:error, term()})

  @spec semantic_search(String.t(), String.t(), String.t(), String.t(), options()) ::
          {:ok, [map()]} | {:error, term()}
  def semantic_search(repo, revision, path_scope, query, opts \\ []) do
    search(repo, revision, path_scope, query, :semantic, opts)
  end

  @spec keyword_search(String.t(), String.t(), String.t(), String.t(), options()) ::
          {:ok, [map()]} | {:error, term()}
  def keyword_search(repo, revision, path_scope, query, opts \\ []) do
    search(repo, revision, path_scope, query, :keyword, opts)
  end

  @spec history_search(String.t(), String.t(), String.t(), String.t(), :commit | :diff, options()) ::
          {:ok, [map()]} | {:error, term()}
  def history_search(repo, revision, path_scope, query, mode \\ :commit, opts \\ [])
      when mode in [:commit, :diff] do
    search(repo, revision, path_scope, query, mode, opts)
  end

  @spec list_files(String.t(), String.t(), String.t(), options()) :: {:ok, [map()]} | {:error, term()}
  def list_files(repo, revision, path_scope, opts \\ []) do
    variables = %{"repo" => repo, "revision" => revision, "path" => path_scope}

    with {:ok, data} <- graphql(list_files_query(), variables, opts) do
      entries =
        get_in(data, ["repository", "commit", "tree", "entries"]) || []

      {:ok,
       Enum.map(entries, fn entry ->
         %{
           name: entry["name"],
           path: entry["path"],
           is_directory: entry["isDirectory"] || false
         }
       end)}
    end
  end

  @spec read_file(String.t(), String.t(), String.t(), options()) ::
          {:ok, %{path: String.t(), content: String.t(), byte_size: non_neg_integer()}} | {:error, term()}
  def read_file(repo, revision, path, opts \\ []) do
    variables = %{"repo" => repo, "revision" => revision, "path" => path}

    with {:ok, data} <- graphql(read_file_query(), variables, opts) do
      case get_in(data, ["repository", "commit", "blob"]) do
        nil ->
          {:error, :file_not_found}

        blob ->
          {:ok,
           %{
             path: path,
             content: blob["content"] || "",
             byte_size: blob["byteSize"] || 0
           }}
      end
    end
  end

  @spec bounded_context(String.t(), String.t(), String.t(), String.t(), options()) ::
          {:ok, %{evidence: EvidenceRecord.t(), brief_input: map()}} | {:error, term()}
  def bounded_context(repo, revision, path_scope, query, opts \\ []) do
    created_at = Keyword.get(opts, :created_at, DateTime.utc_now() |> DateTime.to_iso8601())
    created_by_attempt = Keyword.get(opts, :created_by_attempt)
    read_limit = Keyword.get(opts, :read_limit, 2)

    with {:ok, semantic_results} <- semantic_search(repo, revision, path_scope, query, opts),
         {:ok, keyword_results} <- keyword_search(repo, revision, path_scope, query, opts),
         {:ok, history_results} <- history_search(repo, revision, path_scope, query, :commit, opts),
         {:ok, file_entries} <- list_files(repo, revision, path_scope, opts),
         {:ok, file_bodies} <- read_bounded_files(repo, revision, file_entries, read_limit, opts) do
      files_read =
        file_bodies
        |> Enum.map(& &1.path)
        |> Enum.uniq()

      commits_examined =
        history_results
        |> Enum.filter(&(&1.type == "commit"))
        |> Enum.map(& &1.oid)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()

      diffs_examined =
        history_results
        |> Enum.filter(&(&1.type == "diff"))
        |> Enum.map(& &1.label)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()

      evidence =
        EvidenceRecord.new(%{
          id: evidence_id(repo, revision, path_scope, query),
          provider: "sourcegraph",
          source_type: "sourcegraph_search_context",
          retrieval_mode: "bounded_context",
          repo: repo,
          revision: revision,
          path_scope: path_scope,
          sourcegraph_query: query,
          sourcegraph_conversation_url: Keyword.get(opts, :conversation_url),
          files_read: files_read,
          commits_examined: commits_examined,
          diffs_examined: diffs_examined,
          created_at: created_at,
          created_by_attempt: created_by_attempt,
          summary: summarize_context(path_scope, semantic_results, keyword_results, file_bodies, history_results),
          search_results: semantic_results ++ keyword_results,
          history_results: history_results,
          file_bodies: file_bodies
        })

      {:ok, %{evidence: evidence, brief_input: SubtreeBriefInput.from_evidence(evidence)}}
    end
  end

  defp read_bounded_files(_repo, _revision, [], _read_limit, _opts), do: {:ok, []}

  defp read_bounded_files(repo, revision, file_entries, read_limit, opts) do
    files =
      file_entries
      |> Enum.reject(& &1.is_directory)
      |> Enum.take(read_limit)

    case Enum.reduce_while(files, [], fn file, acc ->
           case read_file(repo, revision, file.path, opts) do
             {:ok, body} -> {:cont, [body | acc]}
             {:error, _reason} = error -> {:halt, error}
           end
         end) do
      {:error, _reason} = error -> error
      bodies -> {:ok, Enum.reverse(bodies)}
    end
  end

  defp search(repo, revision, path_scope, query, mode, opts) do
    limit = Keyword.get(opts, :result_limit, @default_result_limit)
    variables = %{"query" => search_query(repo, revision, path_scope, query, mode, limit)}

    with {:ok, data} <- graphql(search_query_document(), variables, opts) do
      results =
        get_in(data, ["search", "results", "results"])
        |> List.wrap()
        |> Enum.map(&normalize_search_result/1)

      {:ok, results}
    end
  end

  defp graphql(query, variables, opts) do
    request_fun = Keyword.get(opts, :request_fun, &default_request/1)

    case request_fun.(request_options(query, variables, opts)) do
      {:ok, %{"errors" => errors}} when is_list(errors) and errors != [] ->
        {:error, {:sourcegraph_errors, errors}}

      {:ok, %{"data" => data}} ->
        {:ok, data}

      {:ok, other} ->
        {:error, {:unexpected_sourcegraph_response, other}}

      {:error, _reason} = error ->
        error
    end
  end

  defp request_options(query, variables, opts) do
    base_url = Keyword.get(opts, :base_url, "https://sourcegraph.com")
    token = Keyword.get(opts, :access_token, System.get_env("SOURCEGRAPH_ACCESS_TOKEN"))

    headers =
      [{"content-type", "application/json"}]
      |> maybe_add_auth_header(token)

    [
      method: :post,
      url: String.trim_trailing(base_url, "/") <> @graphql_path,
      headers: headers,
      json: %{query: query, variables: variables}
    ]
  end

  defp maybe_add_auth_header(headers, nil), do: headers
  defp maybe_add_auth_header(headers, ""), do: headers
  defp maybe_add_auth_header(headers, token), do: [{"authorization", "token " <> token} | headers]

  defp default_request(opts) do
    case Req.request(opts) do
      {:ok, response} -> {:ok, response.body}
      {:error, _reason} = error -> error
    end
  end

  defp search_query(repo, revision, path_scope, query, mode, limit) do
    mode_prefix =
      case mode do
        :semantic -> "type:file patterntype:literal "
        :keyword -> "type:file patterntype:regexp "
        :commit -> "type:commit "
        :diff -> "type:diff "
      end

    [
      mode_prefix,
      "repo:^",
      repo,
      "$ rev:",
      revision,
      " file:^",
      path_scope,
      " count:",
      Integer.to_string(limit),
      " ",
      query
    ]
    |> IO.iodata_to_binary()
  end

  defp normalize_search_result(%{"__typename" => "FileMatch"} = result) do
    %{
      type: "file",
      path: get_in(result, ["file", "path"]),
      repository: get_in(result, ["repository", "name"]) || get_in(result, ["file", "repository", "name"]),
      url: result["url"],
      preview:
        result["lineMatches"]
        |> List.wrap()
        |> Enum.map(& &1["preview"])
        |> Enum.reject(&is_nil/1)
        |> Enum.join("\n")
    }
  end

  defp normalize_search_result(%{"__typename" => "CommitSearchResult"} = result) do
    %{
      type: "commit",
      oid: get_in(result, ["commit", "oid"]) || result["oid"],
      label: get_in(result, ["commit", "subject"]) || result["label"],
      url: result["url"]
    }
  end

  defp normalize_search_result(%{"__typename" => "CommitDiffSearchResult"} = result) do
    %{
      type: "diff",
      oid: result["oid"],
      label: result["label"],
      url: result["url"]
    }
  end

  defp normalize_search_result(result) do
    %{
      type: String.downcase(to_string(result["__typename"] || "unknown")),
      label: result["label"] || result["url"] || inspect(result)
    }
  end

  defp evidence_id(repo, revision, path_scope, query) do
    encoded =
      [repo, revision, path_scope, query]
      |> Enum.join("|")
      |> :erlang.md5()
      |> Base.encode16(case: :lower)

    "sgctx_" <> encoded
  end

  defp summarize_context(path_scope, semantic_results, keyword_results, file_bodies, history_results) do
    file_count = length(file_bodies)
    search_count = length(semantic_results) + length(keyword_results)
    history_count = length(history_results)

    "Bounded Sourcegraph context for #{path_scope}: #{search_count} search hits, #{file_count} files read, #{history_count} history results."
  end

  defp search_query_document do
    """
    query Search($query: String!) {
      search(query: $query, version: V3) {
        results {
          results {
            __typename
            ... on FileMatch {
              url
              repository { name }
              file { path repository { name } }
              lineMatches { preview }
            }
            ... on CommitSearchResult {
              url
              label
              commit { oid subject }
            }
            ... on CommitDiffSearchResult {
              url
              label
              oid
            }
          }
        }
      }
    }
    """
  end

  defp list_files_query do
    """
    query ListFiles($repo: String!, $revision: String!, $path: String!) {
      repository(name: $repo) {
        commit(rev: $revision) {
          tree(path: $path) {
            entries {
              name
              path
              isDirectory
            }
          }
        }
      }
    }
    """
  end

  defp read_file_query do
    """
    query ReadFile($repo: String!, $revision: String!, $path: String!) {
      repository(name: $repo) {
        commit(rev: $revision) {
          blob(path: $path) {
            byteSize
            content
          }
        }
      }
    }
    """
  end
end

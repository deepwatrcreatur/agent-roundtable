defmodule Roundtable.Sourcegraph.ClientTest do
  use ExUnit.Case, async: true

  alias Roundtable.Sourcegraph.{Client, EvidenceRecord, SubtreeBriefInput}

  test "retrieves bounded context and normalizes it into an evidence record" do
    parent = self()

    request_fun = fn opts ->
      send(parent, {:request, opts})
      query = opts[:json][:query]
      variables = opts[:json][:variables]

      cond do
        String.contains?(query, "query Search") and String.contains?(variables["query"], "type:file patterntype:literal") ->
          {:ok,
           %{
             "data" => %{
               "search" => %{
                 "results" => %{
                   "results" => [
                     %{
                       "__typename" => "FileMatch",
                       "url" => "/github.com/acme/auth-service/-/blob/src/auth/refresh.ts",
                       "repository" => %{"name" => "acme/auth-service"},
                       "file" => %{"path" => "src/auth/refresh.ts", "repository" => %{"name" => "acme/auth-service"}},
                       "lineMatches" => [%{"preview" => "refresh flow"}]
                     }
                   ]
                 }
               }
             }
           }}

        String.contains?(query, "query Search") and String.contains?(variables["query"], "type:file patterntype:regexp") ->
          {:ok,
           %{
             "data" => %{
               "search" => %{
                 "results" => %{
                   "results" => [
                     %{
                       "__typename" => "FileMatch",
                       "url" => "/github.com/acme/auth-service/-/blob/src/auth/token_store.ts",
                       "repository" => %{"name" => "acme/auth-service"},
                       "file" => %{"path" => "src/auth/token_store.ts", "repository" => %{"name" => "acme/auth-service"}},
                       "lineMatches" => [%{"preview" => "token store"}]
                     }
                   ]
                 }
               }
             }
           }}

        String.contains?(query, "query Search") and String.contains?(variables["query"], "type:commit") ->
          {:ok,
           %{
             "data" => %{
               "search" => %{
                 "results" => %{
                   "results" => [
                     %{
                       "__typename" => "CommitSearchResult",
                       "url" => "/github.com/acme/auth-service/-/commit/deadbeef",
                       "label" => "tighten refresh rotation",
                       "commit" => %{"oid" => "deadbeef", "subject" => "tighten refresh rotation"}
                     }
                   ]
                 }
               }
             }
           }}

        String.contains?(query, "query ListFiles") ->
          assert variables == %{
                   "path" => "src/auth",
                   "repo" => "acme/auth-service",
                   "revision" => "refs/heads/main"
                 }

          {:ok,
           %{
             "data" => %{
               "repository" => %{
                 "commit" => %{
                   "tree" => %{
                     "entries" => [
                       %{"name" => "refresh.ts", "path" => "src/auth/refresh.ts", "isDirectory" => false},
                       %{"name" => "token_store.ts", "path" => "src/auth/token_store.ts", "isDirectory" => false}
                     ]
                   }
                 }
               }
             }
           }}

        String.contains?(query, "query ReadFile") and variables["path"] == "src/auth/refresh.ts" ->
          {:ok,
           %{
             "data" => %{
               "repository" => %{
                 "commit" => %{
                   "blob" => %{"byteSize" => 27, "content" => "def refresh(), do: :ok\n"}
                 }
               }
             }
           }}

        String.contains?(query, "query ReadFile") and variables["path"] == "src/auth/token_store.ts" ->
          {:ok,
           %{
             "data" => %{
               "repository" => %{
                 "commit" => %{
                   "blob" => %{"byteSize" => 32, "content" => "def token_store(), do: :ok\n"}
                 }
               }
             }
           }}

        true ->
          flunk("unexpected request: #{inspect(opts)}")
      end
    end

    assert {:ok, %{evidence: %EvidenceRecord{} = evidence, brief_input: brief_input}} =
             Client.bounded_context(
               "acme/auth-service",
               "refs/heads/main",
               "src/auth",
               "token refresh",
               request_fun: request_fun,
               created_by_attempt: "att_42",
               created_at: "2026-05-22T18:00:00Z"
             )

    assert evidence.provider == "sourcegraph"
    assert evidence.repo == "acme/auth-service"
    assert evidence.revision == "refs/heads/main"
    assert evidence.path_scope == "src/auth"
    assert evidence.sourcegraph_query == "token refresh"
    assert evidence.created_by_attempt == "att_42"
    assert evidence.files_read == ["src/auth/refresh.ts", "src/auth/token_store.ts"]
    assert evidence.commits_examined == ["deadbeef"]
    assert evidence.summary =~ "Bounded Sourcegraph context for src/auth"
    assert length(evidence.search_results) == 2
    assert length(evidence.history_results) == 1
    assert brief_input.repo == "acme/auth-service"
    assert get_in(brief_input, [:source_evidence, :query]) == "token refresh"

    assert_received {:request, req}
    assert req[:url] =~ "/.api/graphql"
  end

  test "supports standalone file listing and file reads" do
    request_fun = fn opts ->
      query = opts[:json][:query]
      variables = opts[:json][:variables]

      cond do
        String.contains?(query, "query ListFiles") ->
          {:ok,
           %{
             "data" => %{
               "repository" => %{
                 "commit" => %{
                   "tree" => %{
                     "entries" => [
                       %{"name" => "auth", "path" => "src/auth", "isDirectory" => true},
                       %{"name" => "refresh.ts", "path" => "src/auth/refresh.ts", "isDirectory" => false}
                     ]
                   }
                 }
               }
             }
           }}

        String.contains?(query, "query ReadFile") ->
          assert variables["path"] == "src/auth/refresh.ts"

          {:ok,
           %{
             "data" => %{
               "repository" => %{
                 "commit" => %{
                   "blob" => %{"byteSize" => 11, "content" => "hello world"}
                 }
               }
             }
           }}

        true ->
          flunk("unexpected request: #{inspect(opts)}")
      end
    end

    assert {:ok, files} =
             Client.list_files("acme/auth-service", "refs/heads/main", "src/auth",
               request_fun: request_fun
             )

    assert files == [
             %{name: "auth", path: "src/auth", is_directory: true},
             %{name: "refresh.ts", path: "src/auth/refresh.ts", is_directory: false}
           ]

    assert {:ok, file_body} =
             Client.read_file("acme/auth-service", "refs/heads/main", "src/auth/refresh.ts",
               request_fun: request_fun
             )

    assert file_body.content == "hello world"
  end

  test "builds subtree brief input directly from evidence" do
    evidence =
      EvidenceRecord.new(%{
        id: "sgctx_example",
        provider: "sourcegraph",
        source_type: "sourcegraph_search_context",
        retrieval_mode: "bounded_context",
        repo: "acme/auth-service",
        revision: "refs/heads/main",
        path_scope: "src/auth",
        sourcegraph_query: "token refresh",
        sourcegraph_conversation_url: nil,
        files_read: ["src/auth/refresh.ts"],
        commits_examined: ["deadbeef"],
        diffs_examined: [],
        created_at: "2026-05-22T18:00:00Z",
        created_by_attempt: "att_42",
        summary: "Refresh flow context",
        search_results: [],
        history_results: [],
        file_bodies: []
      })

    brief_input = SubtreeBriefInput.from_evidence(evidence)

    assert brief_input.path_scope == "src/auth"
    assert get_in(brief_input, [:source_evidence, :files_read]) == ["src/auth/refresh.ts"]
    assert get_in(brief_input, [:source_evidence, :summary]) == "Refresh flow context"
    assert brief_input.evidence_records == [evidence]
  end
end

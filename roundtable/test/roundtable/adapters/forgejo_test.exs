defmodule Roundtable.Adapters.ForgejoTest do
  use ExUnit.Case, async: true

  alias Roundtable.Adapters.Forgejo
  alias Roundtable.DiscussionRepo
  alias Roundtable.TestSupport.FakeRunner

  defp repo(opts \\ []) do
    Process.put(:test_pid, self())

    config =
      %{
        runner: FakeRunner,
        base_url: Keyword.get(opts, :base_url, "https://forgejo.example.org")
      }
      |> maybe_put(:auth_scheme, Keyword.get(opts, :auth_scheme))

    DiscussionRepo.new(Keyword.get(opts, :slug, "owner/test-repo"),
      backend: Forgejo,
      config: config,
      token: Keyword.get(opts, :token),
      base_path: Keyword.get(opts, :base_path)
    )
  end

  defp set_result(result), do: Process.put(:runner_result, result)
  defp set_result_seq(results), do: Process.put(:runner_result_seq, results)

  defp response(body, status), do: {body <> "\n__ROUNDTABLE_HTTP_STATUS__:#{status}", 0}

  defp json_file(content_b64, sha \\ "abc123") do
    Jason.encode!(%{
      "sha" => sha,
      "content" => content_b64,
      "encoding" => "base64"
    })
  end

  defp json_dir(names) do
    names
    |> Enum.map(&%{"name" => &1, "type" => "file"})
    |> Jason.encode!()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  describe "read_file/2" do
    test "issues GET to the Forgejo contents API and decodes base64" do
      set_result(response(json_file(Base.encode64("hello world")), 200))

      assert {:ok, "hello world"} = Forgejo.read_file(repo(), "BRIEF.md")

      assert_received {:cmd, "curl", args, [stderr_to_stdout: true]}
      assert "https://forgejo.example.org/api/v1/repos/owner/test-repo/contents/BRIEF.md" in args
      assert ["-H", "Accept: application/json"] == Enum.slice(args, 5, 2)
    end

    test "uses token auth by default when token is set" do
      set_result(response(json_file(Base.encode64("hello")), 200))

      Forgejo.read_file(repo(token: "sekret"), "BRIEF.md")

      assert_received {:cmd, "curl", args, _}
      assert ["-H", "Authorization: token sekret"] == Enum.slice(args, 7, 2)
    end

    test "supports bearer auth when configured" do
      set_result(response(json_file(Base.encode64("hello")), 200))

      Forgejo.read_file(repo(token: "sekret", auth_scheme: :bearer), "BRIEF.md")

      assert_received {:cmd, "curl", args, _}
      assert "Authorization: Bearer sekret" in args
    end

    test "returns api_failed from the reported HTTP status" do
      set_result(response(~s({"message":"Not Found"}), 404))

      assert {:error, {:api_failed, 404, _}} = Forgejo.read_file(repo(), "missing.md")
    end

    test "returns missing_option when no Forgejo host is configured" do
      bare_repo =
        DiscussionRepo.new("owner/test-repo",
          backend: Forgejo,
          config: %{runner: FakeRunner}
        )

      assert {:error, {:missing_option, :base_url}} = Forgejo.read_file(bare_repo, "BRIEF.md")
    end
  end

  describe "write_file/4" do
    test "updates an existing file with PUT and sha" do
      set_result_seq([
        response(json_file(Base.encode64("old"), "deadbeef"), 200),
        response(Jason.encode!(%{"commit" => %{"id" => "newsha"}}), 200)
      ])

      assert {:ok, %DiscussionRepo{}} =
               Forgejo.write_file(repo(), "rounds/round-01.md", "new content", "close round 1")

      assert_received {:cmd, "curl", first_args, _}

      assert "https://forgejo.example.org/api/v1/repos/owner/test-repo/contents/rounds/round-01.md" in first_args

      assert_received {:cmd, "curl", second_args, [stderr_to_stdout: true, input: json_input]}
      assert "--request" in second_args
      assert "PUT" in second_args

      {:ok, body} = Jason.decode(json_input)
      assert body["message"] == "close round 1"
      assert body["content"] == Base.encode64("new content")
      assert body["sha"] == "deadbeef"
    end

    test "creates a new file with POST when the blob lookup is 404" do
      set_result_seq([
        response(~s({"message":"Not Found"}), 404),
        response(Jason.encode!(%{"commit" => %{"id" => "newsha"}}), 201)
      ])

      assert {:ok, %DiscussionRepo{}} =
               Forgejo.write_file(repo(), "new.md", "brand new", "add new.md")

      assert_received {:cmd, "curl", _first_args, _}
      assert_received {:cmd, "curl", second_args, [stderr_to_stdout: true, input: json_input]}
      assert "POST" in second_args

      {:ok, body} = Jason.decode(json_input)
      assert body["message"] == "add new.md"
      assert body["content"] == Base.encode64("brand new")
      refute Map.has_key?(body, "sha")
    end

    test "prefixes the configured base path" do
      set_result_seq([
        response(~s({"message":"Not Found"}), 404),
        response(Jason.encode!(%{"commit" => %{"id" => "newsha"}}), 201)
      ])

      Forgejo.write_file(repo(base_path: "docs/design"), "BRIEF.md", "text", "msg")

      assert_received {:cmd, "curl", _first_args, _}

      assert_received {:cmd, "curl", second_args, _}

      assert "https://forgejo.example.org/api/v1/repos/owner/test-repo/contents/docs/design/BRIEF.md" in second_args
    end
  end

  describe "list_files/2" do
    test "returns entry names from a directory listing" do
      set_result(response(json_dir(["round-01.md", "round-02.md"]), 200))

      assert {:ok, names} = Forgejo.list_files(repo(), "rounds")
      assert Enum.sort(names) == ["round-01.md", "round-02.md"]
    end

    test "returns empty list on 404" do
      set_result(response(~s({"message":"Not Found"}), 404))
      assert {:ok, []} = Forgejo.list_files(repo(), "rounds")
    end

    test "propagates non-404 API failures" do
      set_result(response(~s({"message":"boom"}), 500))
      assert {:error, {:api_failed, 500, _}} = Forgejo.list_files(repo(), "rounds")
    end
  end

  describe "discussion_repo?/1" do
    test "returns true when roundtable.toml exists" do
      set_result(response(json_file(Base.encode64("schema_version = 1")), 200))
      assert Forgejo.discussion_repo?(repo())
    end

    test "returns false when roundtable.toml does not exist" do
      set_result(response(~s({"message":"Not Found"}), 404))
      refute Forgejo.discussion_repo?(repo())
    end
  end
end

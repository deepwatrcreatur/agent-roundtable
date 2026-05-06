defmodule Roundtable.CLITest do
  use ExUnit.Case, async: true

  alias Roundtable.CLI

  defmodule FakeGh do
    def list_issues(_opts, _config) do
      {:ok,
       [
         %{
           "number" => 12,
           "title" => "Q1",
           "state" => "OPEN",
           "labels" => [%{"name" => "roundtable"}, %{"name" => "satisfied"}],
           "url" => "https://example.test/issues/12",
           "comments" => [
             %{
               "id" => "c1",
                "body" =>
                 "## Codex\n\nThe repo uses Nix [observed: cat flake.nix]. Therefore use a flake [inferred]."
             },
             %{
               "id" => "c2",
               "body" =>
                 "## Gemini\n\n[needs more evidence: reproduce this locally]\nPremise collision: the BRIEF assumes a server, but the observed repo is a CLI tool."
             }
           ]
         }
       ]}
    end
  end

  setup do
    brief_path = Path.join(System.tmp_dir!(), "test_brief_cli_#{System.unique_integer()}.md")
    File.write!(brief_path, "# Brief\n\n### Q1 — Architecture\n\nWhat should we build?\n")
    on_exit(fn -> File.rm(brief_path) end)
    %{brief_path: brief_path}
  end

  describe "inject_question/3" do
    # inject_question requires a live gh CLI and GitHub token.
    # Tested in integration suite; unit test verifies arg validation only.
    test "returns error when repo is nil (no default repo configured)" do
      # nil repo with no gh env configured must return {:error, _} without raising.
      result = CLI.inject_question(nil, "New question", [])
      assert match?({:error, _}, result)
    end
  end

  describe "module API exports" do
    # get_discussion_state requires gh CLI; tested via satisfaction label inference
    # which is exposed indirectly. We verify the module loads and exports the right API.
    test "module exports start_discussion/2" do
      assert function_exported?(CLI, :start_discussion, 2)
    end

    test "module exports get_discussion_state/1" do
      assert function_exported?(CLI, :get_discussion_state, 1)
    end

    test "module exports inject_question/3" do
      assert function_exported?(CLI, :inject_question, 3)
    end
  end

  describe "start_discussion/2 roster validation" do
    test "fails fast when a requested agent is unsupported", %{brief_path: brief_path} do
      assert {:error, {:unsupported_agents, [:copilot]}} =
               CLI.start_discussion(brief_path, agents: [:codex, :copilot])
    end
  end

  describe "get_discussion_state/1" do
    setup do
      Application.put_env(:roundtable, :gh_module, FakeGh)

      on_exit(fn ->
        Application.delete_env(:roundtable, :gh_module)
      end)

      :ok
    end

    test "includes parsed comments, provenance-tagged claims, and adversarial turn flags" do
      assert {:ok, %{12 => question}} = CLI.get_discussion_state("owner/repo")

      assert question.comment_count == 2
      assert [%{agent: :codex, body: body, claims: claims}, %{agent: :gemini}] = question.comments
      assert body =~ "The repo uses Nix"

      assert [
               %{claim: "The repo uses Nix", tag: :observed, detail: "cat flake.nix", agent: :codex},
               %{claim: "Therefore use a flake", tag: :inferred, detail: nil, agent: :codex}
             ] = claims

      assert question.claims == claims
      assert question.has_adversarial

      assert [
               %{agent: :codex, is_skeptic: false, has_collision: false, satisfaction: :unknown},
               %{
                 agent: :gemini,
                 is_skeptic: true,
                 has_collision: true,
                 satisfaction: :needs_more_evidence
               }
             ] = Enum.map(question.turns, &Map.take(&1, [:agent, :is_skeptic, :has_collision, :satisfaction]))
    end
  end
end

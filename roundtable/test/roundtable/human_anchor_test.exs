defmodule Roundtable.HumanAnchorTest do
  use ExUnit.Case, async: true

  alias Roundtable.HumanAnchor

  defmodule FakeDolt do
    def query(sql, _opts) do
      send(self(), {:query, sql})

      if String.contains?(sql, "SELECT issue_number") do
        {:ok,
         [
           %{
             "issue_number" => "45",
             "claim_key" => "finding",
             "maintainer_id" => "lead-maintainer",
             "verdict" => "vouched",
             "ai_state" => "satisfied",
             "note" => "",
             "created_at" => "2026-05-09T13:00:00Z"
           }
         ]}
      else
        {:ok, []}
      end
    end

    def write_files(params, _opts) do
      send(self(), {:commit, params})
      {:ok, %{commit_id: "abc123", branch: "main"}}
    end
  end

  test "persists a finding vouch and requests a signed dolt commit" do
    assert :ok =
             HumanAnchor.verify_finding(
               "/tmp/repo",
               45,
               "lead-maintainer",
               :satisfied,
               dolt: FakeDolt,
               sign?: true,
               signing_key: "ABCDEF"
             )

    assert_received {:query, schema_sql}
    assert schema_sql =~ "CREATE TABLE IF NOT EXISTS trust_vouches"

    assert_received {:query, insert_sql}
    assert insert_sql =~ "REPLACE INTO trust_vouches"
    assert insert_sql =~ "'45'"
    assert insert_sql =~ "'finding'"
    assert insert_sql =~ "'lead-maintainer'"

    assert_received {:commit, commit}
    assert commit.sign?
    assert commit.signing_key == "ABCDEF"
    assert commit.message =~ "anchor issue 45"
  end

  test "builds anchor statuses and human/ai delta labels" do
    questions = %{
      45 => %{satisfaction: :satisfied},
      46 => %{satisfaction: :needs_more_evidence}
    }

    statuses =
      HumanAnchor.build_statuses(questions, [
        %{
          issue_number: "45",
          claim_key: "finding",
          maintainer_id: "lead-maintainer",
          verdict: "vouched",
          ai_state: "satisfied",
          note: "",
          created_at: ""
        }
      ])

    assert statuses[45].anchored?
    assert statuses[45].status_label == "Project-Binding"
    assert statuses[45].delta_label == "Aligned"
    refute statuses[46].anchored?
    assert statuses[46].delta_label == "Awaiting review"
  end

  test "lists vouches from dolt rows" do
    assert {:ok, [%{maintainer_id: "lead-maintainer", issue_number: "45"}]} =
             HumanAnchor.list_vouches("/tmp/repo", dolt: FakeDolt)
  end
end

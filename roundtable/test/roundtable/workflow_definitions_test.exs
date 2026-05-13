defmodule Roundtable.WorkflowDefinitionsTest do
  use ExUnit.Case, async: true

  alias Roundtable.WorkflowDefinitions

  defmodule FakeDolt do
    def query(sql, _opts) do
      send(self(), {:query, sql})

      cond do
        String.contains?(sql, "WHERE id = 'wf-codex'") ->
          {:ok,
           [
             %{
               "id" => "wf-codex",
               "title" => "Codex coding workflow",
               "description" => "Reusable coding policy",
               "task_types_json" => ~s(["code_change","review"]),
               "runtime_requirements_json" =>
                 ~s({"profiles":["codex-gpt54"],"labels":["linux"],"transports":["unix_socket"]}),
               "retry_policy_json" => ~s({"max_attempts":4,"retry_on":["tool_error"]}),
               "timeout_policy_json" => ~s({"hard_timeout_s":1800}),
               "hitl_policy_json" => ~s({"gate":"approve"}),
               "resume_policy_json" => ~s({"on_approve":"resume"}),
               "created_at" => "2026-05-12T09:30:00Z",
               "updated_at" => "2026-05-12T09:30:00Z"
             }
           ]}

        String.contains?(sql, "SELECT id, title, description, task_types_json") ->
          {:ok,
           [
             %{
               "id" => "wf-codex",
               "title" => "Codex coding workflow",
               "description" => "Reusable coding policy",
               "task_types_json" => ~s(["code_change","review"]),
               "runtime_requirements_json" => ~s({"profiles":["codex-gpt54"]}),
               "retry_policy_json" => ~s({"max_attempts":4}),
               "timeout_policy_json" => ~s({"hard_timeout_s":1800}),
               "hitl_policy_json" => ~s({"gate":"approve"}),
               "resume_policy_json" => ~s({"on_approve":"resume"}),
               "created_at" => "2026-05-12T09:30:00Z",
               "updated_at" => "2026-05-12T09:30:00Z"
             }
           ]}

        true ->
          {:ok, []}
      end
    end

    def write_files(params, _opts) do
      send(self(), {:commit, params})
      {:ok, %{commit_id: "abc123", branch: "main"}}
    end
  end

  test "schema SQL defines workflow_definitions table" do
    assert WorkflowDefinitions.schema_sql() =~ "CREATE TABLE IF NOT EXISTS workflow_definitions"
  end

  test "stores and lists reusable workflow definitions" do
    assert :ok =
             WorkflowDefinitions.put_definition(
               "/tmp/repo",
               %{
                 id: "wf-codex",
                 title: "Codex coding workflow",
                 description: "Reusable coding policy",
                 task_types: ["code_change", "review"],
                 runtime_requirements: %{
                   profiles: ["codex-gpt54"],
                   labels: ["linux"],
                   transports: ["unix_socket"]
                 },
                 retry_policy: %{max_attempts: 4, retry_on: ["tool_error"]},
                 timeout_policy: %{hard_timeout_s: 1800},
                 hitl_policy: %{gate: "approve"},
                 resume_policy: %{on_approve: "resume"}
               },
               dolt: FakeDolt
             )

    assert_received {:query, schema_sql}
    assert schema_sql =~ "CREATE TABLE IF NOT EXISTS workflow_definitions"

    assert_received {:query, insert_sql}
    assert insert_sql =~ "REPLACE INTO workflow_definitions"
    assert insert_sql =~ "'wf-codex'"
    assert insert_sql =~ "\"max_attempts\":4"

    assert_received {:commit, commit}
    assert commit.message =~ "define workflow wf-codex"

    assert {:ok, [definition]} = WorkflowDefinitions.list_definitions("/tmp/repo", dolt: FakeDolt)
    assert definition.id == "wf-codex"
    assert definition.task_types == ["code_change", "review"]
  end

  test "resolves workflow defaults into work items with inline overrides" do
    work_item = %{
      id: "wk-1",
      workflow_ref: "wf-codex",
      task_type: "code_change",
      retry_policy: %{"max_attempts" => 2},
      timeout_policy: nil,
      hitl_policy: %{"gate" => "review"},
      runtime_requirements: %{"runtimes" => ["rtk-1"]}
    }

    assert {:ok, resolved} =
             WorkflowDefinitions.resolve_work_item("/tmp/repo", work_item, dolt: FakeDolt)

    assert resolved.retry_policy == %{"max_attempts" => 2, "retry_on" => ["tool_error"]}
    assert resolved.timeout_policy == %{"hard_timeout_s" => 1800}
    assert resolved.hitl_policy == %{"gate" => "review"}

    assert resolved.runtime_requirements == %{
             "profiles" => ["codex-gpt54"],
             "labels" => ["linux"],
             "transports" => ["unix_socket"],
             "runtimes" => ["rtk-1"]
           }

    assert WorkflowDefinitions.runtime_allowed?(resolved,
             runtime_id: "rtk-1",
             runtime_profile_ids: ["codex-gpt54"],
             runtime_labels: ["linux", "nixos"],
             transport: "unix_socket"
           )

    refute WorkflowDefinitions.runtime_allowed?(resolved,
             runtime_id: "rtk-2",
             runtime_profile_ids: ["gemini-cli"],
             runtime_labels: ["linux"],
             transport: "unix_socket"
           )
  end
end

defmodule RoundtableWeb.BoardLiveTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Roundtable.BoardKanbanReadModel
  alias RoundtableWeb.BoardLive

  defmodule FakeBoard do
    def list_work_items(_repo_path, _opts) do
      {:ok,
       [
        %{
          id: "wk-1",
          repo_ref: "deepwatrcreatur/agent-roundtable",
          branch_ref: "feat/board",
          source_ref: "round-1",
          title: "Queued card",
          task_type: "code_change",
          input_payload: %{},
          surface_route: "/forgejo-shell",
          evidence_links: [
            %{"label" => "Open board evidence", "href" => "/board", "kind" => "surface"}
          ],
          priority: 10,
          status: "queued",
          assignee_ref: "codex-queue",
          desired_outcome: %{"result" => "Queue remains visible"},
          updated_at: "2026-05-23T00:00:00Z"
        },
        %{
          id: "wk-2",
          repo_ref: "deepwatrcreatur/agent-roundtable",
          branch_ref: "feat/deploy",
          source_ref: "round-2",
          title: "Needs approval",
          task_type: "deploy",
          input_payload: %{},
          surface_route: "/forgejo-shell/reports",
          public_demo_id: "kubernetes",
          priority: 20,
          status: "awaiting_human_input",
          assignee_ref: "codex-review",
          desired_outcome: %{"result" => "Promote after approval"},
          updated_at: "2026-05-23T00:05:00Z"
        }
      ]}
    end

    def list_attempts(_repo_path, "wk-1", _opts), do: {:ok, []}

    def list_attempts(_repo_path, "wk-2", _opts) do
      {:ok,
       [
         %{
           id: "att-2",
           work_item_id: "wk-2",
           attempt_number: 1,
           runtime_id: "rtk-1",
           status: "running",
           lease_expires_at: "2026-05-23T01:07:00Z",
           summary: "Awaiting approval",
           exit_class: "needs_human_gate",
           started_at: "2026-05-23T00:50:00Z"
         }
       ]}
    end

    def list_human_gates(_repo_path, "wk-2", _opts) do
      {:ok,
       [
         %{
           id: "gate-1",
           work_item_id: "wk-2",
           attempt_id: "att-2",
           gate_type: "approve",
           state: "open",
           prompt: "Promote now?",
           created_at: "2026-05-23T00:56:00Z"
         }
       ]}
    end

    def list_human_gates(_repo_path, _work_item_id, _opts), do: {:ok, []}

    def list_runtime_heartbeats(_repo_path, _opts) do
      {:ok, [%{runtime_id: "rtk-1", host_label: "runner-1", status: "busy", last_seen_at: "2026-05-23T00:57:00Z"}]}
    end

    def list_attempt_events(_repo_path, "att-2", _opts) do
      {:ok,
       [
         %{id: "evt-1", attempt_id: "att-2", event_type: "needs_human_gate", summary: "Approval required", created_at: "2026-05-23T00:56:00Z"}
       ]}
    end
  end

  test "render shows board lanes, cards, and selected detail" do
    now = ~U[2026-05-23 01:00:00Z]

    {:ok, snapshot} = BoardKanbanReadModel.snapshot("/tmp/repo", board: FakeBoard, now: now)
    selected = Enum.find(snapshot.cards, &(&1.work_item_id == "wk-2"))

    html =
      %{
        __changed__: %{},
        repo_path: "/tmp/repo",
        params: %{},
        filters: snapshot.filters,
        counts: snapshot.counts,
        snapshot_generated_at: snapshot.generated_at,
        error: nil,
        cards: snapshot.cards,
        lanes: snapshot.lanes,
        selected_card: selected
      }
      |> BoardLive.render()
      |> rendered_to_string()

    assert html =~ "Vaglio Board"
    assert html =~ "Queued"
    assert html =~ "Gated"
    assert html =~ "Queued card"
    assert html =~ "Needs approval"
    assert html =~ "Approval required"
    assert html =~ "Selected card"
    assert html =~ "Owner codex-review"
    assert html =~ "Source round-2"
    assert html =~ "Next signal"
    assert html =~ "Promote after approval"
    assert html =~ "/forgejo-shell/reports"
    assert html =~ "/forgejo-shell?demo=kubernetes"
    assert html =~ "Related evidence"
  end

  test "render can show a pre-filtered repo slice" do
    now = ~U[2026-05-23 01:00:00Z]
    {:ok, snapshot} = BoardKanbanReadModel.snapshot("/tmp/repo", board: FakeBoard, now: now)

    cards = Enum.filter(snapshot.cards, &(&1.work_item_id == "wk-2"))
    card_ids = MapSet.new(Enum.map(cards, & &1.work_item_id))
    lanes =
      Enum.map(snapshot.lanes, fn lane ->
        Map.update!(lane, :cards, fn lane_cards ->
          Enum.filter(lane_cards, fn card -> MapSet.member?(card_ids, card.work_item_id) end)
        end)
      end)

    html =
      %{
        __changed__: %{},
        repo_path: "/tmp/repo",
        params: %{"repo" => "deepwatrcreatur/agent-roundtable"},
        filters: snapshot.filters,
        counts: snapshot.counts,
        snapshot_generated_at: snapshot.generated_at,
        error: nil,
        cards: cards,
        lanes: lanes,
        selected_card: List.first(cards)
      }
      |> BoardLive.render()
      |> rendered_to_string()

    assert html =~ "Needs approval"
    refute html =~ "Queued card"
  end
end

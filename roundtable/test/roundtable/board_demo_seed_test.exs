defmodule Roundtable.BoardDemoSeedTest do
  use ExUnit.Case, async: true

  alias Roundtable.BoardDemoSeed

  defmodule FakeBoard do
    def heartbeat_runtime(_repo_path, attrs, _opts) do
      send(self(), {:heartbeat_runtime, attrs})
      :ok
    end

    def create_work_item(_repo_path, attrs, _opts) do
      send(self(), {:create_work_item, attrs})
      :ok
    end

    def append_attempt(_repo_path, attrs, _opts) do
      send(self(), {:append_attempt, attrs})
      :ok
    end

    def open_human_gate(_repo_path, attrs, _opts) do
      send(self(), {:open_human_gate, attrs})
      :ok
    end

    def append_attempt_event(_repo_path, attrs, _opts) do
      send(self(), {:append_attempt_event, attrs})
      :ok
    end
  end

  test "seed writes a representative set of board records" do
    assert :ok = BoardDemoSeed.seed("/tmp/repo", board: FakeBoard)

    heartbeats = drain(:heartbeat_runtime)
    work_items = drain(:create_work_item)
    attempts = drain(:append_attempt)
    gates = drain(:open_human_gate)
    events = drain(:append_attempt_event)

    assert length(heartbeats) == 3
    assert Enum.any?(heartbeats, &(&1.runtime_id == "runtime-vaglio-ops" and &1.status == "offline"))

    assert length(work_items) == 6
    assert Enum.any?(work_items, &(&1.id == "wk-queued" and &1.status == "queued"))
    assert Enum.any?(work_items, &(&1.id == "wk-gated" and &1.priority == 10))
    assert Enum.any?(work_items, &(&1.id == "wk-done" and &1.status == "succeeded"))

    assert length(attempts) == 5
    assert Enum.any?(attempts, &(&1.id == "att-attention-1" and &1.status == "running"))
    assert Enum.any?(attempts, &(&1.id == "att-closed-1" and &1.exit_class == "tool_error"))

    assert gates == [
             %{
               attempt_id: "att-gated-1",
               created_at: "2026-05-23T02:10:00Z",
               gate_type: "approve",
               id: "gate-gated-1",
               options: ["approve", "request changes", "hold"],
               prompt: "Promote the persistent board-repo bootstrap fix to main?",
               state: "open",
               work_item_id: "wk-gated"
             }
           ]

    assert length(events) == 3
    assert Enum.any?(events, &(&1.id == "evt-running-1"))
  end

  defp drain(tag), do: drain(tag, [])

  defp drain(tag, acc) do
    receive do
      {^tag, attrs} -> drain(tag, [attrs | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end
end

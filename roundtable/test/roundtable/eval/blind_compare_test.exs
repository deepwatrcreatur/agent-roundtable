defmodule Roundtable.Eval.BlindCompareTest do
  use ExUnit.Case, async: false

  alias Roundtable.Eval
  alias Roundtable.Eval.Run

  setup do
    state_dir = Application.get_env(:roundtable, :state_dir, "/tmp/roundtable_test_state")
    blind_root = Path.join([state_dir, "eval", "blind"])
    File.rm_rf!(blind_root)

    on_exit(fn -> File.rm_rf!(blind_root) end)
    :ok
  end

  test "writes output_a, output_b, and manifest for a run pair" do
    vaglio =
      %Run{
        id: "eval-vaglio-1",
        question: "Should we persist state?",
        mode: :vaglio,
        final_output: "Use persisted state."
      }

    single =
      %Run{
        id: "eval-single-1",
        question: "Should we persist state?",
        mode: :single_structured,
        final_output: "Maybe persist state."
      }

    assert {:ok, dir} = Eval.blind_compare(vaglio, single)
    assert dir =~ "eval-vaglio-1"

    assert File.read!(Path.join(dir, "output_a.md")) in ["Use persisted state.", "Maybe persist state."]
    assert File.read!(Path.join(dir, "output_b.md")) in ["Use persisted state.", "Maybe persist state."]

    assert {:ok, manifest} =
             dir
             |> Path.join("manifest.json")
             |> File.read()
             |> then(fn {:ok, json} -> Jason.decode(json) end)

    assert manifest["question"] == "Should we persist state?"

    pair = {
      get_in(manifest, ["a", "mode"]),
      get_in(manifest, ["b", "mode"])
    }

    assert pair in [
             {"vaglio", "single_structured"},
             {"single_structured", "vaglio"}
           ]
  end

  test "returns error when questions differ" do
    run_a = %Run{id: "a", question: "Question A", mode: :vaglio, final_output: "A"}
    run_b = %Run{id: "b", question: "Question B", mode: :single_structured, final_output: "B"}

    assert {:error, :question_mismatch} = Eval.blind_compare(run_a, run_b)
  end
end

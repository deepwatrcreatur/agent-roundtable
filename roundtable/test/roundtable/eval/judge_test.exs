defmodule Roundtable.Eval.JudgeTest do
  use ExUnit.Case, async: true

  alias Roundtable.Eval.Judge

  describe "extract_considerations/2" do
    test "parses a json array from markdown fenced output" do
      text = "Some eval output"

      invoke = fn prompt ->
        assert prompt =~ text

        {:ok,
         """
         ```json
         [{"claim":"Use a persisted state store","provenance":"observed"}]
         ```
         """}
      end

      assert {:ok, [%{"claim" => "Use a persisted state store", "provenance" => "observed"}]} =
               Judge.extract_considerations(text, invoke: invoke)
    end

    test "returns parse failure on invalid json" do
      assert {:error, {:json_parse_failed, "not-json"}} =
               Judge.extract_considerations("x", invoke: fn _ -> {:ok, "not-json"} end)
    end
  end

  describe "check_consistency/2" do
    test "parses a consistency object" do
      invoke = fn _ ->
        {:ok, ~s({"consistent":false,"contradictions":["A and not-A"]})}
      end

      assert {:ok, %{"consistent" => false, "contradictions" => ["A and not-A"]}} =
               Judge.check_consistency("x", invoke: invoke)
    end
  end

  describe "count_dissent/2" do
    test "parses dissent count and examples" do
      invoke = fn _ ->
        {:ok, ~s({"dissent_count":2,"examples":["codex disagrees","gemini objects"]})}
      end

      assert {:ok,
              %{
                "dissent_count" => 2,
                "examples" => ["codex disagrees", "gemini objects"]
              }} = Judge.count_dissent("x", invoke: invoke)
    end
  end
end

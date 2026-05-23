defmodule Mix.Tasks.Roundtable.SeedBoardDemoTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Roundtable.SeedBoardDemo

  test "parse_args accepts positional repo path" do
    assert SeedBoardDemo.parse_args(["/tmp/board"]) == "/tmp/board"
  end

  test "parse_args accepts flag repo path" do
    assert SeedBoardDemo.parse_args(["--repo-path", "/tmp/board"]) == "/tmp/board"
  end

  test "parse_args falls back to board env" do
    System.put_env("ROUNDTABLE_BOARD_REPO_PATH", "/tmp/env-board")

    try do
      assert SeedBoardDemo.parse_args([]) == "/tmp/env-board"
    after
      System.delete_env("ROUNDTABLE_BOARD_REPO_PATH")
    end
  end
end

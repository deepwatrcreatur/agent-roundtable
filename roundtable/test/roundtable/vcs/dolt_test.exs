defmodule Roundtable.Vcs.DoltTest do
  use ExUnit.Case, async: true

  alias Roundtable.Vcs.Dolt

  defmodule FakeRunner do
    def cmd(command, args, opts) do
      send(self(), {:cmd, command, args, opts})
      {~s({"rows":[]}), 0}
    end
  end

  defmodule EmptyRunner do
    def cmd(command, args, opts) do
      send(self(), {:cmd, command, args, opts})
      {"", 0}
    end
  end

  defmodule NoChangeCommitRunner do
    def cmd("dolt", ["add", "."], _opts), do: {"", 0}
    def cmd("dolt", ["commit" | _rest], _opts), do: {"no changes added to commit (use \"dolt add\")\n", 1}
    def cmd("dolt", ["log", "-n", "1", "--oneline", "main"], _opts), do: {"abc123 seed board\n", 0}
  end

  test "query uses dolt sql result-format without a duplicate revision flag" do
    assert {:ok, []} =
             Dolt.query(
               "select * from work_items",
               repo_path: "/tmp/board",
               runner: FakeRunner
             )

    assert_received {:cmd, "dolt", args, [cd: "/tmp/board", stderr_to_stdout: true]}
    assert args == ["sql", "-q", "select * from work_items", "-r", "json"]
  end

  test "read_file uses dolt sql result-format without a duplicate revision flag" do
    assert {:ok, _json} =
             Dolt.read_file(
               "work_items",
               repo_path: "/tmp/board",
               runner: FakeRunner
             )

    assert_received {:cmd, "dolt", args, [cd: "/tmp/board", stderr_to_stdout: true]}
    assert args == ["sql", "-q", "SELECT * FROM `work_items`", "-r", "json"]
  end

  test "query treats empty dolt output as an empty result set" do
    assert {:ok, []} =
             Dolt.query(
               "create table if not exists work_items (id text)",
               repo_path: "/tmp/board",
               runner: EmptyRunner
             )
  end

  test "write_files tolerates no-op commits after sql mutation" do
    assert {:ok, %{commit_id: "abc123", branch: "main"}} =
             Dolt.write_files(
               %{message: "seed board", branch: "main", changes: []},
               repo_path: "/tmp/board",
               runner: NoChangeCommitRunner
             )
  end

  test "current_head parses dolt log output" do
    assert {:ok, "abc123"} =
             Dolt.current_head(
               "main",
               repo_path: "/tmp/board",
               runner: NoChangeCommitRunner
             )
  end
end

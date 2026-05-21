defmodule Mix.Tasks.Roundtable.DemoSnapshotTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Roundtable.DemoSnapshot

  test "parse_args rejects extra positional args" do
    assert_raise RuntimeError, ~r/expected exactly one demo id/, fn ->
      DemoSnapshot.parse_args(["forgejo", "nixpkgs"])
    end
  end

  test "parse_args rejects invalid flags" do
    assert_raise RuntimeError, ~r/invalid arguments/, fn ->
      DemoSnapshot.parse_args(["--bogus", "forgejo"])
    end
  end

  test "parse_args returns one demo id and opts" do
    assert {"forgejo", opts} =
             DemoSnapshot.parse_args([
               "--output-root",
               "/tmp/demo-output",
               "--base-url",
               "https://codeberg.org",
               "forgejo"
             ])

    assert opts[:output_root] == "/tmp/demo-output"
    assert opts[:base_url] == "https://codeberg.org"
  end
end

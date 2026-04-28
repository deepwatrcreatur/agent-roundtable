defmodule RoundtableTest do
  use ExUnit.Case, async: true

  doctest Roundtable

  test "hello/0 returns :world" do
    assert Roundtable.hello() == :world
  end
end

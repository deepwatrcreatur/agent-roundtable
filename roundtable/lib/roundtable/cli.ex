defmodule Roundtable.CLI do
  @moduledoc """
  Minimal entry point for the roundtable scaffold.
  """

  @spec main([String.t()]) :: :ok
  def main(_args) do
    IO.puts("Roundtable scaffold ready.")
    :ok
  end
end

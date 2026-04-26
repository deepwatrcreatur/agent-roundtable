defmodule Roundtable.CLI do
  @moduledoc """
  Entry point for the roundtable CLI.
  """

  def main(args) do
    case parse_args(args) do
      {:ok, brief_path} ->
        run_roundtable(brief_path)
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        System.halt(1)
    end
  end

  defp parse_args([path]), do: {:ok, path}
  defp parse_args(_), do: {:error, "Usage: roundtable <brief.md>"}

  defp run_roundtable(brief_path) do
    IO.puts("Starting roundtable for #{brief_path}...")
    # 1. Parse BRIEF.md (placeholder)
    # 2. Initialize Jido Agent
    # 3. Run the loop
    :ok
  end
end

defmodule Roundtable.SystemCmdRunner do
  @moduledoc false

  @behaviour Roundtable.CommandRunner

  @impl true
  def cmd(command, args, opts), do: System.cmd(command, args, opts)
end

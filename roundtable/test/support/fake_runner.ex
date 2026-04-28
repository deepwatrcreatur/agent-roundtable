defmodule Roundtable.TestSupport.FakeRunner do
  @moduledoc false

  @behaviour Roundtable.CommandRunner

  @impl true
  def cmd(command, args, opts) do
    parent = Process.get(:test_pid, self())
    send(parent, {:cmd, command, args, opts})

    Process.get(:runner_result, {"", 0})
  end
end

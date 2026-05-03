defmodule Roundtable.TestSupport.FakeRunner do
  @moduledoc false

  @behaviour Roundtable.CommandRunner

  @impl true
  def cmd(command, args, opts) do
    parent = Process.get(:test_pid, self())
    send(parent, {:cmd, command, args, opts})

    case Process.get(:runner_result, {"", 0}) do
      fun when is_function(fun, 0) -> fun.()
      result -> result
    end
  end
end

defmodule Roundtable.CommandRunner do
  @moduledoc """
  Abstraction over command execution so CLI-facing modules can be unit tested.
  """

  @type command :: String.t()
  @type args :: [String.t()]
  @type opts :: keyword()
  @type result :: {String.t(), non_neg_integer()} | {:error, term()}

  @callback cmd(command(), args(), opts()) :: result()
end

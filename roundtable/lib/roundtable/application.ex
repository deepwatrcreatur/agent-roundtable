defmodule Roundtable.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        {Phoenix.PubSub, name: Roundtable.PubSub},
        if web_enabled?() do
          RoundtableWeb.Endpoint
        end
      ]
      |> Enum.reject(&is_nil/1)

    opts = [strategy: :one_for_one, name: Roundtable.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp web_enabled? do
    Mix.env() in [:dev, :prod] or System.get_env("ROUNDTABLE_WEB") == "true"
  end

  defp web_port do
    case System.get_env("PORT") do
      nil -> 4000
      p -> String.to_integer(p)
    end
  end
end

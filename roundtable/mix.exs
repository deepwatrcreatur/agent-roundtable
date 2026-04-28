defmodule Roundtable.MixProject do
  use Mix.Project

  def project do
    [
      app: :roundtable,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Roundtable.Application, []}
    ]
  end

  defp deps do
    [
      {:jido, "~> 2.0"},
      # Web dashboard (item 10)
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"}
    ]
  end
end

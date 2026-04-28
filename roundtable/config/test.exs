import Config

config :roundtable, RoundtableWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warning

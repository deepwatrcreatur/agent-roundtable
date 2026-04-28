import Config

config :roundtable, RoundtableWeb.Endpoint,
  http: [port: 4002],
  server: false

config :roundtable, web_enabled: false
config :logger, level: :warning

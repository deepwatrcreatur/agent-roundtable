import Config

config :roundtable, RoundtableWeb.Endpoint,
  http: [port: 4002],
  server: false

config :roundtable, web_enabled: false
config :roundtable, state_dir: "/tmp/roundtable_test_state"
config :logger, level: :warning

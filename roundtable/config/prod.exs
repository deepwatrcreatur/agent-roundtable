import Config

host = System.get_env("HOST") || System.get_env("PHX_HOST") || "localhost"

config :roundtable, RoundtableWeb.Endpoint,
  server: true,
  url: [host: host]

config :roundtable,
  web_enabled: System.get_env("ROUNDTABLE_WEB") != "false",
  state_dir: System.get_env("ROUNDTABLE_STATE_DIR") || "/var/lib/roundtable/state",
  telemetry_handler: :json_logger

config :logger, level: :info
config :logger, :console, format: "[$level] $message\n"
config :phoenix, :plug_init_mode, :runtime

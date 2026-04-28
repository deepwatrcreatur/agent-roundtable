import Config

config :roundtable, RoundtableWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: false,
  check_origin: false,
  watchers: []

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20

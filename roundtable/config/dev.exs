import Config

config :roundtable, RoundtableWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: false,
  check_origin: false,
  watchers: []

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20

# Attach a JSON-to-stdout telemetry handler for all roundtable spans.
# To attach an OTEL exporter instead, see https://hex.pm/packages/opentelemetry_exporter
# and call :telemetry.attach_many/4 with Roundtable.Telemetry.all_events() in your
# application start, replacing this handler.
config :roundtable, telemetry_handler: :json_logger

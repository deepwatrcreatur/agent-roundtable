import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE env var required in production"

  port = String.to_integer(System.get_env("PORT") || "4000")

  config :roundtable, RoundtableWeb.Endpoint,
    http: [port: port],
    secret_key_base: secret_key_base,
    url: [host: System.get_env("HOST") || "localhost", port: port]
end

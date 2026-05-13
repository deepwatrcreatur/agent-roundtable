import Config

config :roundtable, RoundtableWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      "roundtable_dev_secret_do_not_use_in_production_replace_with_mix_phx_gen_secret",
  render_errors: [formats: [html: RoundtableWeb.ErrorHTML]],
  pubsub_server: Roundtable.PubSub,
  live_view: [signing_salt: "roundtable_lv_salt"]

config :roundtable, RoundtableWeb.Endpoint, adapter: Bandit.PhoenixAdapter

import_config "#{config_env()}.exs"

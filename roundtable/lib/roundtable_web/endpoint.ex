defmodule RoundtableWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :roundtable

  @session_options [
    store: :cookie,
    key: "_roundtable_key",
    signing_salt: "roundtable_session_salt"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :roundtable,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], json_decoder: Jason
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug RoundtableWeb.Router
end

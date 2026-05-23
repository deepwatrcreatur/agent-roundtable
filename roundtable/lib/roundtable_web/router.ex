defmodule RoundtableWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {RoundtableWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(RoundtableWeb.UserAuth)
  end

  scope "/", RoundtableWeb do
    pipe_through(:browser)

    get("/auth/sign_in", AuthController, :sign_in)
    get("/auth/callback", AuthController, :callback)
    get("/auth/sign_out", AuthController, :sign_out)

    live("/", LandingLive)
    live("/board", BoardLive)

    live_session :authenticated, on_mount: [{RoundtableWeb.UserAuth, :ensure_authenticated}] do
      live("/roundtable", DiscussionLive)
    end

    live("/forgejo-shell", ForgejoShellLive)
    live("/forgejo-shell/reports", ForgejoShellReportsLive)
  end
end

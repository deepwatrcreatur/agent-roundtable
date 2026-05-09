defmodule RoundtableWeb.Layouts do
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>Vaglio / Roundtable</title>
        <style>
          *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
          body { font-family: ui-monospace, 'Cascadia Code', 'Source Code Pro', monospace;
                 background: #0d1117; color: #c9d1d9; min-height: 100vh; }
          a { color: #58a6ff; }
        </style>
        <script defer src="/vendor/phoenix/phoenix.min.js"></script>
        <script defer src="/vendor/phoenix_live_view/phoenix_live_view.min.js"></script>
        <script defer>
          window.addEventListener("DOMContentLoaded", () => {
            const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

            if (window.Phoenix && window.LiveView && !window.liveSocket) {
              const liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
                params: { _csrf_token: csrfToken }
              })

              liveSocket.connect()
              window.liveSocket = liveSocket
            }
          })
        </script>
      </head>
      <body>
        <nav style="border-bottom: 1px solid #21262d; background: #0d1117; position: sticky; top: 0; z-index: 10;">
          <div style="max-width: 1100px; margin: 0 auto; padding: 0.85rem 1rem; display: flex; gap: 0.75rem; align-items: center; justify-content: space-between;">
            <div style="color: #f0f6fc; font-weight: 700; font-size: 0.95rem;">Deepwater Roundtable</div>
            <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
              <a href="/" style="text-decoration: none; color: #c9d1d9; border: 1px solid #30363d; border-radius: 999px; padding: 0.35rem 0.75rem; font-size: 0.82rem;">
                Vaglio Demo Home
              </a>
              <a href="/forgejo-shell" style="text-decoration: none; color: #c9d1d9; border: 1px solid #30363d; border-radius: 999px; padding: 0.35rem 0.75rem; font-size: 0.82rem;">
                Forgejo Demo Shell
              </a>
              <a href="/roundtable" style="text-decoration: none; color: #c9d1d9; border: 1px solid #30363d; border-radius: 999px; padding: 0.35rem 0.75rem; font-size: 0.82rem;">
                Roundtable Ops
              </a>
            </div>
          </div>
        </nav>
        {@inner_content}
      </body>
    </html>
    """
  end

  def app(assigns) do
    ~H"""
    {@inner_content}
    """
  end
end

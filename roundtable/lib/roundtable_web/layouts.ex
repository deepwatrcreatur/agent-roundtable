defmodule RoundtableWeb.Layouts do
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Roundtable</title>
        <style>
          *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
          body { font-family: ui-monospace, 'Cascadia Code', 'Source Code Pro', monospace;
                 background: #0d1117; color: #c9d1d9; min-height: 100vh; }
          a { color: #58a6ff; }
        </style>
        {@inner_content}
      </head>
      <body>
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

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
          :root {
            --rt-ink: #201d1d;
            --rt-ink-deep: #0f0000;
            --rt-body: #424245;
            --rt-mute: #646262;
            --rt-ash: #9a9898;
            --rt-canvas: #fdfcfc;
            --rt-surface: #f8f7f7;
            --rt-surface-card: #f1eeee;
            --rt-surface-dark: #201d1d;
            --rt-surface-dark-elevated: #302c2c;
            --rt-hairline: rgba(15, 0, 0, 0.12);
            --rt-hairline-strong: #646262;
            --rt-on-dark: #fdfcfc;
            --rt-on-dark-mute: #9a9898;
            --rt-accent: #007aff;
            --rt-success: #30d158;
            --rt-warning: #ff9f0a;
            --rt-danger: #ff3b30;
            --rt-radius: 4px;
            --rt-font: "Berkeley Mono", "Cascadia Code", "SFMono-Regular", "Menlo", "Consolas", monospace;
          }

          *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

          html { background: var(--rt-canvas); }

          body {
            background:
              radial-gradient(circle at top right, rgba(0, 122, 255, 0.05), transparent 28rem),
              linear-gradient(180deg, #fffefe 0%, var(--rt-canvas) 14rem, var(--rt-canvas) 100%);
            color: var(--rt-body);
            font-family: var(--rt-font);
            font-size: 16px;
            line-height: 1.5;
            min-height: 100vh;
          }

          a {
            color: var(--rt-ink);
            text-decoration: none;
          }

          button, input, textarea {
            font: inherit;
          }

          .rt-shell {
            max-width: 1040px;
            margin: 0 auto;
            padding: 48px 16px 72px;
          }

          .rt-panel {
            background: rgba(253, 252, 252, 0.84);
            border: 1px solid var(--rt-hairline);
            border-radius: var(--rt-radius);
          }

          .rt-panel-dark {
            background: var(--rt-surface-dark);
            border: 1px solid var(--rt-surface-dark-elevated);
            color: var(--rt-on-dark);
            border-radius: var(--rt-radius);
          }

          .rt-header {
            display: grid;
            gap: 12px;
            margin-bottom: 32px;
          }

          .rt-kicker {
            color: var(--rt-mute);
            font-size: 14px;
            letter-spacing: 0;
          }

          .rt-title {
            color: var(--rt-ink);
            font-size: 38px;
            font-weight: 700;
            line-height: 1.25;
          }

          .rt-meta {
            color: var(--rt-mute);
            font-size: 14px;
          }

          .rt-section {
            margin-top: 24px;
          }

          .rt-section-title {
            color: var(--rt-ink);
            font-size: 16px;
            font-weight: 700;
            line-height: 1.5;
            margin-bottom: 12px;
          }

          .rt-code-chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            border: 1px solid var(--rt-hairline);
            background: var(--rt-surface);
            border-radius: var(--rt-radius);
            color: var(--rt-mute);
            padding: 2px 8px;
            font-size: 14px;
          }

          .rt-terminal {
            background: var(--rt-surface-dark);
            color: var(--rt-on-dark);
            border-radius: 0;
            padding: 20px;
            border: 1px solid var(--rt-surface-dark-elevated);
          }

          .rt-terminal-title {
            color: var(--rt-on-dark-mute);
            font-size: 14px;
            margin-bottom: 12px;
          }

          .rt-button {
            appearance: none;
            border: 1px solid var(--rt-hairline);
            border-radius: var(--rt-radius);
            background: var(--rt-canvas);
            color: var(--rt-ink);
            cursor: pointer;
            min-height: 36px;
            padding: 4px 20px;
          }

          .rt-button:hover:not(:disabled) {
            background: var(--rt-surface-card);
          }

          .rt-button:disabled {
            background: var(--rt-surface-card);
            color: var(--rt-ash);
            cursor: default;
          }

          .rt-button-primary {
            background: var(--rt-surface-dark);
            border-color: var(--rt-surface-dark);
            color: var(--rt-on-dark);
          }

          .rt-button-primary:hover:not(:disabled) {
            background: var(--rt-ink-deep);
            border-color: var(--rt-ink-deep);
          }

          .rt-banner {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            padding: 12px 16px;
            margin-bottom: 24px;
          }

          .rt-banner-text {
            color: var(--rt-body);
            font-size: 14px;
          }

          .rt-banner-close {
            background: transparent;
            border: none;
            color: var(--rt-mute);
            cursor: pointer;
            font-size: 18px;
            line-height: 1;
          }

          .rt-input,
          .rt-textarea {
            width: 100%;
            border: 1px solid var(--rt-hairline);
            border-radius: var(--rt-radius);
            background: var(--rt-surface);
            color: var(--rt-ink);
            padding: 12px;
            resize: vertical;
          }

          .rt-input:focus,
          .rt-textarea:focus {
            outline: 1px solid var(--rt-hairline-strong);
            background: var(--rt-canvas);
          }

          .rt-stack {
            display: grid;
            gap: 12px;
          }

          .rt-row {
            display: flex;
            gap: 12px;
            align-items: flex-start;
          }

          @media (max-width: 720px) {
            .rt-shell { padding: 24px 12px 48px; }
            .rt-title { font-size: 30px; }
            .rt-row { flex-direction: column; }
          }
        </style>
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

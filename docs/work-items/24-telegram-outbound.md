# 24 — Outbound Telegram Notifications

**Status:** `ready`

## Scope

Send outbound Telegram messages on key orchestrator events (Protocol Update 11 / Q24).
No inbound prompt injection — LiveView is the primary write path.

## Implementation

Add `Roundtable.Notifier.Telegram` module:

```elixir
defmodule Roundtable.Notifier.Telegram do
  @base "https://api.telegram.org"

  def notify(text) do
    token   = System.get_env("TELEGRAM_BOT_TOKEN")
    chat_id = System.get_env("TELEGRAM_CHAT_ID")
    if token && chat_id, do: send_message(token, chat_id, text)
  end

  defp send_message(token, chat_id, text) do
    url = "#{@base}/bot#{token}/sendMessage"
    body = Jason.encode!(%{chat_id: chat_id, text: text, parse_mode: "Markdown"})
    # Use :httpc (built-in) or add :req to deps
    ...
  end
end
```

Hook into `Orchestrator.notify/2` for events:
- `{:question_satisfied, id, rounds}` → "✓ *#{id}* satisfied after #{rounds} round(s)"
- `{:question_max_rounds, id}` → "⚠ *#{id}* needs human review"
- `{:coordinator_takeover, id, agent}` → "↩ Coordinator takeover on #{id}: #{agent}"

## Environment variables

| Var | Description |
|---|---|
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather |
| `TELEGRAM_CHAT_ID` | Chat or channel ID to send to |

Both optional — feature is silently disabled when unset.

## Dependencies

Add `:req` to `mix.exs` (preferred over raw `:httpc` for cleaner API):
```elixir
{:req, "~> 0.5"}
```

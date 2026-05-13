defmodule Roundtable.Notifier.TelegramTest do
  use ExUnit.Case, async: false

  alias Roundtable.Notifier.Telegram

  setup do
    prev_env = Application.get_env(:roundtable, Telegram)
    prev_token = System.get_env("TELEGRAM_BOT_TOKEN")
    prev_chat_id = System.get_env("TELEGRAM_CHAT_ID")

    on_exit(fn ->
      if prev_env == nil do
        Application.delete_env(:roundtable, Telegram)
      else
        Application.put_env(:roundtable, Telegram, prev_env)
      end

      restore_env("TELEGRAM_BOT_TOKEN", prev_token)
      restore_env("TELEGRAM_CHAT_ID", prev_chat_id)
    end)

    :ok
  end

  describe "event_text/1" do
    test "formats supported orchestrator events" do
      assert Telegram.event_text({:question_satisfied, "Q20", 3}) ==
               "Question Q20 satisfied after 3 round(s)"

      assert Telegram.event_text({:question_max_rounds, "Q21"}) ==
               "Question Q21 needs human review"

      assert Telegram.event_text({:coordinator_takeover, "Q20", :codex}) ==
               "Coordinator takeover on Q20: codex"
    end

    test "returns nil for unrelated events" do
      assert Telegram.event_text({:agent_done, :codex, 1}) == nil
    end
  end

  describe "notify/1" do
    test "silently skips when credentials are unset" do
      Application.put_env(:roundtable, Telegram,
        http_client: fn _url, _body -> flunk("http client should not be called") end
      )

      System.delete_env("TELEGRAM_BOT_TOKEN")
      System.delete_env("TELEGRAM_CHAT_ID")

      assert :ok = Telegram.notify("hello")
    end

    test "posts to Telegram with configured credentials" do
      parent = self()

      Application.put_env(:roundtable, Telegram,
        http_client: fn url, body ->
          send(parent, {:http_request, url, body})
          {:ok, %{status: 200}}
        end
      )

      System.put_env("TELEGRAM_BOT_TOKEN", "bot-token")
      System.put_env("TELEGRAM_CHAT_ID", "chat-id")

      assert :ok = Telegram.notify("hello from roundtable")

      assert_receive {:http_request, "https://api.telegram.org/botbot-token/sendMessage",
                      %{chat_id: "chat-id", text: "hello from roundtable"}}
    end

    test "returns error from the http client" do
      Application.put_env(:roundtable, Telegram,
        http_client: fn _url, _body -> {:error, :timeout} end
      )

      System.put_env("TELEGRAM_BOT_TOKEN", "bot-token")
      System.put_env("TELEGRAM_CHAT_ID", "chat-id")

      assert {:error, :timeout} = Telegram.notify("hello")
    end
  end

  describe "notify_event/1" do
    test "sends supported events through notify/1" do
      parent = self()

      Application.put_env(:roundtable, Telegram,
        http_client: fn _url, body ->
          send(parent, {:message_text, body.text})
          {:ok, %{status: 200}}
        end
      )

      System.put_env("TELEGRAM_BOT_TOKEN", "bot-token")
      System.put_env("TELEGRAM_CHAT_ID", "chat-id")

      assert :ok = Telegram.notify_event({:question_satisfied, "Q20", 2})
      assert_receive {:message_text, "Question Q20 satisfied after 2 round(s)"}
    end

    test "ignores unsupported events" do
      Application.put_env(:roundtable, Telegram,
        http_client: fn _url, _body -> flunk("http client should not be called") end
      )

      System.put_env("TELEGRAM_BOT_TOKEN", "bot-token")
      System.put_env("TELEGRAM_CHAT_ID", "chat-id")

      assert :ok = Telegram.notify_event({:agent_done, :codex, 1})
    end
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end

defmodule Roundtable.Notifier.Telegram do
  @moduledoc """
  Sends outbound Telegram notifications for selected orchestrator events.

  The notifier is optional. When `TELEGRAM_BOT_TOKEN` or `TELEGRAM_CHAT_ID`
  is unset, events are ignored silently.
  """

  @base_url "https://api.telegram.org"

  @type event ::
          {:question_satisfied, String.t() | atom() | pos_integer(), non_neg_integer()}
          | {:question_max_rounds, String.t() | atom() | pos_integer()}
          | {:coordinator_takeover, String.t() | atom() | pos_integer(), atom()}
          | term()

  @spec notify(String.t()) :: :ok | {:error, term()}
  def notify(text) when is_binary(text) do
    case credentials() do
      {:ok, token, chat_id} ->
        send_message(token, chat_id, text)

      :disabled ->
        :ok
    end
  end

  @spec notify_event(event()) :: :ok | {:error, term()}
  def notify_event(event) do
    case event_text(event) do
      nil -> :ok
      text -> notify(text)
    end
  end

  @spec event_text(event()) :: String.t() | nil
  def event_text({:question_satisfied, id, rounds}) do
    "Question #{id} satisfied after #{rounds} round(s)"
  end

  def event_text({:question_max_rounds, id}) do
    "Question #{id} needs human review"
  end

  def event_text({:coordinator_takeover, id, agent}) do
    "Coordinator takeover on #{id}: #{agent}"
  end

  def event_text(_event), do: nil

  defp credentials do
    token = System.get_env("TELEGRAM_BOT_TOKEN")
    chat_id = System.get_env("TELEGRAM_CHAT_ID")

    if present?(token) and present?(chat_id) do
      {:ok, token, chat_id}
    else
      :disabled
    end
  end

  defp present?(value), do: is_binary(value) and value != ""

  defp send_message(token, chat_id, text) do
    url = "#{@base_url}/bot#{token}/sendMessage"
    body = %{chat_id: chat_id, text: text}

    case http_client().(url, body) do
      {:ok, _response} -> :ok
      {:error, _reason} = error -> error
      %Req.Response{} -> :ok
      other -> {:error, {:unexpected_response, other}}
    end
  rescue
    error -> {:error, error}
  end

  defp http_client do
    Application.get_env(:roundtable, __MODULE__, [])
    |> Keyword.get(:http_client, &default_http_client/2)
  end

  defp default_http_client(url, body) do
    Req.post(url: url, json: body)
  end
end

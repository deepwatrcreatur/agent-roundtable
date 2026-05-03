defmodule Roundtable.Eval.Run do
  @moduledoc """
  Struct representing a single evaluation run — one question through one mode.

  Modes:
  - `:vaglio` — full multi-agent protocol via Orchestrator
  - `:single_naive` — single model, plain question+context prompt
  - `:single_structured` — single model with vaglio prompt instructions
  - `:single_debate` — single model generating three perspectives then synthesizing
  """

  @type mode :: :vaglio | :single_naive | :single_structured | :single_debate

  @type t :: %__MODULE__{
          id: String.t(),
          question: String.t(),
          brief_context: String.t(),
          mode: mode(),
          model: atom() | nil,
          turns: [map()],
          final_output: String.t() | nil,
          metrics: map() | nil,
          tokens_used: non_neg_integer() | nil,
          cost_usd: float() | nil,
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :question,
    :brief_context,
    :mode,
    :model,
    turns: [],
    final_output: nil,
    metrics: nil,
    tokens_used: nil,
    cost_usd: nil,
    started_at: nil,
    completed_at: nil
  ]

  @doc "Generate a unique eval run ID."
  @spec generate_id(mode()) :: String.t()
  def generate_id(mode) do
    ts = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    rand = :rand.uniform(0xFFFF) |> Integer.to_string(16) |> String.pad_leading(4, "0")
    "eval-#{mode}-#{ts}-#{rand}"
  end

  @doc "Serialize a Run to a JSON-encodable map."
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = run) do
    %{
      id: run.id,
      question: run.question,
      brief_context: run.brief_context,
      mode: Atom.to_string(run.mode),
      model: if(run.model, do: Atom.to_string(run.model)),
      turns: run.turns,
      final_output: run.final_output,
      metrics: run.metrics,
      tokens_used: run.tokens_used,
      cost_usd: run.cost_usd,
      started_at: format_dt(run.started_at),
      completed_at: format_dt(run.completed_at)
    }
  end

  @doc "Deserialize a Run from a decoded JSON map."
  @spec from_map(map()) :: t()
  def from_map(data) do
    %__MODULE__{
      id: data["id"],
      question: data["question"],
      brief_context: data["brief_context"],
      mode: String.to_existing_atom(data["mode"]),
      model: if(data["model"], do: String.to_existing_atom(data["model"])),
      turns: data["turns"] || [],
      final_output: data["final_output"],
      metrics: data["metrics"],
      tokens_used: data["tokens_used"],
      cost_usd: data["cost_usd"],
      started_at: parse_dt(data["started_at"]),
      completed_at: parse_dt(data["completed_at"])
    }
  end

  defp format_dt(nil), do: nil
  defp format_dt(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp parse_dt(nil), do: nil
  defp parse_dt(s) when is_binary(s) do
    case DateTime.from_iso8601(s) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
end

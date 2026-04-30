defmodule Roundtable.Eval.Judge do
  @moduledoc """
  LLM-as-judge for extracting structured metrics from eval run outputs.

  Uses Claude via `RunCliAgent` in a separate context. Judge prompts are
  designed to be mode-blind — they never reveal whether text came from
  vaglio or a single-model baseline.
  """

  alias Roundtable.Actions.RunCliAgent

  @doc """
  Extract unique considerations from output text.

  Returns a list of `%{claim: String.t(), provenance: String.t()}` maps.
  """
  @spec extract_considerations(String.t(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def extract_considerations(text, opts \\ []) do
    repo_root = Keyword.get(opts, :repo_root, File.cwd!())

    prompt = """
    You are a careful analyst. Extract every distinct consideration, argument, \
    or recommendation from the text below. For each, identify the provenance type \
    (observed, inferred, testimony, or unknown).

    Return ONLY a JSON array. Each element: {"claim": "...", "provenance": "..."}

    Do not add commentary. Return valid JSON only.

    ---
    #{String.slice(text, 0, 6000)}
    """

    case invoke_judge(prompt, repo_root) do
      {:ok, raw} -> parse_json_array(raw)
      error -> error
    end
  end

  @doc """
  Check for internal contradictions in the text.

  Returns `%{consistent: boolean(), contradictions: [String.t()]}`.
  """
  @spec check_consistency(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def check_consistency(text, opts \\ []) do
    repo_root = Keyword.get(opts, :repo_root, File.cwd!())

    prompt = """
    You are a logical analyst. Read the text below and identify any internal \
    contradictions — places where the text asserts X and also asserts not-X, or \
    makes incompatible recommendations.

    Return ONLY a JSON object: {"consistent": true/false, "contradictions": ["..."]}

    If there are no contradictions, return: {"consistent": true, "contradictions": []}

    Do not add commentary. Return valid JSON only.

    ---
    #{String.slice(text, 0, 6000)}
    """

    case invoke_judge(prompt, repo_root) do
      {:ok, raw} -> parse_json_object(raw)
      error -> error
    end
  end

  @doc """
  Count explicit disagreements or counter-considerations in multi-agent output.

  Returns `%{dissent_count: non_neg_integer(), examples: [String.t()]}`.
  """
  @spec count_dissent(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def count_dissent(text, opts \\ []) do
    repo_root = Keyword.get(opts, :repo_root, File.cwd!())

    prompt = """
    You are an analyst reviewing a discussion transcript. Count the number of \
    explicit disagreements — places where one section contradicts, challenges, \
    or provides a counter-argument to another section's position.

    Return ONLY a JSON object: {"dissent_count": N, "examples": ["brief description of each disagreement"]}

    If there are no disagreements, return: {"dissent_count": 0, "examples": []}

    Do not add commentary. Return valid JSON only.

    ---
    #{String.slice(text, 0, 6000)}
    """

    case invoke_judge(prompt, repo_root) do
      {:ok, raw} -> parse_json_object(raw)
      error -> error
    end
  end

  # ------------------------------------------------------------------
  # Internals
  # ------------------------------------------------------------------

  defp invoke_judge(prompt, repo_root) do
    case RunCliAgent.run(%{agent: :claude, prompt: prompt, repo_root: repo_root}, %{}) do
      {:ok, %{stdout: raw}} -> {:ok, extract_text(raw)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_text(raw) do
    case JSON.decode(raw) do
      {:ok, %{"result" => text}} when is_binary(text) -> text
      {:ok, %{"content" => text}} when is_binary(text) -> text
      {:ok, %{"message" => text}} when is_binary(text) -> text
      {:ok, %{"text" => text}} when is_binary(text) -> text
      _ -> raw
    end
  end

  defp parse_json_array(raw) do
    # Extract JSON from possible markdown fences
    json_str = extract_json(raw)

    case Jason.decode(json_str) do
      {:ok, list} when is_list(list) -> {:ok, list}
      {:ok, _} -> {:error, :unexpected_json_shape}
      {:error, _} -> {:error, {:json_parse_failed, raw}}
    end
  end

  defp parse_json_object(raw) do
    json_str = extract_json(raw)

    case Jason.decode(json_str) do
      {:ok, map} when is_map(map) -> {:ok, map}
      {:ok, _} -> {:error, :unexpected_json_shape}
      {:error, _} -> {:error, {:json_parse_failed, raw}}
    end
  end

  # Strip markdown code fences if present
  defp extract_json(text) do
    case Regex.run(~r/```(?:json)?\s*\n?([\s\S]*?)\n?```/, text) do
      [_, json] -> String.trim(json)
      nil -> String.trim(text)
    end
  end
end

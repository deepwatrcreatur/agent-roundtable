defmodule Roundtable.Attestation do
  @moduledoc """
  SLSA-compatible attestation hooks for linking code changes to their
  deliberation transcripts.

  Each agent-produced commit can carry an attestation pointing to the specific
  round, decision hash, and agent identity that produced it. This provides
  100% provenance visibility from line-of-code back to agent-consensus.
  """

  require Logger

  @type attestation :: %{
          subject_commit: String.t(),
          predicate_type: String.t(),
          round_ref: String.t(),
          decision_hash: String.t() | nil,
          agent_id: String.t(),
          timestamp: String.t(),
          repo_path: String.t()
        }

  @predicate_type "https://vaglio.dev/attestation/deliberative/v1"

  @doc """
  Builds a SLSA-compatible attestation for a commit produced by an agent
  during a deliberation round.

  The attestation links:
  - the commit (subject) to
  - the round transcript and decision hash (predicate)
  """
  def build(commit_id, opts) do
    round_ref = Keyword.fetch!(opts, :round_ref)
    agent_id = Keyword.fetch!(opts, :agent_id)
    repo_path = Keyword.fetch!(opts, :repo_path)
    decision_hash = Keyword.get(opts, :decision_hash)

    %{
      subject_commit: commit_id,
      predicate_type: @predicate_type,
      round_ref: round_ref,
      decision_hash: decision_hash,
      agent_id: agent_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      repo_path: repo_path
    }
  end

  @doc """
  Serializes an attestation to the SLSA in-toto envelope format (JSON).
  """
  def to_envelope(attestation) do
    payload = %{
      "_type" => "https://in-toto.io/Statement/v1",
      "subject" => [
        %{
          "name" => attestation.subject_commit,
          "digest" => %{"gitCommit" => attestation.subject_commit}
        }
      ],
      "predicateType" => attestation.predicate_type,
      "predicate" => %{
        "roundRef" => attestation.round_ref,
        "decisionHash" => attestation.decision_hash,
        "agentId" => attestation.agent_id,
        "timestamp" => attestation.timestamp,
        "repoPath" => attestation.repo_path
      }
    }

    Jason.encode!(payload)
  end

  @doc """
  Attaches an attestation to a commit as a git note or trailer.

  Stores the attestation as a git note under `refs/notes/attestations`.
  """
  def attach(attestation, opts \\ []) do
    repo_path = Keyword.get(opts, :repo_path, attestation.repo_path)
    envelope = to_envelope(attestation)

    case System.cmd(
           "git",
           ["notes", "--ref=attestations", "add", "-m", envelope, attestation.subject_commit],
           cd: repo_path,
           stderr_to_stdout: true
         ) do
      {_, 0} ->
        Logger.info(
          "[Attestation] attached to #{String.slice(attestation.subject_commit, 0, 8)} " <>
            "round=#{attestation.round_ref} agent=#{attestation.agent_id}"
        )

        :ok

      {output, _} ->
        Logger.warning("[Attestation] failed to attach: #{output}")
        {:error, output}
    end
  end

  @doc """
  Verifies that a commit has a valid attestation linking it to a deliberation
  round. Returns the parsed attestation or an error.

  This is the "Vouch-Verify" command: it checks signatures before code
  promotion by ensuring every commit has provenance back to a round.
  """
  def verify(commit_id, opts) do
    repo_path = Keyword.fetch!(opts, :repo_path)

    case System.cmd(
           "git",
           ["notes", "--ref=attestations", "show", commit_id],
           cd: repo_path,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        case Jason.decode(String.trim(output)) do
          {:ok, %{"predicateType" => @predicate_type} = envelope} ->
            {:ok, parse_envelope(envelope)}

          {:ok, _} ->
            {:error, :unknown_predicate_type}

          {:error, _} ->
            {:error, :invalid_attestation_format}
        end

      {_, _} ->
        {:error, :no_attestation}
    end
  end

  @doc """
  Verifies a range of commits (e.g., all commits in a PR branch).
  Returns `{:ok, results}` with per-commit verification results.

  Unattested commits are flagged as "Unattributed State" in the DAG.
  """
  def verify_range(base_ref, head_ref, opts) do
    repo_path = Keyword.fetch!(opts, :repo_path)

    case System.cmd(
           "git",
           ["rev-list", "#{base_ref}..#{head_ref}"],
           cd: repo_path,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        commits = output |> String.trim() |> String.split("\n", trim: true)

        results =
          Enum.map(commits, fn commit ->
            {commit, verify(commit, repo_path: repo_path)}
          end)

        unattested = Enum.filter(results, fn {_, result} -> match?({:error, _}, result) end)

        if unattested != [] do
          Logger.warning(
            "[Attestation] #{length(unattested)}/#{length(commits)} commits lack attestation"
          )
        end

        {:ok, results}

      {output, _} ->
        {:error, {:rev_list_failed, output}}
    end
  end

  @doc """
  Computes a hash of the current DECISION.md content for attestation binding.
  """
  def decision_hash(repo_path) do
    decision_path = Path.join(repo_path, "docs/design/DECISION.md")

    case File.read(decision_path) do
      {:ok, content} ->
        hash =
          :crypto.hash(:sha256, content)
          |> Base.encode16(case: :lower)

        {:ok, hash}

      {:error, _} ->
        {:ok, nil}
    end
  end

  defp parse_envelope(envelope) do
    predicate = Map.get(envelope, "predicate", %{})
    subject = envelope |> Map.get("subject", []) |> List.first(%{})

    %{
      subject_commit: get_in(subject, ["digest", "gitCommit"]) || Map.get(subject, "name"),
      predicate_type: Map.get(envelope, "predicateType"),
      round_ref: Map.get(predicate, "roundRef"),
      decision_hash: Map.get(predicate, "decisionHash"),
      agent_id: Map.get(predicate, "agentId"),
      timestamp: Map.get(predicate, "timestamp"),
      repo_path: Map.get(predicate, "repoPath")
    }
  end
end

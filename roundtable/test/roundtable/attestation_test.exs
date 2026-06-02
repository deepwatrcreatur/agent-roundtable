defmodule Roundtable.AttestationTest do
  use ExUnit.Case, async: true

  alias Roundtable.Attestation

  @commit_id "abc123def456"
  @round_ref "round-117"
  @agent_id "claude-ic"
  @repo_path "/tmp/test-repo"

  describe "build/2" do
    test "creates attestation with required fields" do
      att =
        Attestation.build(@commit_id,
          round_ref: @round_ref,
          agent_id: @agent_id,
          repo_path: @repo_path
        )

      assert att.subject_commit == @commit_id
      assert att.round_ref == @round_ref
      assert att.agent_id == @agent_id
      assert att.repo_path == @repo_path
      assert att.predicate_type == "https://vaglio.dev/attestation/deliberative/v1"
      assert att.decision_hash == nil
      assert is_binary(att.timestamp)
    end

    test "includes optional decision_hash" do
      att =
        Attestation.build(@commit_id,
          round_ref: @round_ref,
          agent_id: @agent_id,
          repo_path: @repo_path,
          decision_hash: "deadbeef"
        )

      assert att.decision_hash == "deadbeef"
    end
  end

  describe "to_envelope/1" do
    test "produces valid in-toto JSON envelope" do
      att =
        Attestation.build(@commit_id,
          round_ref: @round_ref,
          agent_id: @agent_id,
          repo_path: @repo_path
        )

      json = Attestation.to_envelope(att)
      assert {:ok, decoded} = Jason.decode(json)

      assert decoded["_type"] == "https://in-toto.io/Statement/v1"
      assert decoded["predicateType"] == "https://vaglio.dev/attestation/deliberative/v1"

      [subject] = decoded["subject"]
      assert subject["name"] == @commit_id
      assert subject["digest"]["gitCommit"] == @commit_id

      predicate = decoded["predicate"]
      assert predicate["roundRef"] == @round_ref
      assert predicate["agentId"] == @agent_id
    end
  end

  describe "decision_hash/1" do
    test "returns nil for nonexistent DECISION.md" do
      assert {:ok, nil} = Attestation.decision_hash("/nonexistent/path")
    end

    test "returns SHA256 hash for existing DECISION.md" do
      dir = System.tmp_dir!() |> Path.join("att-test-#{System.unique_integer([:positive])}")
      File.mkdir_p!(Path.join(dir, "docs/design"))
      File.write!(Path.join(dir, "docs/design/DECISION.md"), "test content")

      assert {:ok, hash} = Attestation.decision_hash(dir)
      assert is_binary(hash)
      assert String.length(hash) == 64

      File.rm_rf!(dir)
    end
  end

  describe "verify/2" do
    test "returns error for commit without attestation" do
      assert {:error, :no_attestation} =
               Attestation.verify("nonexistent", repo_path: "/nonexistent")
    end
  end
end

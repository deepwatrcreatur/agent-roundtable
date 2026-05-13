defmodule Roundtable.Provenance.Gpg do
  @moduledoc """
  Wraps GPG CLI for agent signing and verification.
  """

  alias Roundtable.SystemCmdRunner

  @doc """
  Signs the given binary content using the agent's key.
  Returns a detached ASCII-armored signature.
  """
  def sign(agent_id, content, opts \\ []) do
    with {:ok, key_id} <- ensure_agent_key(agent_id, opts) do
      gpg(["--detach-sign", "--armor", "--local-user", key_id, "--batch", "--yes"], content, opts)
    end
  end

  @doc """
  Verifies a detached signature against content.
  """
  def verify(content, signature, opts \\ []) do
    # gpg --verify <sig_file> <content_file>
    # We use temp files for standard gpg verification flow
    tmp_content =
      Path.join(System.tmp_dir!(), "rt_verify_content_#{System.unique_integer([:positive])}")

    tmp_sig = Path.join(System.tmp_dir!(), "rt_verify_sig_#{System.unique_integer([:positive])}")

    File.write!(tmp_content, content)
    File.write!(tmp_sig, signature)

    result =
      case gpg(["--verify", tmp_sig, tmp_content], nil, opts) do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, {:verification_failed, reason}}
      end

    File.rm(tmp_content)
    File.rm(tmp_sig)
    result
  end

  defp ensure_agent_key(agent_id, opts) do
    # In v1, we check if a key for this agent already exists in the keyring.
    # If not, we could generate one or assume it's pre-provisioned.
    # For now, we'll try to find a key by the agent's ID (e.g. "gemini@roundtable.internal")
    email = "#{agent_id}@roundtable.internal"

    case gpg(["--list-keys", email], nil, opts) do
      {:ok, output} ->
        # Extract the Key ID from the output
        case Regex.run(~r/pub\s+.*\s+([0-9A-F]{8,})/, output) do
          [_, key_id] -> {:ok, key_id}
          nil -> {:error, {:key_not_found, email}}
        end

      _ ->
        {:error, {:key_not_found, email}}
    end
  end

  defp gpg(args, input, opts) do
    runner = Keyword.get(opts, :runner, SystemCmdRunner)
    gpg_bin = Keyword.get(opts, :gpg_bin, "gpg")
    repo_path = Keyword.get(opts, :repo_path, ".")

    exec_opts = [cd: repo_path, stderr_to_stdout: true]
    exec_opts = if input, do: Keyword.put(exec_opts, :input, input), else: exec_opts

    case runner.cmd(gpg_bin, args, exec_opts) do
      {output, 0} -> {:ok, output}
      {output, status} -> {:error, {:command_failed, status, output}}
    end
  end
end

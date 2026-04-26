defmodule Roundtable.Actions.RunCliAgent do
  use Jido.Action,
    name: "run_cli_agent",
    description: "Invokes a CLI agent (claude, codex, gemini) headlessly",
    schema: [
      agent: [type: {:in, [:claude, :codex, :gemini]}, required: true, doc: "The agent to invoke"],
      prompt: [type: :string, required: true, doc: "The prompt to send to the agent"],
      repo_root: [type: :string, required: true, doc: "The working directory for the command"],
      cli_path: [type: :string, required: false, doc: "Optional path to the CLI binary"]
    ]

  alias Roundtable.SystemCmdRunner

  @impl true
  def run(params, _context) do
    {cmd, args, exec_opts} = build_command(params)
    runner = Roundtable.SystemCmdRunner

    case runner.cmd(cmd, args, exec_opts) do
      {stdout, 0} -> {:ok, %{stdout: stdout}}
      {stdout, status} -> {:error, {:command_failed, status, stdout}}
    end
  end

  defp build_command(%{agent: :claude, prompt: prompt, repo_root: root} = params) do
    cmd = params[:cli_path] || "claude"
    args = ["-p", "--output-format", "json", prompt]
    {cmd, args, [cd: root, stderr_to_stdout: true]}
  end

  defp build_command(%{agent: :codex, prompt: prompt, repo_root: root} = params) do
    cmd = params[:cli_path] || "codex"
    # codex exec - reads from stdin
    args = ["exec", "-", "--json"]
    {cmd, args, [cd: root, input: prompt, stderr_to_stdout: true]}
  end

  defp build_command(%{agent: :gemini, prompt: prompt, repo_root: root} = params) do
    cmd = params[:cli_path] || "gemini"
    args = ["-p", prompt, "--output-format", "json"]
    {cmd, args, [cd: root, stderr_to_stdout: true]}
  end
end

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

  @impl true
  def run(params, _context) do
    runner = Map.get(params, :runner) ||
             Application.get_env(:roundtable, :cmd_runner, Roundtable.SystemCmdRunner)

    case build_command(params) do
      {:ok, {cmd, args, exec_opts, tmp}} ->
        result =
          case runner.cmd(cmd, args, exec_opts) do
            {stdout, 0} -> {:ok, %{stdout: stdout}}
            {stdout, status} -> {:error, {:command_failed, status, stdout}}
          end

        File.rm(tmp)
        result

      {:ok, {cmd, args, exec_opts}} ->
        case runner.cmd(cmd, args, exec_opts) do
          {stdout, 0} -> {:ok, %{stdout: stdout}}
          {stdout, status} -> {:error, {:command_failed, status, stdout}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_command(%{agent: :claude, prompt: prompt, repo_root: root} = params) do
    cmd = params[:cli_path] || "claude"
    args = ["-p", "--output-format", "json", prompt]
    {:ok, {cmd, args, [cd: root, stderr_to_stdout: true]}}
  end

  defp build_command(%{agent: :codex, prompt: prompt, repo_root: root} = params) do
    # System.cmd/3 has no :input option for stdin. Write prompt to a temp file
    # and pass the path; codex exec accepts a filename in place of -.
    tmp = Path.join(System.tmp_dir!(), "rt_prompt_#{System.unique_integer([:positive, :monotonic])}.txt")

    case File.write(tmp, prompt) do
      :ok ->
        cmd = params[:cli_path] || "codex"
        args = ["exec", tmp, "--json"]
        {:ok, {cmd, args, [cd: root, stderr_to_stdout: true], tmp}}

      {:error, reason} ->
        {:error, {:tmp_file_write_failed, reason}}
    end
  end

  defp build_command(%{agent: :gemini, prompt: prompt, repo_root: root} = params) do
    cmd = params[:cli_path] || "gemini"
    args = ["-p", prompt, "--output-format", "json"]
    {:ok, {cmd, args, [cd: root, stderr_to_stdout: true]}}
  end
end

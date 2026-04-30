defmodule Roundtable.Actions.RunCliAgent do
  use Jido.Action,
    name: "run_cli_agent",
    description: "Invokes a CLI agent (claude, codex, gemini, deepseek) headlessly",
    schema: [
      agent: [
        type: {:in, [:claude, :codex, :gemini, :deepseek]},
        required: true,
        doc: "The agent to invoke"
      ],
      prompt: [type: :string, required: true, doc: "The prompt to send to the agent"],
      repo_root: [type: :string, required: true, doc: "The working directory for the command"],
      cli_path: [type: :string, required: false, doc: "Optional path to the CLI binary"],
      deepseek_model: [
        type: :string,
        required: false,
        doc: "DeepSeek model ID (default: deepseek-chat). Use deepseek-reasoner for R1."
      ]
    ]

  @deepseek_api_url "https://api.deepseek.com/v1/chat/completions"
  @deepseek_default_model "deepseek-chat"

  @impl true
  def run(%{agent: :deepseek, prompt: prompt} = params, _context) do
    run_deepseek(prompt, params)
  end

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

  # ------------------------------------------------------------------
  # DeepSeek — direct HTTP (no CLI dependency)
  # ------------------------------------------------------------------

  defp run_deepseek(prompt, params) do
    case params[:api_key] || System.get_env("DEEPSEEK_API_KEY") do
      nil ->
        {:error, :deepseek_api_key_missing}

      api_key ->
        model = params[:deepseek_model] ||
                Application.get_env(:roundtable, :deepseek_model, @deepseek_default_model)

        case Req.post(@deepseek_api_url,
               json: %{
                 model: model,
                 messages: [%{role: "user", content: prompt}],
                 max_tokens: 2048
               },
               headers: [{"Authorization", "Bearer #{api_key}"}],
               receive_timeout: 120_000
             ) do
          {:ok, %{status: 200, body: resp}} ->
            text = get_in(resp, ["choices", Access.at(0), "message", "content"]) || ""
            {:ok, %{stdout: text}}

          {:ok, %{status: status, body: resp}} ->
            {:error, {:deepseek_api_error, status, resp}}

          {:error, reason} ->
            {:error, {:deepseek_http_error, reason}}
        end
    end
  end

  # ------------------------------------------------------------------
  # CLI agent command builders
  # ------------------------------------------------------------------

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

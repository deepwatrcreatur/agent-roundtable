# Run with:
#   nix develop -c mix run scripts/run_eval_batch_1.exs

# Add roundtable lib to path
Code.append_path("_build/dev/lib/roundtable/ebin")
# Note: we assume the app is already compiled and its deps are in the path.
# Since we are running via 'nix develop --command mix run', the environment will be ready.

alias Roundtable.Eval
alias Roundtable.Eval.Metrics

task_files = [
  "task-01.json",
  "task-02.json",
  "task-03.json",
  "task-06.json",
  "task-09.json",
  "task-11.json"
]

task_dir = "state/eval/tasks"

IO.puts("Starting Eval Batch 1")
IO.puts("---------------------")

results = Enum.map(task_files, fn file ->
  path = Path.join(task_dir, file)
  task = Jason.decode!(File.read!(path))

  IO.puts("\n[#{task["id"]}] #{task["question"]}")

  # 1. Run Vaglio
  IO.write("  -> vaglio... ")
  case Eval.run_vaglio(task["question"], task["brief_context"]) do
    {:ok, v_run} ->
      IO.write("computing metrics... ")
      {:ok, v_run} = Metrics.compute(v_run)
      IO.puts("done.")

      # 2. Run Single
      IO.write("  -> single structured... ")
      case Eval.run_single(task["question"], task["brief_context"], :structured) do
        {:ok, s_run} ->
          IO.write("computing metrics... ")
          {:ok, s_run} = Metrics.compute(s_run)
          IO.puts("done.")

          # 3. Blind Compare
          IO.write("  -> blind compare... ")
          {:ok, blind_dir} = Eval.blind_compare(v_run, s_run)
          IO.puts("saved to #{blind_dir}")

          %{task_id: task["id"], vaglio: v_run, single: s_run}

        {:error, reason} ->
          IO.puts("FAILED: #{inspect(reason)}")
          nil
      end

    {:error, reason} ->
      IO.puts("FAILED: #{inspect(reason)}")
      nil
  end
end)
|> Enum.reject(&is_nil/1)

IO.puts("\n=== Batch 1 Summary ===\n")

IO.puts("| Task | Vaglio Tokens | Single Tokens | Vaglio Considerations | Single Considerations |")
IO.puts("|---|---|---|---|---|")

Enum.each(results, fn r ->
  v = r.vaglio
  s = r.single
  vm = v.metrics
  sm = s.metrics
  IO.puts("| #{r.task_id} | #{v.tokens_used} | #{s.tokens_used} | #{vm.consideration_count} | #{sm.consideration_count} |")
end)

IO.puts("\nReady for blind review.")

defmodule Roundtable.Backup.SovereignSync do
  @moduledoc """
  Automates nightly backups of Dolt database and Git/JJ history to Mega S4.
  """

  use GenServer
  require Logger

  @nightly_interval_ms 24 * 60 * 60 * 1000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    enabled? = Keyword.get(opts, :enabled, false)
    if enabled?, do: schedule_sync()
    {:ok, %{repo_path: Keyword.get(opts, :repo_path)}}
  end

  @impl true
  def handle_info(:sync, state) do
    Logger.info("Starting sovereign backup sync to Mega S4...")

    with :ok <- dolt_push(state.repo_path),
         :ok <- rclone_sync(state.repo_path) do
      Logger.info("Sovereign backup sync complete.")
    else
      {:error, reason} ->
        Logger.error("Sovereign backup sync failed: #{inspect(reason)}")
    end

    schedule_sync()
    {:noreply, state}
  end

  defp dolt_push(repo_path) do
    # dolt push mega
    case System.cmd("dolt", ["push", "mega"], cd: repo_path, stderr_to_stdout: true) do
      {_, 0} -> :ok
      {out, status} -> {:error, {:dolt_push_failed, status, out}}
    end
  end

  defp rclone_sync(repo_path) do
    # rclone sync <repo_path> mega:roundtable/backups/
    # We assume rclone is configured with a 'mega' remote.
    case System.cmd("rclone", ["sync", repo_path, "mega:roundtable/backups/"], stderr_to_stdout: true) do
      {_, 0} -> :ok
      {out, status} -> {:error, {:rclone_sync_failed, status, out}}
    end
  end

  defp schedule_sync do
    # Trigger at next midnight, but for v1 we'll just use a simple interval
    Process.send_after(self(), :sync, @nightly_interval_ms)
  end
end

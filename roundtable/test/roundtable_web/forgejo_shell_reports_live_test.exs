defmodule RoundtableWeb.ForgejoShellReportsLiveTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest

  @endpoint RoundtableWeb.Endpoint

  setup_all do
    case start_supervised(RoundtableWeb.Endpoint) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  setup do
    previous = Application.get_env(:roundtable, RoundtableWeb.ForgejoShellReportsLive, [])
    Application.put_env(:roundtable, RoundtableWeb.ForgejoShellReportsLive, timeout_ms: 1, ttl_ms: 1)

    on_exit(fn ->
      Application.put_env(:roundtable, RoundtableWeb.ForgejoShellReportsLive, previous)
    end)

    :ok
  end

  test "renders the reports page" do
    conn = get(build_conn(), "/forgejo-shell/reports")
    html = html_response(conn, 200)

    assert html =~ "Public Repo Snapshot Reports"
    assert html =~ "Available Reports"
    assert html =~ "forgejo/forgejo"
    assert html =~ "kubernetes/kubernetes"
    assert html =~ "NixOS/nixpkgs"
    assert html =~ "Back to live demo"
  end
end

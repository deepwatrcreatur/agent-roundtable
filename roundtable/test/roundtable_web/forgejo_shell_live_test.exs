defmodule RoundtableWeb.ForgejoShellLiveTest do
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

  test "renders the forgejo shell page" do
    conn = get(build_conn(), "/forgejo-shell")
    html = html_response(conn, 200)

    assert html =~ "/vendor/phoenix/phoenix.min.js"
    assert html =~ "/vendor/phoenix_live_view/phoenix_live_view.min.js"
    assert html =~ "Deepwater Roundtable"
    assert html =~ "Roundtable Dashboard · discussion ops"
    assert html =~ "Forgejo Demo Shell · investor demo"
    assert html =~ "Forgejo Code Server Shell"
    assert html =~ "Curated Investor Demos"
    assert html =~ "NixOS/nixpkgs"
    assert html =~ "Investor Dashboard"
    assert html =~ "Maintainer concentration"
    assert html =~ "JJ vs Git Infrastructure Benchmark"
    assert html =~ "Concurrent changes"
    assert html =~ "jj-native core"
    assert html =~ "Reuse vs Replace Boundary"
    assert html =~ "Vaglio Analysis Surface"
    assert html =~ "vaglio-demos/nixpkgs"
  end
end

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
    assert html =~ "Vaglio Demo Home"
    assert html =~ "Forgejo Demo Shell"
    assert html =~ "Roundtable Ops"
    assert html =~ "Forgejo Code Server Shell"
    assert html =~ "Public demo shell"
    assert html =~ "Start with this demo"
    assert html =~ "Recommended first view"
    assert html =~ "Recommended first click"
    assert html =~ "Curated Investor Demos"
    assert html =~ "forgejo/forgejo"
    assert html =~ "Investor Dashboard"
    assert html =~ "Maintainer concentration"
    assert html =~ "Stress &amp; Change Heat"
    assert html =~ "Derived from sampled branch history"
    assert html =~ "Sampled commits"
    assert html =~ "sampled branch concentration"
    assert html =~ "sampled"
    assert html =~ "Sampled Repo Evidence"
    assert html =~ "Top sampled contributors"
    assert html =~ "Recent sampled commits"
    assert html =~ "Commits"
    assert html =~ "Branch stress"
    assert html =~ "History heat timeline"
    assert html =~ "JJ vs Git Infrastructure Benchmark"
    assert html =~ "Concurrent changes"
    assert html =~ "jj-native core"
    assert html =~ "Reuse vs Replace Boundary"
    assert html =~ "Vaglio Analysis Surface"
    assert html =~ "vaglio-demos/forgejo"
    assert html =~ "Advanced Prototype Source Controls"
  end
end

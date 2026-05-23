defmodule RoundtableWeb.NavigationTest do
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

  test "landing page exposes the shareable demo entry" do
    conn = get(build_conn(), "/")
    html = html_response(conn, 200)

    assert html =~ "Deepwater Roundtable"
    assert html =~ "Vaglio Demo Home"
    assert html =~ "Forgejo Demo Shell"
    assert html =~ "Board"
    assert html =~ "Roundtable Ops"
    assert html =~ "Forgejo outside."
    assert html =~ "Open Recommended Demo"
    assert html =~ "href=\"/board\""
    assert html =~ "href=\"/forgejo-shell\""
  end

  test "roundtable dashboard lives at /roundtable" do
    conn = get(build_conn(), "/roundtable")
    html = html_response(conn, 200)

    assert html =~ "Deepwater Roundtable"
    assert html =~ "Vaglio Demo Home"
    assert html =~ "Forgejo Demo Shell"
    assert html =~ "Board"
    assert html =~ "Roundtable Ops"
    assert html =~ "href=\"/board\""
    assert html =~ "Inject Question"
  end

  test "forgejo shell includes shared navigation" do
    conn = get(build_conn(), "/forgejo-shell")
    html = html_response(conn, 200)

    assert html =~ "Deepwater Roundtable"
    assert html =~ "Vaglio Demo Home"
    assert html =~ "Forgejo Demo Shell"
    assert html =~ "Board"
    assert html =~ "Roundtable Ops"
    assert html =~ "href=\"/board\""
    assert html =~ "href=\"/roundtable\""
  end
end

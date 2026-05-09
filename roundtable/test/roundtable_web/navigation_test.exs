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

  test "roundtable dashboard includes shared navigation" do
    conn = get(build_conn(), "/")
    html = html_response(conn, 200)

    assert html =~ "Deepwater Roundtable"
    assert html =~ "Roundtable Dashboard · discussion ops"
    assert html =~ "Forgejo Demo Shell · investor demo"
    assert html =~ "href=\"/forgejo-shell\""
  end

  test "forgejo shell includes shared navigation" do
    conn = get(build_conn(), "/forgejo-shell")
    html = html_response(conn, 200)

    assert html =~ "Deepwater Roundtable"
    assert html =~ "Roundtable Dashboard · discussion ops"
    assert html =~ "Forgejo Demo Shell · investor demo"
    assert html =~ "href=\"/\""
  end
end

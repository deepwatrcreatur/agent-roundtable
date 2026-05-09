defmodule RoundtableWeb.ForgejoShellLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest

  @endpoint RoundtableWeb.Endpoint

  setup_all do
    start_supervised!(RoundtableWeb.Endpoint)
    :ok
  end

  test "renders the forgejo shell page" do
    conn = get(build_conn(), "/forgejo-shell")
    html = html_response(conn, 200)

    assert html =~ "Forgejo Code Server Shell"
    assert html =~ "Curated Investor Demos"
    assert html =~ "NixOS/nixpkgs"
    assert html =~ "Investor Dashboard"
    assert html =~ "Maintainer concentration"
    assert html =~ "Reuse vs Replace Boundary"
    assert html =~ "Vaglio Analysis Surface"
    assert html =~ "vaglio-demos/nixpkgs"
  end
end

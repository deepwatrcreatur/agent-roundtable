defmodule RoundtableWeb.LayoutsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias RoundtableWeb.Layouts

  test "root layout renders inner content once in the body" do
    html = render_component(&Layouts.root/1, %{inner_content: "marker-content"})

    assert html =~ "<body>"
    assert length(Regex.scan(~r/marker-content/, html)) == 1
  end
end

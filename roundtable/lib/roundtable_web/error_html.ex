defmodule RoundtableWeb.ErrorHTML do
  use Phoenix.Component

  def render("401.html", _assigns), do: "Unauthorized"
  def render("404.html", _assigns), do: "Page not found"
  def render("500.html", _assigns), do: "Internal server error"

  def render(_template, _assigns) do
    "Something went wrong"
  end
end

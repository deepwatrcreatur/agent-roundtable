defmodule RoundtableWeb.DiscussionLiveTest do
  use RoundtableWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  defmodule StubCli do
    def get_discussion_state(_repo) do
      {:ok,
       %{
         12 => %{
           title: "Q12 test question",
           state: :open,
           labels: ["roundtable", "needs-more-evidence"],
           comment_count: 0,
           satisfaction: :needs_more_evidence,
           url: "https://example.test/issues/12"
         }
       }}
    end

    def inject_question(_repo, _text), do: {:ok, 13}

    def start_discussion(_brief_path, _opts), do: {:error, :boom}
  end

  setup do
    start_supervised!(RoundtableWeb.Endpoint)

    previous = Application.get_env(:roundtable, RoundtableWeb.DiscussionLive, [])
    Application.put_env(:roundtable, RoundtableWeb.DiscussionLive, cli_module: StubCli)

    prev_repo = System.get_env("ROUNDTABLE_REPO")
    prev_brief = System.get_env("ROUNDTABLE_BRIEF")
    System.put_env("ROUNDTABLE_REPO", "owner/repo")
    System.put_env("ROUNDTABLE_BRIEF", "docs/design/BRIEF.md")

    on_exit(fn ->
      Application.put_env(:roundtable, RoundtableWeb.DiscussionLive, previous)
      restore_env("ROUNDTABLE_REPO", prev_repo)
      restore_env("ROUNDTABLE_BRIEF", prev_brief)
    end)

    :ok
  end

  test "trigger round reports failure instead of success", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, RoundtableWeb.DiscussionLive)
    assert html =~ "Q12 test question"

    render_click(view, "trigger_round")
    html = wait_for(fn -> render(view) end)

    assert html =~ "Round failed: :boom"
    refute html =~ "Round complete"
  end

  defp wait_for(fun, attempts \\ 20)

  defp wait_for(fun, 0), do: fun.()

  defp wait_for(fun, attempts) do
    html = fun.()

    if html =~ "Round failed: :boom" do
      html
    else
      Process.sleep(10)
      wait_for(fun, attempts - 1)
    end
  end

  defp restore_env(key, nil), do: System.delete_env(key)

  defp restore_env(key, value), do: System.put_env(key, value)
end

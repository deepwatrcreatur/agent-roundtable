defmodule RoundtableWeb.DiscussionLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias RoundtableWeb.DiscussionLive

  test "select_candidate_repo populates repo and discussion path" do
    socket =
      %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}}}
      |> assign(:candidate_repos, [
        %{
          slug: "deepwatrcreatur/agent-roundtable",
          description: "Roundtable repo",
          private: false,
          url: "https://github.com/deepwatrcreatur/agent-roundtable",
          topics: ["discussion", "embedded"]
        }
      ])
      |> assign(:repo, "")
      |> assign(:discussion_path, "")
      |> assign(:source_mode, "brief")
      |> assign(:local_path, "")
      |> assign(:questions, %{})
      |> assign(:conflicts, [])

    assert {:noreply, updated} =
             DiscussionLive.handle_event(
               "select_candidate_repo",
               %{"repo" => "deepwatrcreatur/agent-roundtable"},
               socket
             )

    assert updated.assigns.repo == "deepwatrcreatur/agent-roundtable"
    assert updated.assigns.discussion_path == "docs/design"
    assert updated.assigns.source_mode == "repo"
    assert updated.assigns.flash_msg == "Selected deepwatrcreatur/agent-roundtable"
  end

  test "render explains discussion path and local checkout roles" do
    assigns = %{
      __changed__: %{},
      repo: "deepwatrcreatur/agent-roundtable",
      brief_path: "docs/design/BRIEF.md",
      local_path: "/tmp/agent-roundtable",
      discussion_path: "docs/design",
      source_mode: "repo",
      candidate_repos: [
        %{
          slug: "deepwatrcreatur/agent-roundtable",
          description: "Roundtable repo",
          private: false,
          url: "https://github.com/deepwatrcreatur/agent-roundtable",
          topics: ["discussion", "embedded"]
        }
      ],
      inject_text: "",
      running: false,
      flash_msg: nil,
      conflicts: [],
      questions: %{},
      robustness_meters: %{},
      low_robustness_history: [],
      integrity_scorecard: %{},
      red_team_only: false,
      red_team_views: %{},
      provenance_views: %{},
      anchor_statuses: %{},
      maintainer_options: ["maintainer@example.com"],
      selected_maintainer: "maintainer@example.com"
    }

    html =
      assigns
      |> DiscussionLive.render()
      |> rendered_to_string()

    assert html =~ "Active discussion target"
    assert html =~ "Discussion path:"

    assert html =~
             "The remote repo where roundtable files and issue-backed discussion state live."

    assert html =~ "Optional folder inside the discussion repo"
    assert html =~ "Local clone used for conflict inspection and resolve actions."
    assert html =~ "does not decide which remote repo receives discussion updates"
  end
end

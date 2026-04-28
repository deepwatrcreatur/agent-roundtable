defmodule Roundtable.Actions.Gh.CommentIssue do
  use Jido.Action,
    name: "comment_github_issue",
    description: "Adds a comment to a GitHub issue",
    schema: [
      number: [type: :integer, required: true, doc: "The issue number"],
      body: [type: :string, required: true, doc: "The comment body"],
      repo: [type: :string, required: false, doc: "Optional repository name (owner/repo)"],
      gh_bin: [type: :string, default: "gh", doc: "Path to gh binary"]
    ]

  alias Roundtable.Actions.Gh

  @impl true
  def run(params, _context) do
    config = %{
      repo: params[:repo],
      gh_bin: params[:gh_bin]
    }

    case Gh.comment_issue(params[:number], params[:body], config) do
      :ok -> {:ok, %{status: "commented"}}
      {:error, reason} -> {:error, reason}
    end
  end
end

defmodule Roundtable.Actions.Gh.ViewIssue do
  use Jido.Action,
    name: "view_github_issue",
    description: "Fetches details of a GitHub issue including comments",
    schema: [
      number: [type: :integer, required: true, doc: "The issue number"],
      repo: [type: :string, required: false, doc: "Optional repository name (owner/repo)"],
      fields: [type: {:list, :string}, required: false, doc: "Fields to fetch via --json"],
      gh_bin: [type: :string, default: "gh", doc: "Path to gh binary"]
    ]

  alias Roundtable.Actions.Gh

  @impl true
  def run(params, _context) do
    config = %{
      repo: params[:repo],
      gh_bin: params[:gh_bin]
    }

    opts = if params[:fields], do: [fields: params[:fields]], else: []

    case Gh.view_issue(params[:number], opts, config) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end
end

defmodule Roundtable.Actions.Gh.SetLabels do
  use Jido.Action,
    name: "set_github_issue_labels",
    description: "Adds and/or removes labels from a GitHub issue",
    schema: [
      number: [type: :integer, required: true, doc: "The issue number"],
      add: [type: {:list, :string}, default: [], doc: "Labels to add"],
      remove: [type: {:list, :string}, default: [], doc: "Labels to remove"],
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

    case Gh.edit_issue_labels(params[:number], params[:add], params[:remove], config) do
      :ok -> {:ok, %{status: "labels_updated"}}
      {:error, reason} -> {:error, reason}
    end
  end
end

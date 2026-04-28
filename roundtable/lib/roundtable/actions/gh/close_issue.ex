defmodule Roundtable.Actions.Gh.CloseIssue do
  use Jido.Action,
    name: "close_github_issue",
    description: "Closes a GitHub issue with an optional reason and comment",
    schema: [
      number: [type: :integer, required: true, doc: "The issue number"],
      reason: [type: :string, required: false, doc: "Close reason (completed/not_planned)"],
      comment: [type: :string, required: false, doc: "Optional closing comment"],
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

    opts = []
    opts = if params[:reason], do: [{:reason, params[:reason]} | opts], else: opts
    opts = if params[:comment], do: [{:comment, params[:comment]} | opts], else: opts

    case Gh.close_issue(params[:number], opts, config) do
      :ok -> {:ok, %{status: "closed"}}
      {:error, reason} -> {:error, reason}
    end
  end
end

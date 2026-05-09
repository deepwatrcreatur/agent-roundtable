defmodule Roundtable.ForgejoShell do
  @moduledoc """
  Builds the first Forgejo-based "code server shell" model for Vaglio.

  The shell is intentionally thin: Forgejo owns the Git-facing repository
  surface, while Vaglio exposes a `jj`-first analysis layer alongside it.
  """

  alias Roundtable.Adapters.Forgejo
  alias Roundtable.DiscussionRepo
  alias Roundtable.Translation.GitToJj

  @default_base_url "https://codeberg.org"
  @default_repo_slug "forgejo/forgejo"
  @default_branch "main"
  @default_head_ref "feature/vaglio-prototype"
  @default_commit_sha "deadbeef"
  @default_merge_strategy :merge
  @default_pr_number 67

  @type options :: keyword() | map()

  @spec build(options()) :: {:ok, map()} | {:error, term()}
  def build(opts \\ []) do
    options = normalize_options(opts)
    base_url = fetch_string(options, :base_url, @default_base_url)
    repo_slug = fetch_string(options, :repo_slug, @default_repo_slug)
    default_branch = fetch_string(options, :default_branch, @default_branch)
    head_ref = fetch_string(options, :head_ref, @default_head_ref)
    commit_sha = fetch_string(options, :commit_sha, @default_commit_sha)
    title = fetch_string(options, :pull_title, "Vaglio prototype shell")
    pr_number = fetch_integer(options, :pull_number, @default_pr_number)

    with :ok <- validate_base_url(base_url),
         :ok <- validate_repo_slug(repo_slug),
         {:ok, commit_projection} <- GitToJj.commit_to_revset(commit_sha),
         {:ok, branch_projection} <- GitToJj.ref_to_bookmark("refs/heads/" <> default_branch),
         {:ok, review_projection} <-
           GitToJj.pull_request_to_change(%{
             number: pr_number,
             head_ref: head_ref,
             base_ref: default_branch,
             title: title,
             state: :open
           }),
         {:ok, merge_projection} <-
           GitToJj.merge_event_to_bookmark_move(%{
             base_ref: default_branch,
             merged_commit_sha: commit_sha,
             strategy: fetch_strategy(options, :merge_strategy, @default_merge_strategy),
             pull_request_number: pr_number
           }) do
      repo = build_repo_model(base_url, repo_slug, default_branch)

      {:ok,
       %{
         repo: repo,
         discussion_repo:
           DiscussionRepo.new(repo_slug,
             backend: Forgejo,
             config: %{base_url: base_url}
           ),
         navigation: [
           %{label: "Forgejo repository", href: repo.repo_url},
           %{label: "Forgejo pull requests", href: repo.pulls_url},
           %{label: "Vaglio roundtable dashboard", href: "/"},
           %{label: "Vaglio analysis surface", href: "/forgejo-shell#analysis-surface"}
         ],
         boundaries: boundaries(),
         analysis: %{
           branch_projection: branch_projection,
           commit_projection: commit_projection,
           review_projection: review_projection,
           merge_projection: merge_projection
         },
         extension_seams: extension_seams()
       }}
    end
  end

  @spec defaults() :: map()
  def defaults do
    %{
      base_url: @default_base_url,
      repo_slug: @default_repo_slug,
      default_branch: @default_branch,
      head_ref: @default_head_ref,
      commit_sha: @default_commit_sha,
      merge_strategy: @default_merge_strategy,
      pull_number: @default_pr_number,
      pull_title: "Vaglio prototype shell"
    }
  end

  defp build_repo_model(base_url, repo_slug, default_branch) do
    root = String.trim_trailing(base_url, "/") <> "/" <> repo_slug

    %{
      slug: repo_slug,
      base_url: base_url,
      default_branch: default_branch,
      repo_url: root,
      tree_url: root <> "/src/branch/" <> default_branch,
      pulls_url: root <> "/pulls",
      issues_url: root <> "/issues",
      clone_url: root <> ".git"
    }
  end

  defp boundaries do
    [
      %{
        capability: "Repository browsing",
        owner: :forgejo,
        seam: "Use Forgejo's repo, tree, issue, and pull-request UI unchanged."
      },
      %{
        capability: "User and session management",
        owner: :forgejo,
        seam:
          "Reuse Forgejo authentication and session handling instead of building a parallel account system."
      },
      %{
        capability: "Web chrome",
        owner: :forgejo,
        seam:
          "Treat Vaglio as an adjacent panel or sidecar surface, not a hard fork of Forgejo chrome."
      },
      %{
        capability: "Webhook ingress",
        owner: :forgejo,
        seam:
          "Let Forgejo emit Git-shaped events while Vaglio translates them at the gateway boundary."
      },
      %{
        capability: "Analysis and deliberation",
        owner: :vaglio,
        seam: "Keep the internal source of truth `jj`-first behind the Git↔jj translation layer."
      }
    ]
  end

  defp extension_seams do
    [
      %{
        surface: "Git edge",
        module: "Roundtable.Adapters.Forgejo",
        role: "Reads and writes discussion repos against Forgejo's API."
      },
      %{
        surface: "Semantic gateway",
        module: "Roundtable.Translation.GitToJj",
        role:
          "Maps Git refs, pull requests, commits, and merges into `jj`-native analysis objects."
      },
      %{
        surface: "Vaglio analysis UI",
        module: "RoundtableWeb.DiscussionLive",
        role:
          "Hosts the existing roundtable dashboard without requiring Git to become the internal source of truth."
      }
    ]
  end

  defp normalize_options(opts) when is_list(opts), do: Map.new(opts)
  defp normalize_options(opts) when is_map(opts), do: opts

  defp fetch_string(options, key, default) do
    options
    |> Map.get(key, default)
    |> to_string()
    |> String.trim()
    |> case do
      "" -> default
      value -> value
    end
  end

  defp fetch_integer(options, key, default) do
    case Map.get(options, key, default) do
      value when is_integer(value) ->
        value

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {parsed, _} -> parsed
          :error -> default
        end

      _ ->
        default
    end
  end

  defp fetch_strategy(options, key, default) do
    case Map.get(options, key, default) do
      value when value in [:merge, :squash, :rebase] -> value
      "merge" -> :merge
      "squash" -> :squash
      "rebase" -> :rebase
      _ -> default
    end
  end

  defp validate_base_url("http://" <> _), do: :ok
  defp validate_base_url("https://" <> _), do: :ok
  defp validate_base_url(url), do: {:error, {:invalid_base_url, url}}

  defp validate_repo_slug(slug) do
    if Regex.match?(~r/\A[^\/\s]+\/[^\/\s]+\z/, slug) do
      :ok
    else
      {:error, {:invalid_repo_slug, slug}}
    end
  end
end

defmodule Roundtable.Translation.GitToJj do
  @moduledoc """
  Deterministic Git → `jj` translation rules for a Forgejo/Git-shaped edge.

  The key policy is that Git-facing concepts are projected into a dedicated
  `git/...` namespace instead of being treated as the canonical internal model.
  That keeps Vaglio free to remain `jj`-first internally while still exposing a
  stable compatibility boundary to Git-native tools and hosts such as Forgejo.

  ## Translation rules

  - `refs/heads/<branch>` ↔ `git/heads/<branch>`
  - `refs/tags/<tag>` ↔ `git/tags/<tag>` (read-only projection)
  - Git commit SHA → `jj` revset selector (`commit_id("<sha>")`)
  - Git pull request → `jj` change proposal envelope with explicit Git-derived
    bookmark projections
  - Git merge events → bookmark moves with surfaced lossiness for `squash` and
    `rebase` strategies
  """

  @type translation :: %{
          git: map(),
          jj: map(),
          provenance: %{
            translated_from: :git,
            lossy: boolean(),
            notes: [String.t()]
          }
        }

  @type merge_strategy :: :merge | :squash | :rebase

  @spec ref_to_bookmark(String.t()) :: {:ok, translation()} | {:error, term()}
  def ref_to_bookmark("refs/heads/" <> branch) when branch != "" do
    {:ok,
     %{
       git: %{kind: :branch_ref, ref: "refs/heads/" <> branch, branch: branch},
       jj: %{
         kind: :bookmark_projection,
         bookmark: "git/heads/" <> branch,
         writable: true
       },
       provenance: base_provenance()
     }}
  end

  def ref_to_bookmark("refs/tags/" <> tag) when tag != "" do
    {:ok,
     %{
       git: %{kind: :tag_ref, ref: "refs/tags/" <> tag, tag: tag},
       jj: %{
         kind: :bookmark_projection,
         bookmark: "git/tags/" <> tag,
         writable: false
       },
       provenance: %{
         translated_from: :git,
         lossy: false,
         notes: ["Git tags are projected as read-only bookmark aliases."]
       }
     }}
  end

  def ref_to_bookmark(ref) when is_binary(ref),
    do: {:error, {:unsupported_git_ref, ref}}

  @spec bookmark_to_ref(String.t()) :: {:ok, translation()} | {:error, term()}
  def bookmark_to_ref("git/heads/" <> branch) when branch != "" do
    {:ok,
     %{
       git: %{kind: :branch_ref, ref: "refs/heads/" <> branch, branch: branch},
       jj: %{kind: :bookmark_projection, bookmark: "git/heads/" <> branch, writable: true},
       provenance: base_provenance()
     }}
  end

  def bookmark_to_ref("git/tags/" <> tag) when tag != "" do
    {:ok,
     %{
       git: %{kind: :tag_ref, ref: "refs/tags/" <> tag, tag: tag},
       jj: %{kind: :bookmark_projection, bookmark: "git/tags/" <> tag, writable: false},
       provenance: %{
         translated_from: :git,
         lossy: false,
         notes: ["Tag projections remain read-only on the Git edge."]
       }
     }}
  end

  def bookmark_to_ref(bookmark) when is_binary(bookmark),
    do: {:error, {:unsupported_bookmark_projection, bookmark}}

  @spec commit_to_revset(String.t()) :: {:ok, translation()} | {:error, term()}
  def commit_to_revset(sha) when is_binary(sha) do
    normalized = String.trim(sha)

    cond do
      normalized == "" ->
        {:error, :empty_commit_id}

      not Regex.match?(~r/\A[0-9a-fA-F]{7,64}\z/, normalized) ->
        {:error, {:invalid_commit_id, sha}}

      true ->
        {:ok,
         %{
           git: %{kind: :commit, sha: normalized},
           jj: %{kind: :revset_selector, revset: ~s|commit_id("#{normalized}")|},
           provenance: %{
             translated_from: :git,
             lossy: false,
             notes: [
               "Git commit SHAs map to explicit `jj` revset selectors, not synthetic change IDs."
             ]
           }
         }}
    end
  end

  @spec pull_request_to_change(map()) :: {:ok, translation()} | {:error, term()}
  def pull_request_to_change(%{number: number, head_ref: head_ref, base_ref: base_ref} = pr)
      when is_integer(number) and number > 0 and is_binary(head_ref) and is_binary(base_ref) do
    title = Map.get(pr, :title) || Map.get(pr, "title")
    state = Map.get(pr, :state) || Map.get(pr, "state") || :open

    {:ok,
     %{
       git: %{
         kind: :pull_request,
         number: number,
         head_ref: head_ref,
         base_ref: base_ref,
         title: title,
         state: state
       },
       jj: %{
         kind: :change_proposal,
         change_key: "git/pr/#{number}",
         head_bookmark: "git/pr/#{number}/head",
         base_bookmark: "git/heads/" <> base_ref,
         source_branch_bookmark: "git/heads/" <> head_ref,
         review_state: normalize_review_state(state)
       },
       provenance: %{
         translated_from: :git,
         lossy: false,
         notes: [
           "Pull requests are projected as change proposals, not canonical internal review objects."
         ]
       }
     }}
  end

  def pull_request_to_change(pr), do: {:error, {:invalid_pull_request, pr}}

  @spec merge_event_to_bookmark_move(map()) :: {:ok, translation()} | {:error, term()}
  def merge_event_to_bookmark_move(
        %{
          base_ref: base_ref,
          merged_commit_sha: merged_commit_sha,
          strategy: strategy
        } = event
      )
      when is_binary(base_ref) and is_binary(merged_commit_sha) and
             strategy in [:merge, :squash, :rebase] do
    number = Map.get(event, :pull_request_number) || Map.get(event, "pull_request_number")

    {:ok,
     %{
       git: %{
         kind: :merge_event,
         base_ref: base_ref,
         merged_commit_sha: merged_commit_sha,
         strategy: strategy,
         pull_request_number: number
       },
       jj: %{
         kind: :bookmark_move,
         bookmark: "git/heads/" <> base_ref,
         target_revset: ~s|commit_id("#{merged_commit_sha}")|,
         merge_strategy: strategy
       },
       provenance: %{
         translated_from: :git,
         lossy: strategy in [:squash, :rebase],
         notes: merge_notes(strategy)
       }
     }}
  end

  def merge_event_to_bookmark_move(event), do: {:error, {:invalid_merge_event, event}}

  defp normalize_review_state(state) when state in [:open, :closed, :merged], do: state
  defp normalize_review_state("open"), do: :open
  defp normalize_review_state("closed"), do: :closed
  defp normalize_review_state("merged"), do: :merged
  defp normalize_review_state(_), do: :open

  defp merge_notes(:merge),
    do: ["Non-squash merges preserve Git edge ancestry most directly."]

  defp merge_notes(:squash) do
    [
      "Squash merges are lossy: multiple Git commits collapse into one promoted target.",
      "Keep the pull request envelope for provenance instead of pretending commit lineage survived intact."
    ]
  end

  defp merge_notes(:rebase) do
    [
      "Rebase merges are lossy: commit identities are rewritten on the Git edge.",
      "Use the change proposal key, not Git SHA identity alone, when reasoning across the boundary."
    ]
  end

  defp base_provenance do
    %{translated_from: :git, lossy: false, notes: []}
  end
end

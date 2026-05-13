defmodule Roundtable.Actions.DiscussionGit do
  @moduledoc """
  Orchestrator-facing interface for reading and writing discussion repo files.

  This module encodes the canonical discussion repo layout (Q23 / Protocol
  Update 10) so the orchestrator does not need to know file paths. All I/O is
  delegated to the `DiscussionRepo.Backend` configured on the repo struct —
  making the orchestrator backend-agnostic.

  This replaces `Roundtable.Actions.Gh` as the orchestrator's state medium.
  `Gh` is retained as an optional Issues overlay (when `issues_enabled: true`).

  ## Typical orchestrator usage

      repo = DiscussionRepo.new("owner/my-discussion")
      {:ok, config} = DiscussionGit.read_config(repo)
      {:ok, brief}  = DiscussionGit.read_brief(repo)

      # After IC closes round 3 on "q7":
      {:ok, repo}   = DiscussionGit.commit_round(repo, 3, "q7", round_content)
      {:ok, repo}   = DiscussionGit.append_decision(repo, decision_section)
  """

  alias Roundtable.DiscussionRepo

  @brief_path "BRIEF.md"
  @decision_path "DECISION.md"
  @config_path "roundtable.toml"
  @rounds_dir "rounds"

  # ----------------------------------------------------------------
  # Reads
  # ----------------------------------------------------------------

  @doc "Read `BRIEF.md` from the discussion repo."
  @spec read_brief(DiscussionRepo.t()) :: {:ok, binary()} | {:error, term()}
  def read_brief(%DiscussionRepo{} = repo),
    do: DiscussionRepo.read_file(repo, @brief_path)

  @doc """
  Read `DECISION.md` from the discussion repo.
  Returns `{:error, :not_found}` when the file does not yet exist.
  """
  @spec read_decision(DiscussionRepo.t()) :: {:ok, binary()} | {:error, :not_found | term()}
  def read_decision(%DiscussionRepo{} = repo) do
    case DiscussionRepo.read_file(repo, @decision_path) do
      {:ok, _} = ok -> ok
      {:error, {:api_failed, 404, _}} -> {:error, :not_found}
      {:error, _} = err -> err
    end
  end

  @doc """
  Parse `roundtable.toml` and return a config map.

  Keys: `:agents` (list of atoms), `:max_rounds`, `:coordinator`, `:issues_enabled`.
  """
  @spec read_config(DiscussionRepo.t()) :: {:ok, map()} | {:error, term()}
  def read_config(%DiscussionRepo{} = repo) do
    with {:ok, content} <- DiscussionRepo.read_file(repo, @config_path) do
      parse_toml(content)
    end
  end

  @doc """
  List round filenames in `rounds/`, sorted lexicographically.
  Returns `{:ok, []}` when the directory does not yet exist.
  """
  @spec list_rounds(DiscussionRepo.t()) :: {:ok, [String.t()]} | {:error, term()}
  def list_rounds(%DiscussionRepo{} = repo) do
    case DiscussionRepo.list_files(repo, @rounds_dir) do
      {:ok, names} -> {:ok, Enum.sort(names)}
      {:error, _} = err -> err
    end
  end

  @doc "Read the raw content of a specific round file by filename."
  @spec read_round(DiscussionRepo.t(), String.t()) :: {:ok, binary()} | {:error, term()}
  def read_round(%DiscussionRepo{} = repo, filename),
    do: DiscussionRepo.read_file(repo, "#{@rounds_dir}/#{filename}")

  # ----------------------------------------------------------------
  # Writes
  # ----------------------------------------------------------------

  @doc """
  Commit a new round file after the IC closes a round.

  `round_number` is a non-negative integer. `slug` is a short kebab-case label
  (e.g. `"q1-q3"`). The filename is zero-padded to two digits:
  `rounds/round-03-q7.md`.

  Returns `{:ok, updated_repo}` with any updated backend state (e.g. new head SHA).
  """
  @spec commit_round(DiscussionRepo.t(), non_neg_integer(), String.t(), binary()) ::
          {:ok, DiscussionRepo.t()} | {:error, term()}
  def commit_round(%DiscussionRepo{} = repo, round_number, slug, content) do
    filename = round_filename(round_number, slug)
    message = "discussion: close round #{round_number} (#{slug})"
    DiscussionRepo.write_file(repo, "#{@rounds_dir}/#{filename}", content, message)
  end

  @doc """
  Append `new_section` to `DECISION.md`, creating the file if it does not exist.

  Returns `{:ok, updated_repo}` or `{:error, reason}`.
  """
  @spec append_decision(DiscussionRepo.t(), binary()) ::
          {:ok, DiscussionRepo.t()} | {:error, term()}
  def append_decision(%DiscussionRepo{} = repo, new_section) do
    existing =
      case read_decision(repo) do
        {:ok, content} -> content
        {:error, :not_found} -> "# Decisions\n\n"
      end

    updated = existing <> "\n" <> new_section
    DiscussionRepo.write_file(repo, @decision_path, updated, "discussion: append decision entry")
  end

  # ----------------------------------------------------------------
  # Private helpers
  # ----------------------------------------------------------------

  defp round_filename(n, slug) do
    "round-#{String.pad_leading(Integer.to_string(n), 2, "0")}-#{slug}.md"
  end

  # Minimal regex-based TOML parser for the fixed roundtable.toml schema.
  # Replace with a proper TOML library if the schema grows significantly.
  defp parse_toml(content) do
    agents =
      case Regex.run(~r/agents\s*=\s*\[([^\]]+)\]/, content) do
        [_, list] ->
          list
          |> String.split(",")
          |> Enum.map(&(&1 |> String.trim() |> String.trim(~s(")) |> String.to_atom()))

        nil ->
          []
      end

    max_rounds =
      case Regex.run(~r/max_rounds\s*=\s*(\d+)/, content) do
        [_, n] -> String.to_integer(n)
        nil -> 5
      end

    coordinator =
      case Regex.run(~r/coordinator\s*=\s*"([^"]+)"/, content) do
        [_, c] -> String.to_atom(c)
        nil -> nil
      end

    issues_enabled =
      case Regex.run(~r/issues_enabled\s*=\s*(true|false)/, content) do
        [_, "true"] -> true
        _ -> false
      end

    {:ok,
     %{
       agents: agents,
       max_rounds: max_rounds,
       coordinator: coordinator,
       issues_enabled: issues_enabled
     }}
  end
end

defmodule Roundtable.DiscussionRepo do
  @moduledoc """
  Represents a repository-backed roundtable discussion.

  A discussion repo follows the canonical layout (Q23 / Protocol Update 10):

      roundtable.toml    — machine config: agents, max_rounds, coordinator
      BRIEF.md           — questions
      DECISION.md        — IC decisions written after each round closes
      rounds/            — one committed file per closed round
      .roundtable/state/ — transient RoundRun JSON snapshots (gitignored)

  ## Backend

  The `backend` field determines which `DiscussionRepo.Backend` implementation
  handles all I/O. Default is `Roundtable.Adapters.GitHub`. Swap to a stub
  in tests or to `Roundtable.Adapters.Forgejo` for a self-hosted deployment.

  ## Usage

      repo =
        DiscussionRepo.new("owner/my-discussion",
          token: System.get_env("GH_TOKEN"),
          backend: Roundtable.Adapters.Forgejo,
          config: %{base_url: "https://forgejo.example.org"}
        )

      {:ok, brief} = DiscussionRepo.read_file(repo, "BRIEF.md")
  """

  @type t :: %__MODULE__{
          gh_slug: String.t(),
          local_path: String.t() | nil,
          base_path: String.t() | nil,
          token: String.t() | nil,
          issues_enabled: boolean(),
          head_sha: String.t() | nil,
          backend: module(),
          config: map()
        }

  defstruct [
    :gh_slug,
    :local_path,
    :base_path,
    :token,
    :head_sha,
    issues_enabled: false,
    backend: Roundtable.Adapters.GitHub,
    config: %{}
  ]

  @doc """
  Build a `DiscussionRepo` from a repository slug (`"owner/repo"`).

  ## Options

  - `:token`          — API token; interpretation depends on the configured backend
  - `:local_path`     — local working-copy path (optional; used for git operations)
  - `:base_path`      — optional discussion root inside the repo (e.g. `docs/design`)
  - `:issues_enabled` — whether the GitHub Issues overlay is active (default `false`)
  - `:backend`        — the `Backend` module to use (default `Adapters.GitHub`)
  - `:config`         — backend-specific configuration map (e.g. Forgejo `:base_url`)
  """
  @spec new(String.t(), keyword()) :: t()
  def new(gh_slug, opts \\ []) do
    %__MODULE__{
      gh_slug: gh_slug,
      token: Keyword.get(opts, :token),
      local_path: Keyword.get(opts, :local_path),
      base_path: normalize_base_path(Keyword.get(opts, :base_path)),
      issues_enabled: Keyword.get(opts, :issues_enabled, false),
      head_sha: nil,
      backend: Keyword.get(opts, :backend, Roundtable.Adapters.GitHub),
      config: Keyword.get(opts, :config, %{})
    }
  end

  @doc "Read a file at `path` using the configured backend."
  @spec read_file(t(), String.t()) :: {:ok, binary()} | {:error, term()}
  def read_file(%__MODULE__{backend: backend} = repo, path),
    do: backend.read_file(repo, path)

  @doc "Write `content` to `path`, committing with `message`."
  @spec write_file(t(), String.t(), binary(), String.t()) ::
          {:ok, t()} | {:error, term()}
  def write_file(%__MODULE__{backend: backend} = repo, path, content, message),
    do: backend.write_file(repo, path, content, message)

  @doc "List entry names at `path` (non-recursive)."
  @spec list_files(t(), String.t()) :: {:ok, [String.t()]} | {:error, term()}
  def list_files(%__MODULE__{backend: backend} = repo, path),
    do: backend.list_files(repo, path)

  @doc "Return `true` if the repo contains a `roundtable.toml`."
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{backend: backend} = repo),
    do: backend.discussion_repo?(repo)

  defp normalize_base_path(nil), do: nil
  defp normalize_base_path(""), do: nil

  defp normalize_base_path(path) do
    path
    |> String.trim()
    |> String.trim("/")
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end
end

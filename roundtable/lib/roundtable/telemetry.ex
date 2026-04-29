defmodule Roundtable.Telemetry do
  @moduledoc """
  OpenTelemetry-shaped span taxonomy for Roundtable orchestrator events.

  All spans are emitted via `:telemetry.execute/3` so any downstream
  handler (OTEL exporter, logger, LiveView) can attach without coupling to
  a specific SDK.

  ## Span names (as `:telemetry` event names)

  | Span                          | When emitted                          |
  |-------------------------------|---------------------------------------|
  | `roundtable.issue.poll`       | `Gh.view_issue/3` call                |
  | `roundtable.agent.turn`       | `RunCliAgent.run/2` start             |
  | `roundtable.gh.comment`       | `Gh.comment_issue/3` call             |
  | `roundtable.satisfaction.parse` | after marker extraction             |
  | `roundtable.ic.triage`        | `triage_with_ic/5` call               |
  | `roundtable.consensus.check`  | `Satisfaction.consensus?/1` eval      |
  | `roundtable.issue.close`      | `Gh.close_issue/3` call               |
  | `roundtable.phase.transition` | every `RoundRun.put_phase/2` call     |

  ## Attaching a handler

  In `config/dev.exs`:

      config :roundtable, telemetry_handler: :json_logger

  The application start will call `Roundtable.Telemetry.attach_logger/0`
  when this is set, printing structured JSON to stdout.

  In production, attach an `opentelemetry_exporter` handler instead.
  See: https://hex.pm/packages/opentelemetry_exporter

  ## Example production wiring

      :telemetry.attach_many(
        "otel-exporter",
        Roundtable.Telemetry.all_events(),
        &MyApp.OtelHandler.handle_event/4,
        nil
      )
  """

  @issue_poll [:roundtable, :issue, :poll]
  @agent_turn [:roundtable, :agent, :turn]
  @gh_comment [:roundtable, :gh, :comment]
  @satisfaction_parse [:roundtable, :satisfaction, :parse]
  @ic_triage [:roundtable, :ic, :triage]
  @consensus_check [:roundtable, :consensus, :check]
  @issue_close [:roundtable, :issue, :close]
  @phase_transition [:roundtable, :phase, :transition]

  @doc "All eight event names — useful for bulk attach."
  def all_events do
    [
      @issue_poll,
      @agent_turn,
      @gh_comment,
      @satisfaction_parse,
      @ic_triage,
      @consensus_check,
      @issue_close,
      @phase_transition
    ]
  end

  # ------------------------------------------------------------------
  # Span emitters
  # ------------------------------------------------------------------

  @doc "Emitted when `Gh.view_issue/3` is called."
  def issue_poll(issue_number, gh_repo) do
    :telemetry.execute(@issue_poll, ts(), %{
      issue_number: issue_number,
      gh_repo: gh_repo
    })
  end

  @doc "Emitted at the start of a `RunCliAgent` invocation."
  def agent_turn(agent, issue_number, round) do
    :telemetry.execute(@agent_turn, ts(), %{
      agent: agent,
      issue_number: issue_number,
      round: round
    })
  end

  @doc "Emitted when `Gh.comment_issue/3` is called."
  def gh_comment(issue_number, agent, body_bytes) do
    :telemetry.execute(@gh_comment, ts(), %{
      issue_number: issue_number,
      agent: agent,
      body_bytes: body_bytes
    })
  end

  @doc """
  Emitted after satisfaction marker extraction.

  `method` is `:marker` when the regex matched, `:triage` when the IC
  classified the response.
  """
  def satisfaction_parse(agent, result, method) do
    :telemetry.execute(@satisfaction_parse, ts(), %{
      agent: agent,
      result: result,
      method: method
    })
  end

  @doc "Emitted when the IC triage call is made."
  def ic_triage(issue_number, result) do
    :telemetry.execute(@ic_triage, ts(), %{
      issue_number: issue_number,
      result: result
    })
  end

  @doc "Emitted when `Satisfaction.consensus?/1` is evaluated."
  def consensus_check(issue_number, labels, result) do
    :telemetry.execute(@consensus_check, ts(), %{
      issue_number: issue_number,
      labels: labels,
      result: result
    })
  end

  @doc "Emitted when `Gh.close_issue/3` is called."
  def issue_close(issue_number, round, reason) do
    :telemetry.execute(@issue_close, ts(), %{
      issue_number: issue_number,
      round: round,
      reason: reason
    })
  end

  @doc "Emitted on every `RoundRun.put_phase/2` transition."
  def phase_transition(issue_number, from_phase, to_phase) do
    :telemetry.execute(@phase_transition, ts(), %{
      issue_number: issue_number,
      from_phase: from_phase,
      to_phase: to_phase
    })
  end

  # ------------------------------------------------------------------
  # Dev JSON logger
  # ------------------------------------------------------------------

  @doc """
  Attaches a handler that prints each event as a structured JSON line to
  stdout. Intended for development; wire an OTEL exporter in production.
  """
  def attach_logger do
    :telemetry.attach_many(
      "roundtable-json-logger",
      all_events(),
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc false
  def handle_event(event, measurements, metadata, _config) do
    entry =
      metadata
      |> Map.new(fn
        {k, v} when is_atom(v) -> {k, Atom.to_string(v)}
        {k, v} when is_list(v) -> {k, Enum.map(v, &to_string/1)}
        kv -> kv
      end)
      |> Map.put(:event, Enum.join(event, "."))
      |> Map.put(:timestamp, DateTime.to_iso8601(DateTime.utc_now()))
      |> Map.put(:system_time, Map.get(measurements, :system_time))

    IO.puts(Jason.encode!(entry))
  end

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp ts, do: %{system_time: :erlang.system_time()}
end

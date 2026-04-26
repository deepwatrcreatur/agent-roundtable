defmodule Roundtable.Orchestrator do
  @moduledoc """
  Jido-backed roundtable orchestrator.
  """
  use Jido.Agent,
    name: "roundtable_orchestrator",
    description: "Orchestrates multi-agent design discussions over GitHub Issues",
    schema: [
      repo: [type: :string, required: true],
      brief_path: [type: :string, required: true],
      questions: [type: {:list, :map}, default: []],
      max_rounds: [type: :integer, default: 5]
    ]

  # In Jido 2.0, state transitions happen via Actions and cmd/2.
  # The Orchestrator agent will hold the state of the roundtable and
  # emit directives to perform side effects (GH calls, Agent calls).

  def initial_state(opts) do
    %{
      repo: opts[:repo],
      brief_path: opts[:brief_path],
      questions: opts[:questions], # List of %{id: "Q1", issue_number: 12, agents: [...], state: :open}
      max_rounds: opts[:max_rounds] || 5,
      current_round: 1
    }
  end

  # Orchestration logic will be implemented as Jido Actions that the agent executes.
end

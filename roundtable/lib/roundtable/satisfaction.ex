defmodule Roundtable.Satisfaction do
  @moduledoc """
  Satisfaction marker and label policy.
  """

  @markers [
    {"satisfied-conditional", "satisfied-conditional"},
    {"no objection", "no-objection"},
    {"satisfied", "satisfied"},
    {"needs more evidence", "needs-more-evidence"}
  ]

  @doc """
  Parses a response for satisfaction markers.
  Returns the corresponding label or nil if none found.

  Recognised markers (case-insensitive, whitespace-tolerant):
  - `[satisfied]` — agent actively agrees
  - `[satisfied-conditional: <condition>]` — agrees subject to a condition
  - `[no objection]` — no further evidence to add; not blocking closure;
    does not imply active agreement (Protocol Update 13)
  - `[needs more evidence: <what>]` — blocking; prevents consensus
  """
  def parse_marker(text) do
    Enum.find_value(@markers, fn {marker, label} ->
      pattern = ~r/\[\s*#{marker}.*?\]/i
      if Regex.run(pattern, text), do: label
    end)
  end

  @doc """
  Determines if a question should be closed based on labels.

  Consensus is reached when:
  - At least one agent is `satisfied` or `satisfied-conditional`
  - No agent has `needs-more-evidence`
  - `no-objection` is non-blocking (does not prevent closure) but
    does not count as positive satisfaction on its own
  """
  def consensus?(labels) do
    has_satisfied? = "satisfied" in labels or "satisfied-conditional" in labels
    has_blocking? = "needs-more-evidence" in labels

    has_satisfied? and not has_blocking?
  end
end

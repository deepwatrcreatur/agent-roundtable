defmodule Roundtable.Satisfaction do
  @moduledoc """
  Satisfaction marker and label policy.
  """

  @markers [
    {"satisfied", "satisfied"},
    {"satisfied-conditional", "satisfied-conditional"},
    {"needs more evidence", "needs-more-evidence"}
  ]

  @doc """
  Parses a response for satisfaction markers.
  Returns the corresponding label or nil if none found.
  """
  def parse_marker(text) do
    Enum.find_value(@markers, fn {marker, label} ->
      pattern = ~r/\[\s*#{marker}.*?\]/i
      if Regex.run(pattern, text), do: label
    end)
  end

  @doc """
  Determines if a question should be closed based on labels.
  """
  def consensus?(labels) do
    has_satisfied? = "satisfied" in labels or "satisfied-conditional" in labels
    has_blocking? = "needs-more-evidence" in labels

    has_satisfied? and not has_blocking?
  end
end

defmodule Roundtable.ProvenanceTest do
  use ExUnit.Case, async: true

  alias Roundtable.Provenance

  test "parses provenance-tagged claims with optional details" do
    text = """
    The repo uses Nix [observed: cat flake.nix]
    Codex already noted this [testimony]
    Therefore the UI should stay incremental [inferred: avoid a rewrite]
    """

    claims = Provenance.parse_claims(text, :codex)

    assert [
             %{claim: "The repo uses Nix", tag: :observed, detail: "cat flake.nix", agent: :codex},
             %{claim: "Codex already noted this", tag: :testimony, detail: nil, agent: :codex},
             %{
               claim: "Therefore the UI should stay incremental",
               tag: :inferred,
               detail: "avoid a rewrite",
               agent: :codex
             }
           ] = claims
  end
end

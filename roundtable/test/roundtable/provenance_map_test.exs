defmodule Roundtable.ProvenanceMapTest do
  use ExUnit.Case, async: true

  alias Roundtable.ProvenanceMap

  test "parses observed, testimony, and inferred claims into an evidence map and chain" do
    questions = %{
      44 => %{
        title: "Q44 — Provenance demo",
        comments: [
          %{
            "body" =>
              "## Codex\n\nThe log shows repeated socket resets. [observed: journalctl -u kea-dhcp4-server]\nUser reported the outage immediately after reboot. [testimony: operator statement]"
          },
          %{
            "body" =>
              "## Gemini\n\nThis likely indicates the service lost interface binding. [inferred: repeated resets plus zero packet counters]"
          }
        ]
      }
    }

    assert %{44 => view} = ProvenanceMap.build(questions)
    assert view.provenance_claim_count == 3
    assert length(view.evidence_map) == 1
    assert length(view.chain.observed) == 1
    assert length(view.chain.testimony) == 1
    assert length(view.chain.inferred) == 1
    assert hd(view.evidence_map).evidence =~ "journalctl"
    assert hd(view.chain.inferred).claim_text =~ "interface binding"
  end

  test "ignores untagged transcript lines" do
    questions = %{
      1 => %{
        title: "Q1",
        comments: [
          %{"body" => "## Gemini\n\nPlain text only.\n\n[satisfied]"}
        ]
      }
    }

    assert %{1 => view} = ProvenanceMap.build(questions)
    assert view.provenance_claim_count == 0
    assert view.evidence_map == []
  end
end

# 80 — Sourcegraph Integration for Lineage Briefs and Outcome Links

**Status:** `done`
**Tag:** `[product]`

## Goal

Turn the Round 90 addendum into a concrete integration slice: use Sourcegraph's
MCP / API surfaces as the discovery plane, then attach local lineage-aware
decision memory so agents get compact subsystem briefs before editing and durable
links between search sessions and later change outcomes.

## Scope

- Define a thin adapter layer over Sourcegraph MCP / API for:
  - semantic / natural-language search
  - keyword search
  - file reads
  - commit / diff history
  - Deep Search conversation access where available
- Define a normalized local evidence record for imported Sourcegraph context,
  including fields such as:
  - `repo`
  - `revision`
  - `path_scope`
  - `sourcegraph_query`
  - `sourcegraph_conversation_url`
  - `files_read`
  - `related_work_item`
  - `related_decision`
  - `related_prediction`
- Define a subtree-brief surface that joins Sourcegraph retrieval with local:
  - active constraints
  - supersession chains
  - rejected precedents
  - incident / fix records
  - prediction / outcome history
- Define how search or Deep Search sessions become durable references in local
  work-item, decision, or prediction records rather than disappearing as transient
  chat history.
- Define the post-change linkage model so a proposal or merged change can point
  back to the Sourcegraph context that informed it and later record whether the
  change merged, was superseded, reverted, or caused follow-up churn.

## Acceptance Criteria

- A concrete design note exists for a thin Sourcegraph adapter using MCP and/or
  documented APIs rather than a speculative full shadow index.
- At least one documented "subtree brief" format exists keyed by:
  - repository
  - path or subtree
  - revision
- The design specifies a canonical local record shape for linking:
  - Sourcegraph search context
  - local work items / decisions / predictions
  - later code-change outcomes
- The design includes one pre-change flow and one post-change flow:
  - pre-change: retrieve Sourcegraph context, then attach local lineage guidance
  - post-change: link the search context to the actual change and later outcome
- The design explicitly preserves the complementarity story:
  - Sourcegraph as discovery plane
  - local system as decision-memory plane
- The design explicitly rejects an initial implementation that tries to mirror all
  Sourcegraph state into a new canonical index.

## Notes

- Primary design source: `docs/design/rounds/round-90-sourcegraph-deep-search-and-jj-lineage.md`
- Concrete design note: `docs/design/SOURCEGRAPH_LINEAGE_INTEGRATION.md`
- This item should stay tightly scoped to integration and decision-memory
  augmentation, not generic search-engine competition.
- Closely related work:
  - `77-jj-prediction-calibration-protocol.md`
  - `79-derived-round-index-and-resource-claims.md`

# Round Metadata Index

**Status:** Drafted from Rounds 73, 74, and 89  
**Purpose:** Define the derived metadata surface for round archives while
keeping markdown as the canonical design-memory layer.

---

## 1. Canonical split

Round markdown remains the source of truth for:

- title and long-form rationale
- disagreement and synthesis
- legitimacy / audit review

The round metadata index is a **derived query surface**. It exists so agents and
tools can query tags, status, and related-round links without scanning every
markdown file on every request.

This document does **not** make the index canonical. If the index and markdown
diverge, the markdown wins and the index must be regenerated.

---

## 2. Extraction target

The recommended derived artifact is a JSONL file plus small derived views:

- `derived/round-index/rounds.jsonl`
- `derived/round-index/tags.json`
- `derived/round-index/related-rounds.json`

`rounds.jsonl` is the canonical derived artifact. The other files are optional
materialized views built from it.

---

## 3. Record shape

Each round file should extract to one JSON object with this minimum shape:

```json
{
  "round_id": "round-89-markdown-canonical-derived-structure",
  "round_number": 89,
  "source_path": "docs/design/rounds/round-89-markdown-canonical-derived-structure.md",
  "title": "Markdown as Canonical Memory, Structured Indices, and Board-Integrated Resource Claims",
  "status": "Closed",
  "tags": ["structural", "tooling", "epistemic-integrity", "governance"],
  "voices_used": ["Copilot synthesis", "local repo grounding"],
  "related_rounds": [62, 73, 74, 85, 87, 88],
  "source_kind": "round",
  "derived_from_markdown": true
}
```

### Field meanings

| Field | Meaning |
|---|---|
| `round_id` | Stable identifier derived from filename |
| `round_number` | Numeric round number when present; nullable for special cases |
| `source_path` | Markdown path that remains canonical |
| `title` | Human title extracted from the first heading |
| `status` | Round status such as `Closed` |
| `tags` | Parsed tags from `**Tags:**` |
| `voices_used` | Parsed participants from `**Voices used:**` when present |
| `related_rounds` | Numeric round references explicitly linked in prior context or explicit metadata |
| `source_kind` | Usually `round`; allows future compatibility with special records |
| `derived_from_markdown` | Explicit reminder that the record is not canonical |

---

## 4. Extraction rules

The extractor should prefer explicit headers and only fall back to light
pattern-matching where the repo already uses stable conventions.

### Required sources

- `round_id`
  - from filename
- `title`
  - from first markdown heading
- `status`
  - from `**Status:**`
- `tags`
  - from `**Tags:**`

### Recommended structured sources

- `voices_used`
  - from `**Voices used:**`
- `related_rounds`
  - from a future explicit header if added later
  - otherwise from the `Relevant prior context` section using stable `**Round N**`
    references

### Non-goals

- no attempt to canonicalize arbitrary prose into opaque inferred structure
- no LLM-derived semantic tagging in the authoritative index
- no replacement of markdown with a database-only memory layer

---

## 5. Query surfaces

Tools should query the derived index rather than rescan all round files for
common retrieval patterns such as:

- all rounds tagged `governance`
- all rounds related to round `88`
- all closed rounds touching `structural` and `tooling`
- round titles and paths for navigation UIs

The index is intentionally optimized for:

- deterministic regeneration
- diffability in git / `jj`
- simple JSONL or static-export consumers

---

## 6. Relationship to board resource claims

The round index is a **derived memory/query layer**.

Board resource claims are **operational enforcement state**.

They are related because rounds such as `88` and `89` define the semantics of
resource contention, but they should not live in the same authority layer:

- markdown explains the policy
- the round index exposes that policy history for retrieval
- board tables enforce live claim semantics

---

## 7. Implementation note

When this is implemented, the first extraction pass should support the current
round corpus without requiring a mass markdown rewrite. Newer rounds can adopt
more explicit headers over time, but the initial derived index should work from
today's stable conventions.

# Embedded Design History Model

**Status:** Drafted from Rounds 56, 63, and 89
**Purpose:** Define the now-maintained embedded design-history model after the
historical design corpus was brought into `agent-roundtable` and later split
into canonical markdown archives, derived query layers, and operational board
linkage.

---

## 1. Boundary

This note answers a narrow question:

> What does it mean for design history to be "embedded" in the main repo without
> collapsing archives, local code-context memory, and board state into one
> undifferentiated layer?

The embedded model owns:

- canonical round/design markdown archives inside the main repo
- bounded near-code memory pointers and sidecars
- derived query/index layers built from canonical markdown
- board/task linkage to relevant design memory

It must **not** mean:

- the board becoming the canonical archive of rationale
- code comments replacing deliberative history
- derived indices becoming more authoritative than markdown

---

## 2. What item 56 originally meant

The original item was about ending the split where:

- `agent-roundtable-design` held design history elsewhere
- `agent-roundtable` held product code and execution surfaces here

That merge has effectively already happened:

- the repo now contains `docs/design/rounds/`
- `docs/design/ACTIVE_DISCUSSION.md`
- `docs/design/DECISION.md`
- `docs/design/historical-synthesis`-style long-horizon memory

So the remaining design question is no longer "should the history be imported?"

It is:

- how should the embedded history be structured and queried now that it lives
  here?

---

## 3. Canonical split

The maintained answer is a hybrid model.

### 3.1 Canonical markdown

Markdown inside `docs/design/` remains the source of truth for:

- round rationale
- disagreement and synthesis
- satisfaction / closure markers
- long-form audit history

This is the durable deliberative archive.

### 3.2 Derived query/index layers

Derived layers exist for:

- round lookup
- tag search
- related-round traversal
- other machine-friendly retrieval

These are derived from markdown and must lose to markdown if they diverge.

### 3.3 Near-code / subtree memory

The embedded model also supports bounded local memory closer to code, such as:

- `jj`-visible intent pointers
- subtree sidecars
- selective local annotations

These are projections or localized entry points, not replacements for the full
archive.

### 3.4 Board/task linkage

The board should link to relevant design-memory records for active work, but the
board is not the archive of design truth.

---

## 4. Placement rules

### 4.1 Keep in round archives

- alternatives considered
- trade-offs
- disagreement
- final synthesis and closure
- long-form legitimacy/audit review

### 4.2 Keep in derived/query layers

- round metadata summaries
- tag and relationship indexes
- browse/search-oriented entry points

### 4.3 Keep near code

- bounded invariants
- local design-intent pointers
- path/subtree-specific summaries
- supersedable local memory projections

### 4.4 Keep in the board

- execution linkage
- current work/attempt association
- human gate state
- references to relevant design-memory artifacts

This is the clean operational separation item 56 needed to mature into.

---

## 5. Why "embedded" does not mean "everything inline"

The project rejected two bad extremes:

- **archive-only** memory that is too far away from active edits
- **everything-inline** memory where code comments, board rows, and local notes
  compete as parallel truths

The maintained line is:

- one canonical archive layer
- bounded local projections
- derived query surfaces
- explicit supersession/lifecycle

That is what makes the embedded model useful instead of noisy.

---

## 6. Supersession and lifecycle

Embedded design memory must support lifecycle from the start.

Every projection or local memory surface should be able to express:

- current
- stale
- superseded-by

Otherwise the embedded layer becomes cargo-cult residue.

This is one of the strongest conclusions from Round 63 and remains the
guardrail for any future near-code design memory work.

---

## 7. Relationship to later work

Item 56 is now concretely realized by later pieces:

| Concern | Current landing place |
|---|---|
| Design history lives in the main repo | `docs/design/rounds/`, `ACTIVE_DISCUSSION.md`, `DECISION.md` |
| Canonical archive vs derived query split | `ROUND_METADATA_INDEX.md` |
| Near-code bounded memory direction | `round-63-embedded-design-memory.md`, `JJ_VIRTUAL_WORKING_COPIES.md` context |
| Board linkage without archive takeover | `BOARD_EXECUTION_MODEL.md` and later board items |

So the item should now be read as an accomplished repo-structuring shift, not a
still-unfinished content migration.

---

## 8. Recommended implementation posture from here

Future work should focus on:

1. better derived indices and browse surfaces
2. bounded subtree retrieval and projection
3. explicit lifecycle/supersession for local design-memory records
4. stronger board linkage to relevant design history

Future work should **not** reopen whether the archive belongs in this repo at
all. That boundary is already settled.

---

## 9. Final synthesis

The design history is already embedded in `agent-roundtable`.

What matters now is keeping the embedded model disciplined:

- markdown archives remain canonical
- derived indices remain derived
- near-code memory remains bounded and supersedable
- board state links to design history without becoming it

That is the mature closure of item 56.

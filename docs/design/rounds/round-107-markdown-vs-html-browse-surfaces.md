## Round 107 — Markdown Canonical vs HTML Browse Surfaces

**Tags:** documentation, html, markdown, browse-surfaces, knowledge-systems  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, Copilot synthesis  
**Additional note:** all four seats produced substantive answers, but the
 initial launch had to be retried for Gemini and DeepSeek after a local
 orchestration mistake started those seats before the shared prompt file had been
 written. The round records the successful rerun outputs, not the failed first
 launch.

### Round question

The maintainer wanted a skeptical discussion about the recent tendency for
 agent-produced documents to shift from Markdown toward HTML because HTML can be
 richer for human browsing.

The question was not “is HTML nicer?” in the abstract. It was:

- which classes of agent-produced documents are genuinely better as HTML
- whether HTML should replace Markdown or remain a companion view
- and, for a concrete set of current artifacts, which should be converted now

The artifacts explicitly evaluated were:

1. `agent-roundtable/docs/design/rounds/historical-synthesis.md`
2. `agent-roundtable/docs/design/DISCUSSION_LEADER_SUMMARY.md`
3. `agent-roundtable/docs/design/rounds/round-104-critiquing-alternatives-and-product-necessity.md`
4. `agent-roundtable/docs/design/rounds/round-105-bun-zig-to-rust-translation-method-and-training-value.md`
5. `agent-roundtable/docs/design/rounds/round-106-jepa-world-models-vs-llms-for-code-porting.md`
6. `nix-router-optimized/docs/DECLARATIVE_CLAT.md`
7. `nix-router-optimized/docs/discussions/README.md`
8. `nix-router-optimized/docs/work-items/README.md`

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive after rerun
- **DeepSeek API:** substantive after rerun via direct HTTP API with local
  credential and explicit CA bundle
- **Copilot:** substantive

### Voice summaries

#### Codex CLI

- Strongest on the distinction between **editing surfaces** and **browsing
  surfaces**.
- Argued that Markdown should remain canonical for:
  - design notes
  - work items
  - round records
  - and short operational documents
- Argued that HTML is justified only where navigation materially changes the user
  experience:
  - dense hubs
  - browse-heavy indices
  - long synthesis documents
- Recommended HTML companions for:
  - `historical-synthesis.md`
  - `nix-router-optimized/docs/discussions/README.md`
- Treated the rest of the candidates as Markdown-only.

#### Gemini CLI

- Most explicit that HTML should remain a **derived read-only interface**, not a
  new canonical source format.
- Distinguished between:
  - operational scaffolding
  - active queues
  - and immutable round records
  which should stay Markdown,
  versus long-lived synthesis and dense design specs that benefit from richer
  hierarchical navigation.
- Recommended HTML companions for:
  - `historical-synthesis.md`
  - `nix-router-optimized/docs/DECLARATIVE_CLAT.md`
- Rejected HTML conversion for the short operational summary, the queue index,
  and the individual round notes.

#### DeepSeek API

- Also insisted that Markdown should remain canonical because HTML-first docs are
  worse for:
  - diffability
  - grepability
  - local editing
  - and long-term maintenance
- Most favorable to HTML for:
  - long-form synthesis
  - summary documents used as shared reference
  - and documents aimed at browsing rather than editing
- Recommended HTML companions for:
  - `historical-synthesis.md`
  - `DISCUSSION_LEADER_SUMMARY.md`
- Rejected HTML for the queue and discussion index surfaces, and treated
  `DECLARATIVE_CLAT.md` as still better kept in Markdown.

#### Copilot

- I agreed with the shared skeptical line: **do not shift the repos broadly from
  Markdown to HTML**.
- My strongest distinction was:
  - Markdown is for canonical source, editing, grep, and patch review
  - HTML is for nonlinear reading where TOC, anchors, and browsing ergonomics
    matter
- I agreed that `historical-synthesis.md` is the clearest HTML-companion
  candidate.
- For the disputed second candidate, I sided with Gemini and favored
  `DECLARATIVE_CLAT.md` because it is a long-lived, dense design artifact whose
  value increases with section navigation, while a short operational note or a
  compact index page gains less.

### First-pass convergence

The live voices converged on the following points.

1. **Markdown should remain canonical.**
   No voice supported replacing Markdown as the primary source format for these
   repos.

2. **HTML should be a companion view, not a second authority.**
   The shared model was:
   - edit Markdown
   - browse HTML where navigation helps

3. **Only a narrow subset of documents actually merit HTML.**
   The panel rejected a fashion-driven “everything important should be HTML”
   stance.

4. **The main HTML-worthy features are navigational, not decorative.**
   The recurring useful features were:
   - table of contents
   - stable heading anchors
   - cross-links
   - print-friendly layout
   - and, where appropriate, collapsible sections

5. **The main failure mode is over-productizing unstable documents.**
   The voices repeatedly warned against turning internal working memory into a
   presentation surface that is harder to patch and easier to let drift.

### Real disagreements that remained

There was one clear agreement and one clear disagreement.

#### Unanimous agreement

All obtained voices treated
`agent-roundtable/docs/design/rounds/historical-synthesis.md`
as a strong HTML-companion candidate.

#### Disputed second candidate

The second conversion candidate did **not** converge:

- Codex favored `nix-router-optimized/docs/discussions/README.md`
- Gemini favored `nix-router-optimized/docs/DECLARATIVE_CLAT.md`
- DeepSeek favored `agent-roundtable/docs/design/DISCUSSION_LEADER_SUMMARY.md`
- Copilot favored `nix-router-optimized/docs/DECLARATIVE_CLAT.md`

This disagreement matters because it shows the panel did not endorse a generic
rule like “convert summaries” or “convert indexes.” The threshold really is
document-shape-specific.

### Final synthesis

The strongest conclusion is conservative:

- keep Markdown canonical
- add HTML only where human browsing genuinely benefits
- and prefer derived companion views over replacement

For the concrete follow-up work, the maintained line is:

1. Convert `historical-synthesis.md` to an HTML companion because it is a long,
   browse-heavy synthesis surface.
2. Convert `DECLARATIVE_CLAT.md` to an HTML companion because it is the strongest
   long-lived hierarchical design document among the disputed candidates and
   benefits materially from TOC and anchor navigation.
3. Leave:
   - short operational notes
   - queue indices
   - discussion indices
   - and ordinary round notes
   as Markdown-only for now.

This is intentionally narrower than a general HTML pivot. The round's real
consensus was that HTML is useful as a **browsing layer**, not as a blanket
upgrade path for agent-authored repo memory.

## Round 105 — Bun Zig→Rust Rewrite as a Translation-Knowledge Program

**Tags:** translation, language-porting, evals, training-data, knowledge-systems  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, Copilot synthesis  
**Additional note:** this was a **degraded roster** round. Claude CLI was
requested and launched but did not return a usable answer in time and was
stopped rather than being simulated. The round treated the user's stated premise
as given: that Bun had recently been rewritten from Zig into Rust under
Anthropic ownership, and that the port began from a substantial mapping document
of Zig types and idioms.

### Round question

The maintainer wanted a round on a narrow but strategically important question:

- if a major Zig→Rust rewrite like Bun were being directed from day 0
- and if leadership cared not only about shipping the Rust port
- but also about extracting the **best possible reusable knowledge for future
  model-assisted translation work**

then how should the effort have been organized?

The specific concerns were:

- how to turn a one-off port into reusable method
- how to distinguish model-training data from retrieval-time knowledge
- how to systematically compare translation strategies rather than letting the
  rewrite become one giant ad hoc effort
- and how to evolve an initial 600-line Zig-idiom/type map into a durable
  knowledge system rather than a forgotten onboarding note

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **DeepSeek API:** substantive via direct HTTP API with local credential and
  explicit CA bundle
- **Claude CLI:** launched but hung on the prompt; no usable answer captured, so
  this round is recorded as degraded rather than as a full normal quorum

### Voice summaries

#### Codex CLI

- Strongest on treating the port as a **translation program**, not just a code
  rewrite.
- Recommended using **small translation slices** as the unit of work:
  original Zig excerpt, candidate Rust translations, chosen rationale, tests,
  benchmark evidence, and labels for whether the decision is general or Bun-local.
- Drew the clearest line between:
  - retrieval-time doctrine
  - training-eligible examples
  - and anti-pattern / rejected examples
- Argued that the most durable asset is a **combination** of:
  - retrieval-quality canonical maps
  - strong evals
  - and a smaller, cleaner distilled training set

#### Gemini CLI

- Strongest on the idea of a staged **translation-data pipeline**:
  syntax and leaf-node data first, then memory/state, then FFI/unsafe edges,
  then concurrency and architecture.
- Framed the output corpus as:
  - parallel source/translation tuples
  - ADR-style decision logs
  - a negative corpus of plausible-but-wrong translations
  - and differential test suites
- Most explicit that some knowledge belongs in **RAG/retrieval**, not in model
  weights — especially high-level architectural recipes and complex allocator /
  runtime decisions
- Also emphasized the risk of producing “**Zig in Rust syntax**” if the project
  optimizes too hard for aligned training pairs rather than idiomatic target code

#### DeepSeek API

- Strongest on framing the effort as a **translation science project** rather
  than a conventional engineering delivery project.
- Recommended a formal pattern taxonomy where each recurring Zig idiom is
  recorded as:
  - Zig idiom
  - Rust equivalent
  - semantic invariant
- Wanted a larger investment than the other voices in:
  - explicit pattern catalogs
  - incorrect/correct translation pairs
  - semantic IR or “lifted intent” records for hard constructs
  - and an external review board with authority over the corpus
- More aggressive than the other voices about dedicating a significant budget
  share to corpus and eval infrastructure rather than treating it as sidecar work

#### Copilot

- Agreed with the others that the initial mistake would be to treat the rewrite
  as a single heroic port rather than as a stream of **labeled translation
  experiments**
- Most convinced that leadership should separate four outputs from the start:
  - shipping Rust code
  - canonical translation knowledge
  - training-eligible examples
  - evaluation artifacts
- Also agreed that the 600-line seed document should evolve into a
  versioned, queryable translation playbook with explicit confidence,
  applicability bounds, and links to worked examples and counterexamples
- Most skeptical of over-investing in heavyweight IR unless it proves itself on
  the hardest construct classes; for much of the project, patterned slice
  capture + differential testing likely buys more than building a full research
  compiler layer

### First-pass convergence

The live voices converged on the following points.

1. **The rewrite should have been run as an explicit knowledge-extraction
   program.**
   The core unit of work should not have been “a file got ported,” but a
   validated translation slice or construct class:

   - source construct
   - candidate translations
   - chosen strategy
   - invariants
   - tests / benchmark evidence
   - labels for general vs Bun-local relevance

2. **The 600-line mapping note should have become a living canonical
   playbook.**
   The panel broadly agreed that a large seed map of Zig types and idioms is a
   strong starting point, but only if it is turned into:

   - a versioned pattern catalog
   - with links to examples
   - counterexamples
   - validation evidence
   - and confidence / scope labels

3. **Training data, retrieval knowledge, and evals should be treated as distinct
   assets.**
   All live voices rejected the idea that “the project corpus” is one blob.
   They converged on a three-way split:

   - **training data:** clean, validated, provenance-controlled examples with
     generalizable lessons
   - **retrieval knowledge:** decision procedures, canonical idiom maps,
     checklists, subsystem summaries, and known traps
   - **evals:** held-out differential tests, benchmarks, safety checks, and
     semantic-equivalence harnesses that should not be contaminated by the
     training material

4. **Strategy comparison should be built into the workflow.**
   The round converged on the need to compare at least a few translation modes
   explicitly:

   - direct source-to-source translation
   - semantic lifting / intent-first translation
   - pattern-library translation
   - subsystem redesign at stable boundaries

   The point is not to crown one universal winner, but to learn which strategy
   performs best for which construct classes.

5. **Compilation success is nowhere near enough as an eval.**
   The live voices broadly agreed that a serious harness needs at least:

   - behavioral equivalence tests
   - differential testing or fuzzing against the Zig implementation
   - safety checks around `unsafe`, FFI, and layout assumptions
   - allocator / runtime behavior checks
   - concurrency / ordering checks where relevant
   - benchmark tracking
   - and some human review of target-language ergonomics

6. **The corpus needs anti-pattern controls or it will become self-poisoning.**
   A major point of agreement was that large ports naturally generate:

   - deadline hacks
   - misleading literal translations
   - Bun-specific workarounds
   - and examples that “worked once” without being good lessons

   Therefore the corpus should record not only accepted exemplars, but also:

   - rejected translations
   - anti-patterns
   - and locality labels such as “canonical-general” versus “Bun-local”

7. **Leadership has to fund curation and evals as first-class work.**
   The round strongly agreed that reusable method does not emerge automatically
   from good engineers doing a big port. It has to be budgeted and staffed:

   - translation method ownership
   - eval / benchmark ownership
   - corpus curation ownership
   - and governance on what is allowed to enter canonical doctrine

### Real disagreements that remained

The round did not fully converge on the following points.

1. **How much semantic IR is worth building.**
   DeepSeek was most favorable to explicit semantic lifting artifacts and even a
   lightweight translation IR for difficult constructs.
   Copilot was more cautious:

   - useful for hard cases like `comptime`, allocator protocols, or unsafe
     pointer patterns
   - but probably not worth forcing across the entire project if slice-level
     artifact capture and strong evals already solve most of the problem

2. **How much of the reusable value should live in model weights versus
   retrieval.**
   Everyone agreed the answer is “some combination,” but:

   - Gemini and Codex leaned more toward keeping complex decision logic in
     retrieval / doctrine
   - DeepSeek was more willing to invest in a richer paired corpus for eventual
     model training, especially including corrected failures and semantic-lift
     records

3. **How faithful the port should remain to Zig structure.**
   The panel agreed this is an enduring tension:

   - literal or near-literal ports produce aligned examples that are useful for
     teaching a model how source constructs map
   - but they can also teach bad Rust habits and produce “Zig wearing a Rust
     costume”

   The unresolved answer was:
   keep both, but label redesigns explicitly rather than pretending they are
   direct translations.

### Recommended operating model

A concrete operating model consistent with the round would look like this:

1. **Phase 0 — Schema and seed formalization**
   - convert the 600-line mapping note into a structured, versioned pattern map
   - define labels for:
     - canonical-general
     - canonical-with-constraints
     - Bun-local
     - anti-pattern
     - rejected
   - build the first differential/eval harness skeleton

2. **Phase 1 — Pilot translation slices**
   - choose 10–20 representative construct classes across:
     - simple logic
     - allocator / ownership pressure
     - FFI / layout risk
     - concurrency / eventing
   - run multiple strategies per slice
   - record both successes and failures

3. **Phase 2 — Production port with artifact capture**
   - require each merged subsystem to carry:
     - translation record
     - chosen rationale
     - test evidence
     - benchmark delta
     - and locality labels

4. **Phase 3 — Distillation and corpus hygiene**
   - split output into:
     - canonical retrieval corpus
     - training-eligible pairs
     - anti-pattern / rejected archive
     - held-out eval suite
   - run periodic corpus reviews to remove noisy or overturned lessons

5. **Phase 4 — Generalization**
   - test whether the same playbook helps on non-Bun Zig→Rust samples
   - only then promote methods from “Bun-specific success” to reusable doctrine

### Final synthesis

The strongest answer from this round is that a rewrite like Bun’s should have
been managed as a **translation knowledge program with sidecar evaluation and
curation**, not merely as an engineering port whose leftover artifacts are later
repackaged for model training.

The round did **not** endorse the simplistic idea that the main reusable asset is
one giant source/target dataset. Instead it converged on a layered asset model:

- **canonical retrieval knowledge** for rules, decision procedures, and traps
- **carefully filtered training examples** for generalizable translation moves
- **negative examples / rejected translations** for anti-pattern learning
- **held-out evals** for semantic preservation, safety, and performance

The initial 600-line Bun mapping document would have been a strong seed, but the
key leadership move would have been to turn it into a versioned, evidence-linked
playbook with explicit scope boundaries. The port then becomes the process by
which that playbook is tested, revised, and distilled.

The biggest failure mode the round identified is organizational, not technical:
shipping pressure causes the team to treat corpus capture, benchmark discipline,
and rejection logging as optional paperwork. In that world, you may still ship a
successful Rust Bun — but you will fail to extract a reusable translation method
that helps future Zig→Rust projects or model-assisted language ports more
generally.

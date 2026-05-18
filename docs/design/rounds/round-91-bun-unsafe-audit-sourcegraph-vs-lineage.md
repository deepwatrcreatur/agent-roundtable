I # Round 91 — Bun's Rust `unsafe` Cleanup Burden: Semantic Search Versus Lineage-Aware Memory

**Status:** Closed  
**Tags:** market, strategy, tooling, product  
**Voices used:** Copilot synthesis, Sourcegraph docs grounding, Bun public PR grounding  
**Additional note:** this round used Bun's Zig-to-Rust migration as a concrete
case study for code-audit workload, not as a claim that the local system already
has a better Rust-analysis product than Sourcegraph

### Round question

The maintainer wanted a follow-up round that compared Sourcegraph's semantic
search and Deep Search strengths against the local offering using a concrete
example: Bun's migration from Zig to Rust, especially the future burden of
auditing and reducing `unsafe` usage in a way more consistent with Rust
philosophy.

The narrower questions were:

- if a team needs to find `unsafe`-heavy regions, FFI boundaries, or migration
  hotspots, is Sourcegraph simply better
- does `jj` lineage and decision reasoning add anything useful beyond semantic
  retrieval
- is there a product-integration story where Sourcegraph does the discovery work
  and the local system adds something meaningfully different

### External grounding used

Sourcegraph's current official positioning remains:

- Deep Search is an agentic code-search tool for natural-language questions over
  codebases
- it searches across repositories, files, commits, diffs, and code-navigation
  surfaces
- it exposes sources, files read, and search steps
- Sourcegraph MCP exposes search, file, navigation, and history operations to
  external agentic systems

Bun's public Rust rewrite grounding used here:

- PR `#30412` ("Rewrite Bun in Rust") merged on 2026-05-14
- the PR body states the codebase is otherwise largely the same, but the team
  now has compiler-assisted tools for catching and preventing memory bugs
- the PR also explicitly says follow-up cleanup work is still needed
- the changed-file list shows large new Rust-oriented build and workflow
  machinery, including Rust-specific pipeline changes and migration workflows

The round treated that as enough public evidence to discuss the likely next
burden: locating and classifying `unsafe` islands, FFI boundaries, migration
artifacts, and cleanup priorities after a large mostly-structure-preserving port.

### Relevant prior context

This round builds directly on:

- **Round 65** — current `jj` advantage is real but narrow
- **Round 67** — the moat is in decision/correction memory, not raw hosting
- **Round 74** — explicit repo-native records matter more than inferred graph magic
- **Round 87** — predictions should be judged against later graph outcomes
- **Round 90** — Sourcegraph should be treated as stronger at semantic discovery,
  with the local system positioned above search as decision memory

### First-pass convergence

The round converged on the following points.

1. **For the first-order Bun question, Sourcegraph is better positioned.**
   If the task is:
   - find every `unsafe` block
   - locate FFI-heavy regions
   - map similar migration patterns
   - trace surrounding call sites and revisions
   then Sourcegraph's semantic search, code navigation, history search, and Deep
   Search style exploration are the natural fit.

2. **The local system should not pretend `jj` lineage replaces semantic code
   understanding.**
   `jj` lineage does not inherently answer:
   - where all risky Rust patterns are
   - which `unsafe` usages are structurally similar
   - which files likely hide the next cleanup target

   Sourcegraph or a similarly strong code-search/intelligence product remains
   better for that discovery problem.

3. **The useful local value begins after discovery.**
   Once a team has found many `unsafe` regions, the next hard questions are:
   - which ones are intentional and durable
   - which ones are temporary migration residue
   - which ones are already tied to known incidents or prior cleanup attempts
   - which proposed refactors were rejected for performance, compatibility, or
     FFI reasons
   - which cleanup bets later succeeded, regressed, or were rolled back

   Those are not primarily semantic-search questions. They are decision-memory
   and outcome-tracking questions.

4. **Bun's migration example actually sharpens the complementarity story.**
   The public PR says the architecture is largely the same and that cleanup
   follow-ups remain. That implies a likely multi-phase engineering burden:
   - phase 1: large port lands
   - phase 2: risky islands are enumerated
   - phase 3: cleanup/refinement proposals are made
   - phase 4: some are merged, some rejected, some reverted, some deferred

   Sourcegraph is strongest in phases 1-2 discovery and exploration.
   The local system is strongest in phases 3-4 decision memory, justification,
   and outcome linkage.

5. **The best product story is a joint unsafe-audit workflow.**
   The integrated workflow would be:
   - Sourcegraph identifies `unsafe`, FFI, and migration clusters
   - the local system turns those clusters into bounded work items, briefs,
     constraints, and later outcome-linked records
   - later agents can see not only where risky code exists, but which cleanup
     approaches were tried and what happened

### Where Sourcegraph is stronger in this case

The round treated Sourcegraph as stronger on:

- semantic retrieval of `unsafe` patterns beyond exact grep
- cross-file exploration of similar ownership / lifetime / FFI shapes
- rapid code-local investigation by engineers or agents who do not already know
  the Bun runtime internals
- revision-aware exploration of how the Rust port touched particular subsystems
- producing an inspectable search trail for a targeted question like:
  - "show the highest-risk `unsafe` regions introduced during the Rust port near
    JavaScriptCore interop"

This is all firmly in Sourcegraph's home territory.

### Where lineage-aware decision memory adds value

The strongest differentiated surfaces in the Bun-style scenario were:

1. **Unsafe classification with local policy memory**
   The local system can record whether a given `unsafe` region is:
   - unavoidable FFI boundary
   - temporary migration artifact
   - known debt with owner
   - cleanup blocked by performance/regression concerns

2. **Proposal and rejection history**
   Teams can ask:
   - was a similar unsafe-removal attempt already tried
   - why was it rejected
   - which benchmark, compatibility, or correctness concern blocked it

3. **Outcome-linked cleanup tracking**
   If a team predicts:
   - "this unsafe block can be removed with no benchmark regression"
   - "this FFI wrapper can be narrowed safely"
   those predictions can later be linked to:
   - merge
   - revert
   - slowdown
   - incident
   - follow-up churn

4. **Durable migration rationale**
   After a large AI-assisted or batch migration, the real risk is not only risky
   code but lost reasoning. The local system can preserve:
   - which clusters were considered risky
   - which cleanup sequence was recommended
   - what was consciously deferred
   - what became canonical guidance for future contributors

### Concrete synergy with Sourcegraph

The round strongly endorsed a synergistic rather than competitive workflow.

For a Bun-style unsafe audit, the joint product could work like this:

1. **Discovery query in Sourcegraph**
   Ask for:
   - `unsafe` regions
   - FFI-heavy files
   - migration-related diffs
   - JSC or other boundary-sensitive subsystems

2. **Import bounded evidence**
   Preserve the Sourcegraph query, files read, revisions, and Deep Search
   conversation links as explicit evidence records.

3. **Create subtree or cluster briefs**
   Turn each cluster into a local brief:
   - why it is risky
   - what local constraints are known
   - what prior cleanup attempts exist
   - what predictions are being made about a new cleanup effort

4. **Track change outcomes**
   Link cleanup proposals to later:
   - merges
   - regressions
   - reverts
   - benchmark outcomes
   - superseding approaches

5. **Recover precedent later**
   Future agents or engineers can ask:
   - "show prior unsafe-cleanup attempts in this subsystem"
   - "which approaches were accepted"
   - "which ones caused regressions"

### What not to claim

The round was especially firm that the project should **not** say:

- "our `jj` graph is better than semantic search for unsafe-code audits"
- "decision lineage makes code intelligence unnecessary"
- "we can beat Sourcegraph at finding Rust migration hotspots"
- "the existence of rejection history means retrieval no longer matters"

Those claims were treated as category errors.

### What to say instead

The stronger commercial language is:

- "Sourcegraph helps you find the risky Rust."
- "We help you remember which cleanup ideas were tried, rejected, or vindicated."
- "Semantic search locates unsafe islands; lineage-aware memory explains their
  local status, constraints, and cleanup history."
- "Together, discovery and decision memory turn a one-off audit into an
  improving maintenance program."

### Concrete product direction the round would endorse

The round would endorse a future product slice specifically for this class of
problem:

1. **Risk-cluster import**
   Import Sourcegraph-derived risky code clusters as local evidence-backed work
   items.

2. **Unsafe audit status fields**
   Add local fields such as:
   - `unsafe_class`
   - `cleanup_status`
   - `cleanup_blocker`
   - `benchmark_risk`
   - `ffi_boundary`

3. **Cleanup proposal history**
   Preserve which unsafe-removal or wrapper-tightening ideas were attempted and
   why they were accepted or rejected.

4. **Prediction-to-outcome linkage**
   Reuse the Round 87 protocol to assess whether cleanup expectations later held.

### One-sentence verdict

In a Bun-style Rust migration, Sourcegraph is the stronger tool for discovering
`unsafe` hotspots and surrounding code patterns, while the local system adds
value only if it captures the later decision memory — which unsafe regions are
intentional, which cleanup strategies were tried, and which ones actually held
up — making the best product story a layered integration rather than a search
competition.

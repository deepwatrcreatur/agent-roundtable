## Round 58 — Git Compatibility on a `jj`-Native Host

**Tags:** tooling, structural, hosting
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, Copilot  
**Claude:** Not used in this run

### Round question

If Vaglio is a hosting site whose deeper architecture is `jj`-native, how easy
or hard is it to preserve strong compatibility for users who remain deeply
embedded in git workflows? Conversely, how should Vaglio avoid collapsing into
"just a way to use `jj` for development work" when the real goal is to build a
better hosting, governance, and deliberation substrate than GitHub?

### Voice summaries

#### Codex

- Codex argued that git compatibility should be treated as a **market-entry
  requirement**, not as the product thesis.
- Its preferred architecture was:
  - full git-compatible network edge for the common path
  - `jj` as the canonical internal model
  - a disciplined translation boundary between them
- It rejected both extremes:
  - pure import/export bridge mode, because that makes Vaglio feel like a sidecar
  - equal dual-native storage, because that creates operator burden and
    legitimacy confusion
- It was strongest on a distinction between:
  - git compatibility for code transport and collaboration familiarity
  - `jj`-native modeling for competing histories, deliberation, and acceptance
- Its central warning was against **product collapse into infrastructure
  fetishism**: if the main demo is merely "use `jj` here," the platform has
  missed its thesis.

#### Gemini

- Gemini framed Vaglio as a **governance platform that uses `jj` as its internal
  coordination primitive**, not as a `jj` hosting site.
- It wanted a "lossless git projection" for mainstream Git users:
  - normal `clone` / `fetch` / `push`
  - deterministic branch/ref mapping
  - familiar PR rendering
  - git-shaped CI and webhook events
- But it argued that several core advantages must remain `jj`-native:
  - conflict persistence as a shareable object
  - operation-log / meta-history
  - change-centric modeling rather than branch-centric clutter
- Gemini was the strongest on **projection UX**:
  - let Git users see familiar surfaces
  - offer a more powerful toggle into the richer graph when useful
- Its main risk was the **leaky abstraction trap**: if Git users encounter `jj`
  semantics only as confusing breakage, they will experience Vaglio as a broken
  Git host rather than a better one.

#### DeepSeek

- DeepSeek argued for **bounded git compatibility with explicit semantic
  translation**, not full git emulation.
- It sharply separated:
  - git transport compatibility, which it considered mandatory
  - git governance semantics, which it considered the wrong thing to imitate
- It insisted that governance, deliberation, and audit surfaces should remain
  **unapologetically `jj`-native**.
- Its preferred architecture was a **semantic translation layer** where:
  - git refs are projections of `jj` state
  - git pushes become interpreted change proposals
  - merge-like events become explicit promotion records
- DeepSeek's strongest warnings were:
  - semantic collapse into "just GitHub with `jj` underneath"
  - legitimacy gaps when Git users believe they are doing ordinary git actions
    but the platform is actually applying richer governance semantics
- It emphasized that any lossy mapping must be transparent, documented, and
  reversible where possible.

#### Copilot

- Copilot's view was that Vaglio should optimize for **git continuity at the
  edge, `jj` truth in the core, and hosting/governance differentiation above the
  transport layer**.
- It agreed that mainstream users should not have to adopt a new local tool just
  to try the host.
- But it also argued that several things must not be flattened into Git-shaped
  metaphors:
  - proposal lineage across rewrites
  - endorsement and objection records
  - explicit promotion into accepted history
  - deliberative memory that survives forks
- Copilot was strongest on product framing:
  - the real win is not "you can use Git here"
  - the win is "your project's reasoning, alternatives, and acceptance path are
    portable, inspectable, and harder to silently erase"
- It emphasized that Git compatibility should be treated as the **on-ramp**,
  while the product itself lives in review, discovery, governance, and project
  memory.

### First-pass convergence

All four voices converged on the following points:

1. **Strong git compatibility is required for adoption.** Ordinary users and
   existing teams must be able to keep `clone`, `fetch`, `push`, familiar refs,
   CI integrations, and recognizable review entry points.
2. **But Vaglio should not become "just a `jj` dev host."** The product thesis
   is not local-VCS substitution; it is better hosting semantics around forks,
   project memory, acceptance, and governance.
3. **The right model is a translation layer, not a sidecar bridge.** Vaglio
   should not merely import/export between worlds; it should present a genuine
   host with a git-compatible edge and a `jj`-native core.
4. **Equal dual-authority storage is the wrong answer.** Two canonical models
   would multiply complexity, blur legitimacy, and make operator behavior harder
   to reason about.
5. **Certain surfaces must remain `jj`-native.** Change identity, conflict
   persistence, operation history, promotion/acceptance, and deliberative audit
   trails are precisely where Vaglio's value exceeds GitHub.
6. **Git users must not experience the richer model as random breakage.**
   Translation boundaries need to be visible, documented, and paired with clear
   UX for "what just happened" when semantics differ.
7. **Public language should emphasize continuity and better hosting, not VCS
   ideology.** Mainstream users need to hear "works with your Git workflow" and
   "gives you better project memory and fork handling," not a sermon about
   revision theory.

### Disconfirmation findings

The main risks surfaced across the voices were:

- **leaky abstraction** — claiming Git compatibility while exposing unfamiliar
  `jj` behavior only when something goes wrong
- **false equivalence** — marketing Vaglio as a normal Git host when promotion,
  acceptance, and review semantics are materially different
- **sidecar collapse** — reducing the platform to import/export or mirroring
  utilities rather than a real host with native semantics
- **dual-authority confusion** — treating both git and `jj` as equal canonical
  truth sources
- **governance flattening** — translating deliberation and legitimacy into
  ordinary PR mechanics until the differentiating value disappears
- **trust failure on rewrite/conflict edges** — Git users experiencing rebases,
  force-push analogues, or conflict persistence as platform bugs rather than as
  explicitly modeled states

### Closure

The round closes with the following design rules.

#### 1. What git compatibility must cover

The minimum converged compatibility surface is:

- `git clone`, `fetch`, and `push`
- predictable branch and ref projection
- familiar pull/merge request entry points
- standard CI, webhook, deploy-key, and integration behavior
- readable audit and permission surfaces for Git-native users

This is a **trust floor**, not a luxury feature.

#### 2. What should remain `jj`-native

Vaglio should keep the following as native semantics:

- canonical change identity and lineage
- operation / evolution history
- conflict persistence and forkable disagreement
- explicit promotion into accepted history
- endorsement, objection, and deliberation records
- operator policy and governance state

These are not implementation details. They are the substrate of Vaglio's
hosting model.

#### 3. The right architecture

The converged answer is:

- **git-compatible edge**
- **`jj`-native canonical core**
- **explicit semantic translation layer**

That means:

- Git clients and ordinary automation can continue to function
- Vaglio internally reasons about changes, forks, and acceptance in richer terms
- when a Git action maps imperfectly into Vaglio semantics, the platform makes
  the translation visible rather than pretending equivalence

#### 4. Why `jj` compatibility is not the main thesis

The round converged that Vaglio is not mainly trying to help people run a new
local VCS. It is trying to solve the problems of current hosting platforms,
including:

- deliberation being detached from code history
- forks losing too much social and governance context
- accepted history looking cleaner than the real contested process that produced
  it
- project legitimacy, endorsement, and alternatives being poorly represented
- review and discovery surfaces collapsing too much context into branch tips and
  PR threads

The value appears in the host's treatment of **reason, conflict, alternatives,
and acceptance**, not just in the storage engine.

#### 5. Concrete product / protocol recommendations

1. **Make Git transport a hard requirement**
   - standard clone/fetch/push and common forge integrations must work without
     requiring local `jj`
2. **Use one canonical internal authority**
   - keep `jj` as the source of truth; treat Git refs as projections, not as an
     equal second ontology
3. **Render a proposal object above PRs**
   - let Git users enter through a familiar PR-like view, but attach richer
     lineage, endorsement, objection, and promotion metadata underneath
4. **Expose a dual history view**
   - offer a familiar Git-shaped history view and a richer structured graph /
     change view, with the latter available when users need to inspect contested
     alternatives
5. **Make translation visible**
   - when a Git push becomes a fork, pending promotion, or conflict-persistent
     state, explain that clearly in UI and API responses
6. **Keep governance surfaces native**
   - do not force issues, discussions, audit trails, and acceptance records into
     Git metaphors if doing so erases the product's core value
7. **Provide migration helpers, not migration dogma**
   - optional remote helpers, mirroring, or Git-oriented tooling can smooth the
     path, but should not become the main architecture
8. **Anchor public messaging above transport**
   - say "works with your Git workflow" and "preserves project reasoning,
     alternatives, and acceptance history," rather than "come adopt `jj`"

#### 6. Tightened philosophy and vocabulary

The round converged on this public-facing statement:

**Vaglio should let projects keep their Git workflows while giving them a host
that remembers more, loses less, and treats alternatives and acceptance more
honestly than GitHub does.**

Public-facing vocabulary should emphasize:

- Git compatibility
- proposal review
- project memory
- fork continuity
- acceptance history
- maintainership and endorsement

Operator-facing language may still speak in terms of:

- `jj`-native canonical history
- semantic translation
- change identity
- promotion events
- operation log

### Final answer

The council's answer is that Git continuity is not in tension with a `jj`-native
host if the boundary is disciplined. Vaglio should behave like a trustworthy Git
host at the transport edge while refusing to flatten away the richer semantics
that make it worth existing. That means users can keep their entrenched Git
workflows, but the platform itself must stay centered on what GitHub fails to
preserve: project reasoning, portable fork context, explicit legitimacy around
accepted history, and better visibility into live alternatives.

`[satisfied]`

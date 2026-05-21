## Round 116 — Agent Hygiene and Dirty-Checkout Discipline

**Tags:** hygiene, worktrees, git, orchestration, tooling  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** this round asked why cleanup debt keeps recurring despite prior worktree and single-writer guidance, and what concrete changes would most likely stop it.

### Round question

The maintainer wanted a fresh round on a recurring operational problem:

- agents are supposed to use clean worktrees
- shared checkouts are still repeatedly getting dirty
- publication often turns into careful cherry-picking or patch replay from noisy
  trees
- and local artifact clutter keeps making `git status` harder to trust

The concrete decision questions were:

- is the main problem guide clarity, guide placement, missing enforcement, or bad
  defaults
- should the shared checkout be treated as read-mostly / sync-only by default
- what is the smallest high-leverage intervention that changes agent behavior
- and what concrete work items should follow

### Grounding used in this round

Fresh grounding carried into the round:

- **Prior local process context**
  - Round 61 argued that breakthrough fixes were being lost or reintroduced
    across independent agent branches and stale pins
  - Round 88 converged on single-writer discipline for the same live resource,
    while preserving parallel branch work elsewhere
  - work item 78 already exists around stronger resource-contention discipline
- **Current local guidance**
  - `docs/design/ORCHESTRATION_GUIDE.md` already tells agents to stop mutating a
    dirty checkout and move to a separate worktree or branch
  - repo-local guidance in the Nix repos already favors worktrees for parallel
    write work
- **Recent operational evidence**
  - repeated cleanup/recovery work from dirty shared checkouts
  - branch tips advancing during publication, forcing patch replay instead of
    clean landing
  - recurring local artifact clutter such as agent worktree metadata and editor
    sidecar files

Important scope boundary carried into the round:

- the question was **not** whether worktrees are conceptually good
- it was why the current guidance still fails in practice and what should become
  load-bearing instead of advisory

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** substantive
- **DeepSeek API:** substantive
- **Copilot:** substantive

This round therefore had a **full substantive roster**.

### Voice summaries

#### Codex CLI

- Strongest on the claim that the core failure is **default-path economics**:
  the shared checkout is the fastest writable path, so agents keep choosing it.
- Treated dirty-checkout cleanup as a “broken windows” problem:
  once a shared tree is even slightly noisy, agents stop treating cleanliness as
  a real invariant.
- Most explicit that prose guidance is insufficient without a
  **stop-the-line preflight gate**.
- Recommended:
  - worktree-by-default mutation flow
  - a hard or near-hard hygiene check before mutating
  - and standardized ignore/quarantine rules for agent artifacts

#### Gemini CLI

- Strongest on distinguishing **correct theory vs weak defaults**:
  the docs already say the right things, but they are not load-bearing.
- Most explicit that guidance placement is fragmented and can be missed because
  it lives in multiple worktree-scoped or secondary documents rather than one
  root-level rule every agent sees.
- Treated the shared checkout as needing a new policy identity:
  **read-mostly / sync-only**, not a normal write surface.
- Recommended a two-layer fix:
  - canonical root policy
  - plus a pre-write warning/guard

#### Claude CLI

- Strongest on the claim that this is fundamentally a **bad-defaults** problem
  more than a misunderstanding problem.
- Preferred a sharper operating mode split:
  shared checkout for sync and inspection, disposable worktrees for edits.
- Most explicit that “recovery branch” behavior is a symptom of writing on
  moving branch tips rather than the correct unit of work.
- Recommended:
  - a preflight script
  - a worktree helper wrapper
  - and ignore/cleanup standards for local artifacts

#### DeepSeek API

- Strongest on the framing that the project currently has conceptual hygiene
  rules but lacks **enforced defaults and situational triggers**.
- Agreed that the smallest practical policy shift is:
  if you are about to edit and the checkout is dirty or unclear, leave
  immediately and create a disposable worktree.
- Most explicit that artifact noise and real unsafe dirt are separate issues, but
  they compound each other because noisy status output weakens operator judgment.
- Recommended concise operational guidance plus one helper wrapper that checks
  status and nudges or creates a worktree before edits begin.

#### Copilot

- I agreed with the strong convergence that the main failure is not “agents do
  not know about worktrees.”
- My strongest synthesis point was:
  the shared checkout is still acting as a writable commons, while the correct
  path requires deliberate extra steps and therefore loses unless tooling and
  policy reverse the default.
- I also agreed that the next moves should be practical and narrow:
  policy surfacing, preflight guardrails, and artifact-ignore hygiene rather than
  another abstract “be cleaner” reminder.

### First-pass convergence

The substantive voices converged on the following points.

1. **The problem is not mainly lack of conceptual agreement.**
   The project already has the right intuition about worktrees and resource
   contention.

2. **The shared checkout remains the path of least resistance for writes.**
   That is the real operational bug.

3. **The shared checkout should become read-mostly / sync-only by default.**
   Agents should inspect, pull, fast-forward, and land there — not treat it as
   the normal mutation surface.

4. **Guide placement matters, but enforcement/defaults matter more.**
   A canonical root rule helps, but hygiene will keep degrading if the moment of
   use still offers no friction against unsafe edits.

5. **A small preflight guard is the highest-leverage first intervention.**
   The panel repeatedly favored a lightweight `git status`-based pre-write check
   or wrapper that warns, redirects, or refuses mutation in dirty shared trees.

6. **Artifact-noise cleanup is a separate but necessary follow-up.**
   If local editor and agent artifacts keep appearing in normal status output,
   operators and agents lose the ability to distinguish benign clutter from real
   hygiene violations.

### Real disagreements that remained

There was no major strategic disagreement, but there were real differences in
strictness:

- **Codex** was most willing to make the hygiene gate hard-fail by default
- **Gemini** was most focused on canonical guide placement and rule visibility
- **Claude** most strongly favored helper wrappers and explicit write-mode entry
  points
- **DeepSeek** was most comfortable with a short operational rule plus a lighter
  wrapper nudge

These were differences in enforcement shape, not direction.

### Final synthesis

The strongest answer from this round is:

- cleanup debt keeps recurring because the project has the right hygiene theory
  but the wrong writable default
- and the shared checkout is still treated as common mutable space rather than a
  clean sync/landing surface

The panel rejected two bad extremes:

- **bad extreme A:** “just remind agents more often in prose”
- **bad extreme B:** “this is only a tooling problem; guide placement does not
  matter”

The maintained line is:

- make the rule explicit at the root:
  **shared checkout = read-mostly / sync-only**
- move edits into disposable worktrees by default
- add one small preflight or wrapper-level guard so the unsafe path is no longer
  frictionless
- and reduce agent/editor artifact noise so status output becomes trustworthy
  again

That gives the project a practical way to turn hygiene from advisory etiquette
into an operational default.

### Recommended follow-on work

The round converged on three concrete follow-ons:

1. **Codify a root-level read-mostly policy.**
   Put the rule in the main agent entrypoints so every agent sees it before
   mutating.

2. **Add a dirty-checkout preflight guard.**
   A small wrapper or helper should check for dirty state, branch divergence, and
   unsafe write context before edits begin.

3. **Tighten ignore/worktree-path hygiene.**
   Agent artifacts and editor sidecars should stop leaking into repo status
   output by default.

### Satisfaction marker

This round is satisfied if future agent write work starts from:

- a clean shared checkout used mainly for sync/landing
- a disposable worktree for mutations
- and a visible preflight guard that makes unsafe write-in-place behavior
  abnormal rather than invisible

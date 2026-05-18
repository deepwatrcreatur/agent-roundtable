## Round 61 — Preserving Breakthrough Fixes Across Independent Agents

**Tags:** epistemic-integrity, structural, tooling
**Status:** Closed for Q1-Q4 / Q5 release-tag verdict still pending  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, Claude IC  
**Run mode:** Live GitHub-issue roundtable on `deepwatrcreatur/agent-roundtable` issues `#80`-`#84`

### Round question

What did the 2026-05-09 / 2026-05-10 router regressions reveal about:

- how independently working agents, stale flake pins, and overlapping branches
  reintroduce old bugs
- how project knowledge should be embedded in repos so validated repairs become
  durable and discoverable
- whether the current `BRIEF.md` / `DECISION.md` / `rounds/` /
  `.roundtable/state/` artifact model is sufficient
- how git history and live incidents should become first-class evidence in
  future discussions
- whether the recent upgrade cluster is ready for a release tag

### Incident context

The triggering evidence was not abstract process drift. It was a concrete router
repair and regression cycle:

- a prior router generation switch caused a household outage and rollback
- the router dashboard later regressed from the intended amber theme to the old
  blue theme
- the DHCP panel regressed to `0` leases and the stale pool
  `10.10.10.100 - 10.10.10.250`
- live investigation showed two distinct causes:
  - stale pinned `nix-router-optimized` dashboard assets
  - lost Kea snapshot / DHCP override logic in the active consumer tree
- the final live repair restored:
  - amber dashboard CSS
  - DHCP pool `10.10.200.0 - 10.10.222.0`
  - nonzero lease count

This round treated that incident as design evidence for repo memory and
artifact structure.

### Evidence used by the panel

- `unified-nix-configuration` recent commits:
  - `d44d8bb7` — `docs: point flake checkout policy at shared RTK`
  - `630c7dab` — `fix(router-backup): align standby interfaces and mgmt address`
- active router-related worktree changes in:
  - `hosts/nixos/router/role.nix`
  - `modules/nixos/router-dashboard-runtime-repair.nix`
  - `scripts/router-dashboard-api-wrapper.py`
- router dashboard / DHCP regression and live restoration details from the
  active incident brief
- live issue discussions:
  - `#80` Q1 root cause / regression mechanism
  - `#81` Q2 durable knowledge artifacts
  - `#82` Q3 artifact sufficiency
  - `#83` Q4 evidence and provenance handling
  - `#84` Q5 release timing (started but stalled before full consensus)

### Voice summaries

#### Codex

- Framed the core failure as the repository preserving code state without a
  strong enough record of which repairs are authoritative, recovered, deployed,
  and still required.
- Argued that the project needs durable fix-oriented artifacts rather than
  relying on rounds and session memory.
- Favored fix cards, incident records, and a discovery index keyed by surface.
- Supported treating stale flake pins as a provenance problem rather than only a
  branch-discipline problem.

#### Gemini

- Emphasized the split between narrative history and operational state.
- Proposed a more explicit discovery layer so agents can ask what is known-good
  for a path, host, or subsystem before editing.
- Pushed for provenance-explicit briefs and durable incident timelines with
  exact verification commands.
- Strongly supported a `known-good-fix-recovered` marker because repeated use of
  that marker is itself evidence that sync mechanisms are failing.

#### DeepSeek

- Provided the sharpest diagnosis: the repo currently conflates code with
  knowledge about why the code is that way.
- Pressed hardest on schema precision:
  - structured pin provenance rather than prose
  - health checks rather than hand-wavy verification notes
  - explicit status transitions such as `validated` vs. `known-good`
- Distinguished discovery from enforcement:
  surface maps should help lookup, while hooks or policy should enforce
  protection.

#### Claude IC

- Closed Q1-Q4 by synthesizing the convergence and adopting the strongest
  concrete proposals from the other voices.
- Ruled that the current artifact model is good for deliberation but not enough
  for operational memory.
- Elevated the unresolved implementation question:
  who populates the evidence and knowledge artifacts, and how much should be
  tooled vs. manual.

### First-pass convergence

The panel converged on the following conclusions.

1. **The root failure is loss of durable operational knowledge, not failure of
   deliberation quality.**
   The fix existed in branches, local checkouts, and prior sessions, but the
   repo did not preserve the why, provenance, and validation state strongly
   enough for future agents to rediscover it.

2. **Stale flake pins and recovery branches are first-class regression vectors.**
   A working fix in the filesystem can still be absent from the evaluated build
   graph, and a recovery branch can remain a dead-end island of proven
   knowledge if it is not promoted into the main line with artifacts attached.

3. **The current roundtable artifacts are necessary but insufficient.**
   `BRIEF.md`, `DECISION.md`, `rounds/`, and `.roundtable/state/` should keep
   their current roles, but they do not provide a canonical lookup path for
   validated repairs.

4. **Two new durable artifact families are required.**
   The panel converged on:
   - fix cards
   - incident records

5. **A discovery index is required.**
   Whether named `SURFACE_MAP`, `INDEX.md`, or similar, agents need a durable
   way to answer:
   - what is known-good for this path or host?
   - which pins or dependencies does that known-good state rely on?
   - what health check verifies it?

6. **Schema beats prose.**
   The panel consistently pushed toward structured fields, especially for:
   - `pin_map`
   - `verification_command` / `health_check`
   - `regression_signal`
   - `status`
   - incident cause / fix linkage

7. **Briefs need mandatory evidence sections.**
   Future incident-driven rounds should include exact commit hashes, touched
   paths, pinned input revisions, and observed runtime state, rather than
   relying on narrative summaries alone.

8. **Typed links should connect commits, regressions, and repairs.**
   The round converged on a small link vocabulary such as:
   - `introduced-by`
   - `repaired-by`
   - `regressed-by`
   - `validated-by`
   - `depends-on-pin`
   - `superseded-by`

9. **`known-good-fix-recovered` should become a real workflow marker.**
   The panel did not treat this as a decorative label. Repeated recovery of the
   same fix is a signal that the project is losing memory.

### Minimum structure adopted by the round

The strongest converged answer across Q2-Q4 was a dedicated durable knowledge
layer. The exact directory naming varied across voices, but the substance was
stable:

```text
docs/knowledge/
  fixes/
  incidents/
  INDEX.md            # or SURFACE_MAP equivalent
```

The round also accepted the stronger view that fix cards should eventually carry
testable probes, not just prose descriptions of prior checks.

Minimum fix-card fields:

- `surface`
- `problem`
- `known_good_state`
- `verification_command` or `health_check`
- `provenance`
- `regression_signal`
- `status`
- `supersedes`

Minimum incident fields:

- `date`
- `affected_surfaces`
- `symptoms`
- `root_cause`
- `fixes_applied`
- `validation_result`
- `follow_up_items`

### Q1-Q4 closure summary

#### Q1 — What caused old bugs to reappear?

Closed by consensus in issue `#80`.

The panel agreed the regressions came from:

- dependency-level split-brain via stale flake pins
- recovery branches not being promoted into active durable knowledge
- operational truths living only in session memory
- blind recombination of overlapping branches without preserved constraints

#### Q2 — How should project knowledge change?

Closed by consensus in issue `#81`.

The panel agreed the project needs:

- fix cards as the primitive for validated repairs
- incident records for outages and regressions
- an index or surface map for discovery
- structured provenance for pinned inputs
- a distinction between `validated` and `known-good`

#### Q3 — Are current discussion artifacts sufficient?

Closed by consensus in issue `#82`.

The answer was no. The existing artifact set is good for preserving debate and
design decisions, but insufficient for preserving operational repairs.

#### Q4 — How should git history and incidents become first-class evidence?

Closed by consensus in issue `#83`.

The panel agreed future briefs should carry stronger evidence and provenance
blocks, incident records should become durable artifacts, and repeated recovered
fixes should be marked in a machine-meaningful way.

### Q5 release question

Issue `#84` started but did **not** complete a full panel cycle during the live
run. Only Codex's opening comment landed before the run stalled.

Because of that, this round does **not** archive a final four-voice consensus on
release tagging.

However, the surrounding discussion strongly suggests the likely gating posture:

- do not tag a release until the recovery knowledge is captured durably
- do not tag while open follow-ups such as `router-backup` reachability and AP
  `.22` remain unresolved
- do not tag until the release note can distinguish:
  - repaired regressions
  - recovered known-good fixes
  - remaining operational noise

This is an informed interim read, not the official Q5 close.

### Open implementation questions

The round left several important details open:

1. **Who writes the evidence blocks and fix cards?**
   Manual authoring under outage pressure is fragile; tooling support may be
   necessary.

2. **Where should enforcement live?**
   Discovery indexes should not be overloaded into policy engines. Hooks,
   checks, or orchestrator rules likely need to enforce fix preservation.

3. **What exact directory naming should be canonical?**
   Voices differed between `docs/knowledge/`, `docs/registry/`, and narrower
   variants. The content model matters more than the path, but the repo still
   needs one canonical choice.

4. **What is the release gate?**
   Q5 should be rerun or resumed so the release posture is archived as a full
   panel conclusion rather than inferred from partial discussion.

### Closure

This round materially sharpened the project thesis around embedded repo
knowledge:

- rounds preserve deliberation
- decisions preserve design rulings
- but validated operational truth needs its own durable layer

The incident demonstrated that project memory must not stop at "what we decided."
It must also record "what was known-good, how it was verified, what pins it
depended on, and how to detect if it has been lost again."

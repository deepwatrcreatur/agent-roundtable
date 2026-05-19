# Vaglio Historical Synthesis: Genuine Follow-Up Rounds

Browse-oriented HTML companion: [`historical-synthesis.html`](./historical-synthesis.html).

These notes record genuine follow-up rounds run with the actual CLI agents
(`codex` and `gemini`). Claude was not used in these closes because the round
owner explicitly allowed proceeding without Claude and Claude CLI availability
was rate-limited during this session.

## Round 45-46: Subject Tags & Multidimensional Discovery
**Consensus:** Tags are first-class architecture, not cosmetic labels. For v1,
use `jj change_id` as the canonical anchor for tag identity, store tag state in
Dolt keyed by `(repo_id, change_id)`, and record immutable evidence such as the
observed `commit_id` and actor at tag time. Split tags into `advisory` and
`governing`; only governing tags that are approved and not disputed may affect
routing or tag-scoped vouch reach. No implicit inheritance for governing tags
in v1.

## Round 47: The Project Mind (Active Inference)
**Consensus:** Translate Active Inference into explicit governance rather than
metaphor. Vouches are claim-scoped, time-bounded precision signals attached to
concrete basis/scope. Stress is computed over contested objects, not people, and
attention is allocated by risk-reduction heuristics rather than talk volume.
Automation may detect, score, and recommend, but legitimacy-critical actions
remain human/IC-governed. A people/power dispute escape hatch is mandatory:
when invoked with a concrete asymmetry, the issue moves into a dedicated
power-review state and object-stress stops being the lead routing signal.

## Round 48: File Reservations vs. Git Worktrees
**Consensus:** `jj` does not eliminate reservations entirely; it demotes them
from correctness locks to scheduling / intent primitives. Agents should work in
private ephemeral working copies by default. Merge-back is an explicit promotion
step into vouched history, with rebase and revalidation on current accepted
head. To prevent stale-success promotion, each private change must carry enough
metadata for the orchestrator to detect causal and architectural overlap before
full revalidation. Architecturally incompatible but locally valid changes go to
arbitration rather than “first to the gate wins.”

## Round 49: Controversial Open Source Figures as Case Studies
**Consensus:** Vaglio must not score people directly. It should score contested
objects and protocol events, while allowing only bounded, project-local views of
 actor-centrality to high-stress objects. Dashboards should separate technical,
governance, and people/power conflict, with a shared stress timeline. The
system may route, slow, tag, and recommend process interventions, but it must
not emit public reputation scores, automated person sanctions, or personality
judgments.

## Round 50: Active Inference, Merit, and the "Slop Shield"
**Consensus:** Active inference is useful as a bounded operator theory for
evidence routing, uncertainty reduction, and boundary design around code
objects. Merit should be decomposed into object-scoped correctness,
reliability, calibration, reproducibility, and coordination value rather than
person status. "Slop shield" is acceptable as user-facing language for
discovery filtering, but not as the core legitimacy vocabulary of governance.

## Round 51: Clarifying the "Project Mind"
**Consensus:** The core intuition survives, but "project mind" is too
anthropomorphic if taken literally. The disciplined replacement is a
history-shaped governance pattern: project evidence history, precedent model,
policy surface, or latent project model. Agents should help reconstruct that
pattern from decisions, surface uncertainty and drift, and support bounded
novelty, while final legitimacy-critical judgments remain human-owned.

## Round 52: Social Epistemology vs Active Inference
**Consensus:** Social-epistemic convergence remains the legitimacy foundation:
it explains why heterogeneous agreement is evidence and why prestige/PageRank
is insufficient. Active inference adds a distinct governance layer for
attention allocation, boundary design, novelty handling, object stress, and
uncertainty routing. Its value is real, but only when translated into explicit
protocol rather than metaphysical rhetoric.

## Round 53: Self-Escalation and Protocol Friction
**Consensus:** Behavior such as self-escalation, attention-mining, and
lane-bypassing should be represented as object-scoped protocol friction, not as
personality defects. Vaglio should measure escalation pressure, reviewer churn,
queue distortion, and evidence delta at the object level, then apply explicit,
reversible friction such as cooldowns, bundling, slower lanes, neutral review,
and typed exception requests. Public language should emphasize fair lanes,
reviewer bandwidth, and visible exceptions rather than psychology or AI
diagnosis.

## Round 54: Contributor Support and Re-Engagement
**Consensus:** A humane contributor-support layer is compatible with the prior
 philosophy if it stays object-scoped and dignity-preserving. Agents may
 reconstruct probable fit conditions from public project history, generate
 bounded mismatch hypotheses, offer practice lanes and re-entry options, and
 compress repeated guidance for maintainers. The platform may sell preparation
 and coaching infrastructure, but must never sell acceptance likelihood, queue
 priority, or person-level worth, and may not repurpose contributor failure data
 without explicit consent and strong boundaries.

## Round 55: Socially Coupled Priors and Brigading
**Consensus:** Active inference can accommodate social constraints in prior
updating, but Vaglio still needs explicit social-epistemic and anti-capture
protocols because consensus is often socially coupled rather than independent.
The system should measure timing concentration, basis diversity, consensus
velocity, and evidence-to-label ratios at the object/process level, then apply
visible anti-cascade mechanisms such as delayed visibility, diversity-of-basis
requirements, structured disconfirmation, and separate evidence signals from
coalition signals. Hidden trust scores, ideological profiling, and secret
de-boosting remain out of bounds.

## Round 56: Design Stress vs Social Stress
**Consensus:** Vaglio can partially infer the difference between design /
implementation stress and coordination / social friction, but not automate it as
ground truth. The responsible default is technical-first routing and visibility,
with bounded, transparent tuning for governance sensitivity. Mixed cases should
be explicit, confidence-tagged, and routed through special review paths rather
than forced into simplistic technical or social labels.

## Round 57: Governance Collapse, Constitutional Gaps, and Branch Naming
**Consensus:** `jj`-based democratic branching materially improves survivability
by making disagreement forkable, inspectable, and less dependent on a single
write-path bottleneck, but it is not a constitution. Vaglio still needs explicit
legitimacy machinery around endorsement, escalation, transition, and naming.
Contributor- or org-scoped namespaces should be the default, while labels that
imply shared authority or endorsement must be mechanically earned through
published criteria rather than granted informally or inferred from popularity
alone.

## Round 58: Git Compatibility on a `jj`-Native Host
**Consensus:** Vaglio should treat strong git compatibility as an adoption and
trust requirement at the transport and integration edge, while keeping
governance, deliberation, promotion, and canonical history modeling
structurally `jj`-native. The right architecture is neither pure bridge mode nor
full dual-authority storage, but a disciplined translation layer: ordinary users
can keep `git clone` / `fetch` / `push`, familiar review entry points, and CI
integrations, while Vaglio's real product value appears above transport as
forkable governance, inspectable alternatives, durable project memory, and
explicit legitimacy around accepted history.

## Round 61: Preserving Breakthrough Fixes Across Independent Agents
**Consensus:** Router regressions showed that the project loses validated repairs
 not because deliberation failed, but because durable operational knowledge is
 still too weakly embedded. The panel converged that the current roundtable
 artifact set is necessary but insufficient; the repo needs stronger fix cards,
 incident records, and a discovery index keyed by surface so future agents can
 find what is known-good, what pin/dependency state it relied on, and how to
 validate it. Structured provenance, explicit status fields, typed links such as
 `introduced-by` / `repaired-by` / `validated-by`, and a real
 `known-good-fix-recovered` workflow marker were all treated as first-class
 requirements rather than optional documentation polish.

## Round 62: Bulletin Board, Product Boundaries, and Reducing Supervision Burden
**Consensus:** The project should move now toward a Symphony-style bulletin
board rather than continuing to center the workflow on many supervised terminal
tabs. `dmux` should remain as an operator console, but not as the canonical
orchestration surface. The right state model is hybrid: issue-like and socially
legible on top, Dolt-backed and structurally queryable underneath. The cleanest
conceptual separation is: `agent-roundtable` for design discussion, a bulletin
board for execution dispatch, and Vaglio for forge / governance / long-term
memory. The practical implementation path is to build the board first as a
bounded context inside the existing Elixir / Jido stack, preserving flexibility
to keep it embedded or split it later.

## Round 63: Embedded Design Memory in `jj` / Code Context
**Consensus:** The project should move from archive-only design memory toward a
hybrid embedded model that keeps round artifacts as the full deliberative
archive while adding local, bounded retrieval near code. The converged answer is
not to pick one representation, but to combine a single canonical structured
design-memory record with `jj`-visible intent pointers, subtree sidecars, and
selective local annotations. The task board should link to this memory but not
become its canonical home. The key guardrail is explicit lifecycle /
supersession so embedded context does not become stale cargo-cult noise.

## Round 64: Generic Execution VM / Agent Tooling Substrate
**Consensus:** The execution substrate should be layered: a generic NixOS VM
output as the primary reproducible artifact, plus a reusable Home Manager
agent-toolchain profile as a secondary layer for user-scoped reuse. The system
must publish an explicit baseline tool inventory, especially for OCR, image
processing, scripting, debugging, repo operations, and Nix tooling. Secrets and
subscription credentials should be modular and operator-swappable rather than
embedded in personal host config. The execution VM should integrate directly
with the task board and future `pve-strix` deployment rather than remaining a
mere convenience shell.

## Round 65: Is `jj` + Embedded Deliberation a Meaningful Agentic Coding Advantage?
**Consensus:** The design offers a real but currently narrow improvement over a
competent git+GitHub agent workflow. The strongest present gains are in
rewrite-heavy local mutation, preserving alternatives and supersession, treating
conflict as durable inspectable state, and enabling bounded subtree-local
rationale retrieval when the metadata is actually surfaced. The round rejected
broad claims of general superiority over disciplined git practice for transport,
review, CI, and ordinary task execution. The right next move is to amplify
subtree-local retrieval, supersession, and edit-time surfacing of rationale, and
to benchmark against a competent git-agent baseline rather than overclaim from
theory.

## Round 66: Alyx, Planning Discipline, and What We Should Copy
**Consensus:** The project is plausibly ahead of Alyx in some architecture
ideas, especially code-local durable rationale, explicit supersession, and the
clean separation between deliberation, execution dispatch, and durable memory.
But the round rejected any claim of overall frontier product leadership today:
public Alyx material suggests stronger shipped planning discipline, explicit
task-state semantics, harder completion gating, and better context-hygiene
mechanics than the local system currently demonstrates. The right next move is
to copy those runtime controls now, benchmark against Alyx's free tier and a
strong git baseline, and then run a reuse-oriented follow-up on public Arize
repos, noting that adjacent code appears split between MIT-licensed repos such
as `arize-skills` / `arize-harness-tracing` and `phoenix` under ELv2 rather
than a standalone open Alyx repository.

## Round 67: Moats for an Agent-First Forge
**Consensus:** The round rejected any claim that the project already has a
 meaningful moat: raw code hosting, repo portability, and agent-first workflow
 features are not durable defensibility by themselves. The only plausible moat
 category identified was a delayed learning / decision moat built from the
 correction cycle itself: cross-repo records of agent proposals, human
 rejection/approval reasons, repair patterns, trust allocation, and downstream
 outcomes. That data is more defensible than code alone because much of it is
 not recoverable from exported repositories, but the round also stressed that it
 is narrow, slow to build, and replicable in principle by rivals with enough
 usage. The credible investor story is therefore not "better hosting," but
 decision intelligence and trust signals for agent-mediated software
 production — and only if the project starts capturing the full proposal /
 deliberation / decision / outcome lifecycle now.

## Round 68: Non-Exported Trust Signals as Investor-Legible Value
**Consensus:** Non-exported trust signals can be a real value layer, but only if
 they are defined as operational workflow intelligence rather than vague social
 reputation. The round converged that the strongest examples are approval
 velocity, reviewer deference, routing preferences, outcome-linked trust
 trajectories, and org-specific taste / risk filters that do not live cleanly in
 exported repo state. Their value is in reducing coordination tax: better
 routing, less wasted review, lower merge friction for trusted work, and more
 scrutiny where risk is higher. The defensibility story is not a classic social
 network effect, but a moderate learning / switching-cost story around
 accumulated software judgment. The round strongly warned that this narrative
 only becomes investor-legible after the project proves measurable gains from
 trust-aware routing and review behavior.

## Round 69: Persistent Identity, Cross-Company Trust, and the Ethics of Power
**Consensus:** The round accepted that persistent identity and cross-company
 behavioral history could create real proprietary business value, especially for
 contractor vetting, reviewer routing, access control, and compliance-heavy
 enterprise workflows. But it strongly rejected fantasy claims of inevitable
 market dominance, treating the realistic upside as a bounded switching-cost and
 enterprise-differentiation layer rather than a universal monopoly. More
 importantly, the panel converged that the commercially strongest version of the
 idea is also structurally dangerous: cross-employer trust scoring can become a
 labor-surveillance and blacklist system with power asymmetry, mobility
 suppression, and opaque judgment over workers' futures. The overall conclusion
 was therefore not to normalize a universal developer reputation system, but to
 prefer much narrower, contextual workflow intelligence with hard constraints on
 visibility, contestability, retention, and use.

## Round 70: Borrowing from Multica and Conductor Without Reopening the Architecture
**Consensus:** The round treated both tools as useful validators of the existing
Round 62 split rather than as replacements for it. Multica is most useful as a
reference for board-centric execution UX: agents as visible assignees, local
daemons for subscription-backed CLIs, real-time status surfaces, and
 capability-style agent presentation. Conductor is most useful as a reference
 for durable execution semantics: persisted attempt lineage, retries, timeouts,
 replay / resume behavior, human-in-the-loop checkpoints, and a lightweight
 workflow-as-data discipline. The round rejected adopting either tool wholesale,
 rejected Multica as a code-reuse source due to license and stack mismatch, and
 treated Conductor as legally safer but still primarily a design-pattern source
 rather than an implementation dependency. The near-term implication is to
 encode these borrowings into the bulletin-board work-item schema, local daemon
 contract, and lightweight declarative task / round definitions while keeping
 `agent-roundtable` discussion-focused and leaving capability registry and
longer-term governance memory to Vaglio.

## Round 71: Repo-Embedded Skills as Deliberative Artifacts
**Consensus:** Repo-embedded skills are worth adding, but only as a narrow,
explicit artifact type for reusable execution knowledge rather than as a vague
prompt pile or new plugin system. The converged split was: roundtable proposes
and ratifies, board/orchestrator resolves and attaches exact versions at task
time, and Vaglio owns cross-repo lineage and shared governance. Skills must stay
vendor-neutral, explicitly versioned, transparently activated, logged in task
history, and supersession-aware. The biggest risks are hidden behavior, stale
repo-local assumptions, and scope creep into covert capability grants or ambient
agent-local behavior.

## Round 72: Obsidian as Interface, Not Canonical Memory
**Consensus:** Obsidian is valuable as an optional downstream interface for
human browsing and some local agent workflows, but it must not become the
canonical memory or governance layer. Canonical truth should remain in
repo-managed markdown, explicit structured records, and related repo-native
metadata rather than vault-local state, plugins, or `.obsidian` conventions.
The strongest recommended pattern is one-way export from canonical memory into a
derived Obsidian view. The round supported borrowing formatting/export
conventions and treating `obsidian-cli` as a local optional bridge, while
rejecting making the Vaglio appliance depend on a running Obsidian/Electron app.

## Round 73: A Deliberation Graph Index, Not a Canonical Graph
**Consensus:** The project should add a graph layer only as a derived index over
canonical records, not as the source of truth. Chronological prose remains the
legitimacy and audit surface, while the missing canonical layer is explicit
structured records for decisions, incidents, fixes, invariants, and work-item
lineage. The graph's job is bounded retrieval and navigation: helping agents
find the right active records and supersession chains without replaying the full
archive. Graphify is useful mainly as a design-pattern source for extraction /
build / report / export, not as the right canonical deliberation substrate.

## Round 74: The Natural Repo-Native Knowledge Base
**Consensus:** There is a real repo-native knowledge base here, but it is the
explicit, versioned, supersession-aware record set in the repo rather than "the
graph" or whatever an agent reconstructs from context. The natural canonical
units are rounds, decisions, invariants, incidents, fixes, work items, and
concrete `jj` changes, linked by explicit traceability and replacement
relationships. `jj`-native supersession materially strengthens this model by
making "what replaced what, and why" first-class rather than accidental.
Graphify-like tools should remain derived viewers / study aids / query surfaces
over that explicit record layer, not a hidden inferred authority that recreates
implicit state in a new form.

## Round 75: DBOS, Temporal, and the Durable Execution Boundary
**Consensus:** The project should stay mostly BEAM-native for now, but only if
 it stops confusing OTP supervision with durable execution and explicitly proves
 Temporal-like guarantees in its own persistence layer. Temporal was treated as
 the clearest reference model for what "real" durable execution means
 (persisted history, replay/resume, visibility, workflow/activity boundaries),
 but as too architecture-shaping to adopt as a core dependency in the current
 BEAM/Jido board-daemon design. DBOS was treated as the more relevant comparator
 because its in-process library plus persistence-substrate model is closer to
 the local direction, though still a poor direct dependency fit due to the
 TypeScript/Postgres versus Elixir/Dolt mismatch. The strongest next step is not
 more theory but hard validation: crash-recovery drills, replay semantics,
 idempotency/duplicate-delivery tests, durable timer tests, and operator-grade
 history inspection that prove the local model is truly durable rather than only
 well supervised.

## Round 76: Open Agent Skills Standard and Project Alignment
**Consensus:** The project has not actually adopted the open Agent Skills
standard yet; it has only reached a very similar concept independently through
Round 71. The round concluded that this is a strong argument for adopting the
external `SKILL.md` directory/file format at the artifact layer rather than
inventing a private near-clone, because the standard is simple, portable, and
already broadly supported across agent clients. However, the project's local
requirements remain stricter than the base format: activation must still be
resolved explicitly by the board/orchestrator, logged in attempt history, and
governed by local policy rather than by anything embedded in the skill file.
MCP was treated as a separate connectivity protocol for tools/data/workflows,
not a skill format; Swarm / Agents SDK and Microsoft Agent Framework were
treated as orchestration/runtime references rather than the project's governing
abstraction. The strongest next step is a narrow adapter: repo-local `SKILL.md`
ingestion plus explicit board fields such as `required_skills`,
`recommended_skills`, and `resolved_skills`, with `allowed-tools` treated as
advisory rather than authoritative.

## Round 77: Skill Candidates for `unified-nix-configuration` and `nix-router-optimized`
**Consensus:** Both repos justify skills, but not the same kind. The shared
overlap is real, but narrow: low-authority Nix workflow loops such as flake
validation, targeted eval/test selection, queue/onboarding conventions, and
  docs/examples synchronization. The more dangerous or environment-specific areas
  should stay repo-local: rebuild discipline, secret/identity lifecycle, host and
  remote execution context, router management-plane smoke checks, router
  diagnostics interpretation, and source-of-truth boundary awareness. The round
  strongly rejected treating raw commands like `nix flake check`,
  `nixos-rebuild`, or generic "network diagnostics" as skills by themselves;
  they only become skills when wrapped in explicit entry criteria, boundaries,
  expected outputs, and stop conditions. The strongest practical next step is to
  start with one or two shared low-risk skills and one or two repo-local skills,
  prove reuse, and avoid jumping straight to a large dedicated shared-skills
  repo.

## Round 78: `gstack` Retention and Standards Fit
**Consensus:** `gstack` should not remain as active local tooling. The local
environment no longer depends on it, and its continued presence mainly creates
confusion about whether it is part of the supported workflow. The round treated
it as only superficially adjacent to the open Agent Skills standard: it shares
`SKILL.md` naming and directory packaging, but diverges materially through
host-specific runtime assumptions, executable preambles, and product-specific
metadata and activation behavior. The strongest keep-case is not "keep it
installed," but "keep it only as archive/reference material" so the project can
mine a few useful ritual ideas around planning, review, and QA. The strongest
next step is to either archive or remove the `gstack` tree from the active skill
path, audit for lingering config hooks, and rewrite any genuinely useful rituals
from scratch as narrow, standards-aligned local `SKILL.md` artifacts.

## Round 79: Fit, Productive Friction, and the Ethics of Behavioral Matching
**Consensus:** The round accepted the strongest positive case: bad
 programmer-project and programmer-company matching causes real economic and
 human harm, and some projects genuinely need contributors who tolerate or even
 generate high technical friction in productive ways. But it also converged that
 this does **not** justify durable person-level fit or friction profiling. The
 only ethically defensible version is a narrow local workflow assistant: recent,
 contestable, object-scoped signals about work contexts, team appetite for
 challenge, and project-local routing needs. "Productive friction" may be
 represented only as a property of a lane, subsystem, redesign track, or recent
 contribution interaction inside one org/project — not as a portable trait of a
 human. Cross-employer durable identity/profile products remained firmly out of
 bounds as blacklist and labor-surveillance infrastructure. The strongest next
 step is to frame any future work here as workflow assistance and self-declared
 project-local preference/routing, while explicitly ruling out person scores,
 culture-fit inference, and any exportable behavioral dossier.

## Round 80: Credit Scoring as Comparison, Precedent, or Warning Sign
**Consensus:** The round treated credit scoring as a useful comparison mainly
 because it shows how opportunity-gating metrics become normalized, regulated,
 and still ethically troubling. It did **not** treat credit scoring as moral
 legitimation for programmer-fit or behavioral scoring. The analogy is valid at
 the structural level: both systems compress history into signals that can gate
 access to important opportunities, create opacity and power asymmetry, and
 drift from narrow use into broader gatekeeping. But the analogy also breaks in a
 way that makes programmer scoring worse: repayment history is already imperfect
 and unequal, yet still more discrete and partially verifiable than highly
 contextual collaboration, dissent, review tone, escalation, and "fit"
 judgments. FCRA-like safeguards such as disclosure, dispute rights,
 adverse-action notice, and purpose limitation were treated as helpful but far
 from sufficient, because the core problem is not only due process but the
 subjectivity of the underlying data. The strongest implication is unchanged
 from Round 79: stay with project-local or org-local workflow assistance using
 recent, contestable, expiring process signals, and keep person-level or
 portable scoring/reporting out of bounds.

## Round 81: Ecosystem Pragmatism and Queryable Behavioral Data
**Consensus:** The round accepted the maintainer's pushback that "ability to
 build effectively on existing ecosystems and useful external assets" is more
 concrete and professionally relevant than vague culture-fit or personality
 scoring. Reuse judgment, interoperability, incrementalism, and avoiding
 needless reinvention were all treated as real engineering strengths that
 hiring managers and open source maintainers may legitimately care about. But
 the round also converged that this does **not** justify passive accumulation
 and query answering over cross-context behavioral data. The key distinction is
 evidence form: public code artifacts, explicit references/endorsements,
 candidate-curated architectural portfolios, and project-local trust records
 can all represent this trait in inspectable, contextual ways. What remains out
 of bounds is a platform that infers or aggregates person-level "ecosystem
 judgment" across employers or projects and answers hiring or committer queries
 from that dossier. Hiring remained the hardest red-line case; open-source
 maintainer trust was treated as somewhat narrower but still properly grounded
 in local project evidence rather than portable behavioral reputation.

## Round 82: Private Code, Better Matching, and Privacy-Preserving Attestations
**Consensus:** The round accepted that proprietary hosted code creates a real
 evidence problem: public artifacts are often unavailable, so evaluators are
 pushed toward proxies. But it rejected the idea that this makes portable
 worker scoring or behavioral dossiers ethically acceptable. Instead, the most
 promising middle ground was a candidate-controlled attestation layer:
 selective disclosure, verifiable credentials, scoped endorsements, and
 employer-issued factual claims that let a worker prove bounded facts without
 exposing underlying confidential code. The round emphasized that such
 attestations help with verification, not with resolving the deeper
 subjectivity problem, and therefore still do **not** justify scores. The
 practical line became: candidate-controlled, claim-specific, time-bounded,
 non-aggregatable evidence may be defensible; cross-employer portable scores,
 queryable behavioral profiles, hidden telemetry aggregation, and any
 worker-credit-style reputation layer remain out of bounds.

## Round 83: OpenTUI as Optional UX, Not Core Architecture
**Consensus:** OpenTUI is a useful reference point for a richer terminal
operator surface, but it is not the project's missing architectural layer. The
real core remains the board/API/memory split already established in earlier
rounds. OpenTUI's component-oriented terminal model is attractive mainly as an
optional local client for board visibility, not as a canonical UI or a new core
runtime commitment. Its Bun/TypeScript/Zig assumptions were treated as too
opinionated for the main platform path today. The practical recommendation is to
keep any future TUI optional and subordinate to the board service.

## Round 84: DSPy Patterns Without DSPy Runtime Adoption
**Consensus:** The project should not adopt DSPy itself as a core dependency,
but it should borrow the best part of DSPy's design: explicit
signature-and-validation discipline for bounded agent operations. The strongest
local application is a repo-native layer of research-operation artifacts for
tasks like retrieval, evidence evaluation, synthesis, and contradiction
checking, each with explicit inputs, outputs, provenance, validation examples,
and supersession. Automatic prompt optimization and opaque tuned behavior were
treated as misaligned with the project's emphasis on inspectability and governed
memory.

## Round 85: `jj` Ergonomics Plus Stronger Agent Discipline
**Consensus:** The Ellie Huxtable `jj` note validated the project's practical
change-centric instincts: start new work explicitly, treat changes as the
durable unit, return to old work via `jj edit`, and use `jj undo` as a real
recovery path. But the round also stressed that those human ergonomics are not
enough by themselves for agent work. The local practice must add explicit
supersession markers, path-scoped metadata, conflict visibility, delta-based
resume patterns, and more intentional bookmark discipline. The immediate result
was to update `docs/JJ_GUIDE.md` so these habits become concrete repo practice
rather than informal preference.

## Round 86: Taste-Weighted Vouching Without Prestige Capture
**Consensus:** The round rejected "good taste" as a legitimate first-class
ranking primitive because it collapses too easily into prestige, clique rule,
and covert person scoring. Popularity alone was treated as a weak proxy for
quality, but the inverse romantic error was also rejected: obscurity or slow
recognition do not prove brilliance by themselves. The narrowest acceptable
alternative is recent, domain-specific, claim-scoped vouch calibration on
similar object types, with strong decay, visible sample size, explicit basis,
and zero portability across projects or employers. The round also stressed that
if the project wants to preserve space for slow-burn brilliance, it needs
novelty lanes and promises-vs-outcomes tracking rather than elite taste panels
or mass-appeal metrics.
**Addendum:** A person may build *local* credibility by vouching well on similar
objects, but only as a revocable, domain-specific calibration signal rather than
as general status. The round also rejected preference signaling as a recommended
path to recommendation: merely expressing taste or alignment is coalition signal,
not evidence. Preferences become legitimate only when attached to explicit
reasons, expected failure modes, and outcomes that can later be checked. A
further refinement distinguished **predictive** vouches from merely **late
correct** ones: once recognition is already broad, a new vouch usually measures
consensus-reading or winner attachment more than foresight unless it adds an
independent basis beyond the visible trend.

## Round 87: `jj` Graph Events as Prediction-Calibration Evidence
**Consensus:** The `jj` graph should be treated as an evidence trail for whether
 explicit predictions held up, not as a proxy popularity graph. The legitimate
 calibration surfaces are object/process outcomes such as merges, supersessions,
 reversions, conflict resolution, maintenance burden, and replication across
 contexts. The round recommended extending change descriptions and vouch records
 with explicit prediction IDs, scope, expected properties, expected failure
 modes, basis, expiry, and later outcome links. It also reinforced the recent
 distinction between **predictive**, **confirmatory**, and **coalitional**
 vouches: only early, explicit, basis-rich predictions should strongly affect
 anticipatory calibration, while late consensus-stage updates without new
 evidence should be treated mainly as confirmation or possible cascade
 participation. All aggregation must remain internal, recent-windowed,
 subsystem-scoped, sample-size-visible, and non-portable.

## Round 88: Resource-Scoped Single-Writer Discipline
**Consensus:** The project should not use a blunt host-wide or repo-wide lock to
 stop all concurrent work. Parallel branch work and read-only inspection remain
 desirable. The real exclusivity boundary is narrower: only mutating actions on
 the same live resource should require single-writer discipline. The round
 approved the recent `vaglio` wording in spirit but refined it into a
 resource-scoped rule: deploys, rebuilds, restarts, migrations, cache-warming,
 failover drills, and similar live mutations on the same target must serialize,
 while unrelated branch work should continue. The round also concluded that this
 policy belongs not only in queue prose but eventually in board / daemon runtime
 semantics via resource-level leases or affinity constraints.

## Round 89: Markdown Canonical, Structured Derived, Board-Enforced
**Consensus:** Markdown should remain the canonical human-readable memory format
for round archives and design rationale because it is legible, diffable,
portable, and naturally compatible with repo history and `jj` supersession. But
markdown alone is not enough for high-quality machine retrieval, tag search,
prediction/outcome joins, or enforceable contention control. The recommended
model is a hybrid: canonical markdown for long-form memory, derived structured
indices for query/search, and canonical board tables for operational state such
as work attempts, leases, workflow rules, and resource claims. The round also
answered the lock question directly: resource contention rules belong in the
bulletin board / daemon orchestration layer, not in prose docs alone.

## Round 90: Compete Above Search with Lineage-Aware Decision Memory
**Consensus:** Sourcegraph Deep Search is strong at semantic discovery and
 agentic whole-codebase understanding, and the project should not overclaim
 against that. The credible differentiator is narrower and higher-level:
 lineage-aware memory around code change. For agent-heavy teams with already
 quality-filtered internal code, the valuable enhancement is not "find the code"
 but "recover why this code is shaped this way, what replaced what, what was
 rejected, which constraints are current, and which judgments later held up."
 The round endorsed product directions like subtree-bounded constraint queries,
 current-guidance/replacement surfaces, rejection-reason retrieval, and
 prediction-to-outcome calibration. It rejected pitch language that sounds like
 VCS ideology or semantic-search one-upmanship. The addendum concluded that
 direct integration with Sourcegraph does make sense because Sourcegraph already
 exposes API and MCP surfaces for search, history, file access, and Deep Search;
 the right sales story is complementarity rather than replacement. Sourcegraph
 remains the discovery plane, while the lineage-aware system becomes the
 decision-memory plane that attaches local constraints, rejected alternatives,
 supersession, and outcome history before and after changes.

## Round 91: Bun's Rust `unsafe` Cleanup as a Search-vs-Memory Case Study
**Consensus:** Bun's Zig-to-Rust migration sharpened the comparison rather than
 weakening it. For the first-order task — finding `unsafe` regions, FFI-heavy
 boundaries, similar patterns, and migration hotspots — Sourcegraph is plainly
 stronger and the local system should not pretend otherwise. The differentiated
 value begins only after discovery: classifying which risky regions are
 intentional versus temporary migration residue, preserving prior cleanup
 proposals and rejection reasons, and linking new cleanup predictions to later
 benchmark, regression, merge, revert, or incident outcomes. The best product
 story is therefore a layered unsafe-audit workflow: Sourcegraph finds the risky
 Rust; the lineage-aware layer remembers what the team learned while trying to
 clean it up.

## Round 92: Open-Source Security Disclosure in the AI Era
**Consensus:** The old disclosure equilibrium is under real pressure because
 AI-assisted diffing and exploit-hypothesis generation compress patch-to-exploit
 time, but the answer is not a blanket retreat into long private branches. The
 converged answer was severity-based, short, auditable embargoes only for narrow
 critical cases, combined with stronger security-native coordination primitives:
 private security workspaces, cryptographic commitments, time-bounded
 disclosure metadata, downstream notification graphs, and full later
 transparency. The product opportunity is coordinated disclosure and release
 control infrastructure, not a permanently less-open forge.

## Round 93: Sourcegraph as Optional Power, Not Canonical Forge Search
**Consensus:** The successor to GitHub should probably not make Sourcegraph the
 default search engine. Search is too core to forge UX, permissions, economics,
 and product learning to outsource as the canonical substrate. GitHub's own
 public rationale for Blackbird shows that it did not simply miss the
 opportunity; it treated code search as strategic, uniquely code-specific, and
 scale-sensitive enough to justify a first-party engine. The opening for
 Sourcegraph is still real, but narrower: cross-host enterprise discovery,
 optional deep-intelligence augmentation, and integration into a product whose
 differentiated moat lives above search in lineage-aware decision memory.

## Round 94: Adaptive Agent Routing Beats a Single Search Default
**Consensus:** For agents, the economically relevant question is not "which
 search UX is nicer," but which retrieval backend creates the most end-to-end
 task surplus after accounting for query cost, latency, dependency risk, and
 downstream token savings. Sourcegraph can be worth paying for on hard semantic,
 cross-repo, history-heavy, or high-value tasks where better retrieval reduces
 retries and wrong turns. But GitHub search is likely already good enough for
 many cheap, narrow, GitHub-local lookups. The strongest answer is therefore
 adaptive escalation, not a universal Sourcegraph default.

## Round 95: Let the Host Assist Escalation, But Keep Routing Inspectable
**Consensus:** It does make sense for the code host to participate in adaptive
 escalation, because the host has cheap local signals about result quality,
 symbol/path confidence, cross-repo breadth, coverage, and query flailing that
 can improve surplus-sensitive routing. But the host should not become a hidden
 monopoly router. The preferred design is host-assisted adaptive routing:
 native results plus inspectable confidence/escalation hints, with agent or
 operator override and without hardwiring a single premium retrieval vendor.

## Round 96: Build Beats Hold-Up, Buy Only If You Want the Whole Company
**Consensus:** Vertical integration is the cleanest long-run answer to
 Sourcegraph hold-up risk if search is a core host capability. Semantic search
 is not uniquely proprietary as a concept, so a serious platform is not doomed
 to dependence forever. But execution still matters enough that transition
 strategy matters in practice. Acquiring Sourcegraph is not automatically the
 right answer: it makes sense only if the buyer wants broader enterprise
 code-intelligence assets, product surface, and customer relationships rather
 than merely a narrow semantic-search feature.

## Round 97: Hayek Beats the Giant Routing Planner
**Consensus:** The Hayek knowledge-problem analogy is useful for routing. The
 key facts needed for adaptive escalation are dispersed across host, runtime,
 provider, operator, and current task conditions. Trying to bake too much of
 that into ever-larger models risks turning the model into a pseudo central
 planner that guesses live costs and local conditions poorly. Host-assisted
 routing with explicit price-like and confidence signals is the better economic
 architecture: the model still exercises judgment, but does so using distributed
 information rather than pretending to internally encode the whole search
 economy.

## Round 98: Hosted Analysis Control Plane, Pluggable Analysis Engines
**Consensus:** Heavy dangerous-code analysis such as Rust unsafe/UB auditing is
 best treated as a hosted platform capability, not as a giant repo-embedded
 skill. The host should own the control plane: identity, policy, scheduling,
 durable evidence storage, lineage-aware memory, reviewer UX, and the final
 release gate. But the execution plane can remain plural: first-party, self-
 hosted, and third-party specialist analyzers should all be able to contribute
 findings behind a host-owned provider contract with normalized evidence,
 provenance, replay metadata, and policy-aware ingestion. Repo-local skills
 remain useful only as narrow adapters for scope hints, suppressions, local
 reproducibility, and interpretation.

## Round 99: `jj` Helps the Audit Trail, Not the Raw Runner Compromise
**Consensus:** Mini Shai-Hulud does not show that a `jj`-based forge is innately
 safe. The initial failure is mainly a host/CI/release-control-plane failure:
 over-privileged workflow execution, cache trust, and publish authority too
 close to compromised compute. `jj` does not directly stop that. But it can
 materially improve containment, rollback, release binding, and forensics via
 immutable operation history, explicit rewrite lineage, and policy keyed to
 change identity rather than mutable branch state. The package ecosystem still
 has independent responsibilities for quarantine, revocation, safer install
 defaults, and downstream containment. The strongest product answer is therefore
 dual: host-native release-authority separation and lineage-aware incident
 control on the forge side, plus ecosystem-native quarantine/revocation
 mechanics on the package side.

## Round 100: Stricter CI Providers Help, But Release Authority Separation Matters More
**Consensus:** Several alternative CI/CD providers likely would have narrowed the
 first stage of a Mini Shai-Hulud-style attack through stricter defaults around
 fork isolation, secret withholding, protected-resource access, and explicit
 escalation. GitLab's fork-runs-in-fork model, CircleCI's default no-secrets for
 forked PRs, Buildkite's explicit distrust of public forks, and Azure
 Pipelines' scoped identities and fork protections all look safer than a badly
 configured `pull_request_target` pattern. But none of that is the full answer:
 the deeper lesson is architectural, not vendor-branded. A serious forge must
 treat release authority as a separate trust domain from ordinary CI, with
 explicit trust-tier transitions, separate publish-capable identity, and no path
 from untrusted contribution execution to trusted release merely because a
 workflow succeeded.

## Round 101: Better Runner Substrate, Same GitHub Control Plane
**Consensus:** Depot and Blacksmith both improve materially on plain
 GitHub-hosted runners by using ephemeral isolated runner substrates. But they do
 not replace GitHub's higher-level workflow and release control plane. On the
 specific Mini Shai-Hulud chain, Blacksmith appears stronger than Depot because
 branch/tag cache scoping is safer by default, while Depot's default shared
 branch namespace leaves a more meaningful cache-poisoning path open. The deeper
 lesson is that runner hardening is valuable hygiene, and safe-by-default cache
 trust boundaries are even better hygiene, but neither substitutes for host-
 native separation of CI execution from trusted release authority.

## Round 102: Real Design Win, But Only If Security Is Mostly Invisible
**Consensus:** A clean-break forge that separates release authority from
 ordinary CI is addressing a real design flaw, not merely an ergonomics nuisance
 or branding exercise. The flaw is structural: the same automation surface too
 easily evaluates change and reaches publish authority. But starting fresh is not
 an automatic easy win. It only becomes attractive if the platform turns that
 safer architecture into lower visible operator burden than today's retrofitted
 npm/GitHub security stack. The market risk is substantial: if the design feels
 like enterprise security ceremony, migration toil, or more policy surfaces,
 developers will treat it as another security tax. The winning product shape is
 therefore zero- or near-zero-config trusted publishing with progressive
 disclosure, host-managed release controls, and less bespoke hardening work for
 maintainers rather than more.

## Round 103: Codeberg Helps on Entry-Point Trust, Not the Whole Architecture
**Consensus:** Codeberg, specifically Codeberg + hosted Woodpecker, is safer than
 common GitHub Actions practice on the early Mini Shai-Hulud trust failure
 because Woodpecker withholds secrets from pull requests by default and narrows
 the usual ambient-trust mistakes. But the panel did not treat Codeberg as a
 universal migration answer. Codeberg's hosted Forgejo Actions are explicitly
 constrained by security issues and bus factor, while Woodpecker's operational
 maturity and RBAC are limited. Most importantly, Codeberg does not clearly solve
 the deeper architecture problem: release authority still needs to be separated
 from ordinary CI. The recommendation was therefore segmented rather than
 universal: Codeberg + Woodpecker is a reasonable move for smaller open-source
 teams that value safer defaults and can tolerate rough edges, but security-
 sensitive organizations and low-friction teams should not treat “move to
 Codeberg” as the decisive answer to this vulnerability class.

## Round 104: Specialists Largely Confirm the Control-Plane Diagnosis
**Consensus:** Outside specialist commentary mostly reinforced the existing local
 conclusion rather than displacing it. Public exploit-theme lists and GitHub
 hardening checklists are useful, but they mostly operate at the hygiene layer.
 Hardware enclaves and stronger runner isolation are valuable substrate hardening,
 but neither is sufficient because they do not fix authorization semantics: a
 securely isolated build environment can still produce and sign malicious output
 if the wrong workflow state is allowed to count as trusted release authority.
 The strongest outside diagnosis is therefore the control-plane diagnosis: valid
 provenance can truthfully attest to malicious output when the release-control
 plane is mis-scoped. The product opportunity remains real if it truly moves
 release trust out of workflow YAML into a host-native policy plane with explicit
 trust tiers, cache boundaries, and lineage-aware promotion — but the main
 overclaim risk is usability. If the result feels like more governance plumbing
 rather than less bespoke security work, the architecture may be right while the
 product still fails.

## Round 105: A Major Zig→Rust Port Should Be Run as a Translation-Knowledge Program
**Consensus:** If a major rewrite like Bun’s Zig→Rust port is meant to produce
 reusable value for future model-assisted translation work, leadership should not
 treat it as a one-off heroic port with some notes left over. It should be run
 as an explicit translation-knowledge program: the unit of progress is a
 validated translation slice or construct class, not merely a converted file. An
 initial type/idiom mapping document is a strong seed, but it only becomes
 durable value if it is turned into a versioned playbook tied to examples,
 counterexamples, semantic invariants, test evidence, benchmark deltas, and
 scope labels. The reusable outputs should be deliberately separated into
 canonical retrieval-time doctrine, carefully filtered training examples,
 anti-pattern/rejected examples, and held-out evals. The main failure mode is
 organizational: if schedule pressure demotes corpus curation, rejection
 logging, and semantic/performance evals into optional clerical work, the team
 may still ship a good Rust port while failing to extract a reusable translation
 method.

## Round 106: JEPA-Like Modules Fit Better Under LLM-Centered Porting Stacks
**Consensus:** The panel did not support a near-term bet that JEPA-style or
 world-model-heavy systems will displace LLM-centered stacks for large code
 ports such as Zig→Rust or C/C++→Rust. The stronger convergence was a hybrid
 architecture: LLMs remain the top-level generator, repair loop, and interactive
 interface, while JEPA-like or other semantic modules may help on narrower
 subproblems such as unsafe code, layout/ABI risk, concurrency, and
 performance-sensitive translation. The panel also converged that “world model
 of hardware” is mostly the wrong abstraction for ordinary source-to-source
 translation, and that the right next move is experimental benchmarking on top
 of the translation-knowledge program described in Round 105 rather than a
 world-model-first architecture bet.

## Round 107: Keep Markdown Canonical, Add HTML Only for Browse-Heavy Surfaces
**Consensus:** The panel rejected a broad shift from agent-produced Markdown to
 HTML as the default documentation mode. Markdown should remain canonical
 because it is easier to diff, patch, grep, and maintain in repo-native
 workflows. HTML is justified only as a companion view for a narrow class of
 browse-heavy documents that humans consume nonlinearly. All voices agreed that
 `historical-synthesis.md` is such a document and should have an HTML companion.
 The second candidate produced real disagreement: Codex favored the router
 discussions index as a browse surface, Gemini favored the dense
 `DECLARATIVE_CLAT.md` design spec, and DeepSeek favored the operational
 discussion-leader summary. The implemented follow-up kept the unanimous
 `historical-synthesis` conversion and chose `DECLARATIVE_CLAT.md` as the second
 HTML companion because it is the strongest long-lived hierarchical design
 document among the disputed candidates, while queues, short operational notes,
 and ordinary round records remain Markdown-only.

## Round 108: Pi Is a Useful Second Harness, Not the New Primary One
**Consensus:** The panel rejected a simple “replace OpenCode with Pi” story.
 Pi's strongest value is as a thin bring-your-own-key harness for bounded
 one-shot runs: explicit provider/model selection, stateless invocation, and
 JSON-friendly output make it attractive for API-key-backed seats that do not
 need a vendor-tuned CLI. But the round also converged that OpenCode remains
 more useful for this project's specific free-model history because it already
 demonstrated access to curated free voices, while the live Pi seat failed
 locally with `No models available` and unverified model hydration. DeepSeek did
 not move: the earlier local decision still stands that direct HTTP/API
 integration is cleaner than routing DeepSeek through either OpenCode or Pi for
 ordinary one-shot rounds. The practical recommendation was therefore a
 disciplined hybrid boundary: keep vendor CLIs for serious named seats, keep
 direct HTTP for DeepSeek, keep OpenCode for free-model experiments and future
 session-backed server use, and add Pi only as an opt-in secondary harness for
 BYOK provider experiments after real credentialed verification.

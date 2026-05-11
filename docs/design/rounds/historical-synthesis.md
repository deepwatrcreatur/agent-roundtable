# Vaglio Historical Synthesis: Genuine Follow-Up Rounds

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

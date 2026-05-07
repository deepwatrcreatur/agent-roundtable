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

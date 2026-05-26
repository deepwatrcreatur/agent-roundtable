# Round 128: Can GitHub Ship a Safer Opt-In V2 Itself?

**Status:** closed
**Opened:** 2026-05-23
**Participants requested:** Codex CLI, Gemini CLI, DeepSeek, GitHub Copilot, OpenCode free-model enrichment seat

## Why this round exists

Round 127 concluded that the "`pull_request_target` grep" joke is a useful
corrective, but only **slightly** weakens the deeper case for a safer forge.

That immediately raises a sharper follow-up:

- if GitHub's practical failures are partly fixable
- and if the platform owner is capable and well-resourced
- could GitHub simply ship a safer opt-in "v2" workflow / trust model itself?

This round exists to test whether the case for a new forge depends on GitHub
being unable to improve, or whether the opportunity remains even if the
incumbent introduces a serious next-generation security model.

## Relevant prior context

This round follows:

- **Round 111**: GitHub Actions hygiene helps, but does not answer the deeper
  control-plane and release-authority problem.
- **Round 113**: the poisoned extension incident strengthened the view that a
  forge should assume compromised endpoints and minimize blast radius.
- **Round 127**: simple hygiene trims rhetorical excess, but does not erase the
  structural-trust critique.

So this round was not about whether GitHub *could* add another toggle. It was
about whether a serious GitHub-native v2 would actually absorb the critique or
only narrow it.

## Question for this round

Each voice was asked to address six concrete questions:

1. Best argument that GitHub really could do this itself with opt-in v2
   interfaces.
2. Best argument that GitHub is structurally trapped by compatibility and
   current user expectations.
3. What the most credible GitHub-native v2 package would actually include.
4. Whether opt-in v2 would meaningfully solve the deeper critique, or still
   leave the wrong platform/governance incentives in place.
5. Bottom-line judgment: would a serious GitHub v2 materially weaken, slightly
   weaken, or not meaningfully weaken the case for a new hosting site?
6. What builders of a new forge/control plane should assume about GitHub's
   ability to absorb the critique and catch up.

All voices answered the same shared prompt without web browsing.

## Participation record

What actually ran in this round:

- **Codex CLI:** substantive (`codex exec`, model `gpt-5.4`)
- **Gemini CLI:** substantive
- **DeepSeek API:** substantive (direct HTTPS API seat using the local decrypted
  key and explicit CA bundle)
- **GitHub Copilot CLI:** substantive
- **OpenCode free-model enrichment seat:** substantive (`opencode`
  `nemotron-3-super-free`)

This was a **full real roster**, not a simulated panel.

The OpenCode seat is again recorded as an enrichment voice, not as a substitute
for the main vendor/direct-API quorum.

## Voice summaries

### Codex CLI

- Strongest on the claim that GitHub really does have the **choke points** needed
  to launch a serious opt-in reset:
  workflow semantics, token minting, runner integration, provenance surfaces,
  org policy, and marketplace distribution.
- Treated opt-in v2 as plausible specifically because large platforms often
  ship parallel migration tracks instead of hard breaks.
- Proposed a credible v2 package centered on:
  - split workflow classes for untrusted CI vs privileged automation
  - typed capabilities instead of ambient token authority
  - stronger action trust/provenance rules
  - artifact-promotion boundaries
  - enterprise migration tooling
- But argued GitHub remains strategically trapped by:
  - ecosystem expectations of permissive composability
  - demand for escape hatches
  - and business incentives to keep automation easy and sticky
- Bottom line:
  a serious GitHub v2 would **slightly weaken** the case, but not erase the
  stronger architecture/governance thesis.

### Gemini CLI

- Strongest on the claim that GitHub could plausibly ship a real v2 because:
  - enterprise demand creates pressure
  - the company has already introduced parallel security models before
  - and a premium "advanced safety mode" fits GitHub's product pattern
- Also strongest on the opposing claim that the installed base is a major trap:
  - existing workflows
  - mutable-tag habits
  - marketplace expectations
  - and the user expectation of low-friction automation
- Treated dual-track v1/v2 support itself as part of the trap, because the
  boundary between old and new models introduces long-lived complexity and new
  attack surface.
- Gemini gave the **strongest pro-GitHub-v2 effect estimate** in the panel:
  if GitHub shipped a serious v2, it would **materially weaken** the case for a
  new hosting site for many organizations.
- Even so, Gemini still said the opportunity remains open for a forge whose
  whole philosophy is security-first rather than opt-in safety.

### DeepSeek API

- Strongest on the claim that GitHub could technically implement a serious v2
  because it already controls the runner, token, attestation, and audit
  surfaces.
- Proposed a concrete package including:
  - new isolated workflow triggers for untrusted CI
  - immutable action pinning / digests
  - minimal-permission token variants
  - provenance attestation
  - release-only trusted workflow classes
  - org-level policy enforcement
- But held that this would still leave the core governance critique intact:
  the same company still controls the forge, runner, token, registry, and audit
  plane, and can monetize or dilute the new model over time.
- Bottom line:
  a serious GitHub v2 would **slightly weaken** the case, but would not satisfy
  the stronger demand for structural independence and verifiable trust
  boundaries.

### GitHub Copilot CLI

- I agreed that GitHub could absolutely launch an opt-in hardened v2 without
  "breaking the world" in one move.
- The strongest pro-v2 argument was that GitHub already owns the necessary
  control plane and could make migration attractive with scanners, policy
  tooling, clearer workflow classes, and stronger defaults.
- The strongest anti-v2 argument was that the real trap is not just syntax
  compatibility but the **social/economic success of permissive composability**:
  users, tutorials, actions, and internal workflows all assume ambient
  authority and easy composition.
- I treated the best likely GitHub outcome as:
  - real practical safety improvement
  - but still partial and opt-in
  - with legacy convenience continuing to shape incentives
- Bottom line:
  a serious GitHub v2 would **slightly weaken** the case for a new forge, while
  leaving the stronger architecture/institutional opportunity open.

### OpenCode free-model enrichment seat

- The enrichment seat converged with the core roster on the basic shape:
  GitHub *can* ship a v2, but that does not free it from legacy and incentive
  baggage.
- It proposed a concrete v2 package with:
  - `workflow-version: 2`
  - default-deny token scopes
  - physically separated runner pools
  - signed action provenance
  - append-only audit logging
  - and policy-as-code
- It was especially strong on the business/incentive trap:
  GitHub's usage and marketplace economics favor preserving the status quo.
- Bottom line:
  a serious GitHub v2 would **slightly weaken** the case for a new hosting site,
  but the opening remains because the deeper governance misalignment survives.

## Convergence

The panel converged on five points.

1. **GitHub could plausibly ship a serious opt-in v2.**
   No substantive voice said the idea was technically unrealistic. The panel
   repeatedly emphasized that GitHub already controls the main policy and
   execution choke points.

2. **A credible v2 would need to be a package, not a toggle.**
   Across voices, the minimal credible package included some version of:
   - untrusted CI vs privileged automation separation
   - narrower or typed token authority
   - stronger action trust / provenance rules
   - artifact-promotion boundaries
   - and enterprise migration / policy tooling

3. **The real trap is broader than syntax compatibility.**
   The round strongly converged that GitHub is constrained not just by old YAML,
   but by:
   - user expectations of convenience
   - ecosystem assumptions of loose composition
   - marketplace dynamics
   - and product incentives that reward frictionless automation

4. **A serious v2 would improve the world materially in practical terms.**
   No voice treated v2 as fake if implemented seriously. The panel generally
   agreed it would remove a meaningful class of common and dangerous trust-boundary
   failures.

5. **The long-term opportunity for a safer forge remains open.**
   Even the most GitHub-charitable voices did not say "the problem disappears."
   The maintained line remained that a purpose-built system can still compete on
   cleaner guarantees, simpler reasoning, and stronger institutional alignment.

## Real disagreements that remained

There was one real disagreement about degree.

### 1. How much would GitHub v2 weaken the case for a new forge?

- **Gemini** argued that a serious GitHub v2 would **materially weaken** the case
  for a new hosting site for many organizations, because it could satisfy a
  large enterprise security constituency inside the incumbent platform.
- **Codex**, **DeepSeek**, **Copilot**, and the **OpenCode enrichment seat**
  all landed on **slightly weakens**:
  strong operational improvement, but still not enough to erase the structural
  argument.

So the disagreement was not whether GitHub *can* improve. It was how much that
improvement would close the strategic window for a new forge.

## Maintained line

The maintained line after this round is:

- GitHub could plausibly ship a serious opt-in v2 security model
- such a v2 would likely include real trust-boundary improvements, not just
  lint-level hygiene
- but compatibility, ecosystem expectations, and business incentives would still
  make that v2 partial, optional, and politically constrained
- so the case for a new forge/control plane is narrowed, not erased

The best synthesis is:

1. **Do not rely on GitHub being incapable of learning.**
   That is a weak thesis and this round rejected it.
2. **Do not rely on hygiene-only differentiation either.**
   A new forge must beat a plausible GitHub v2, not just today's defaults.
3. **Compete on architecture and institutional posture.**
   The strongest remaining opening is cleaner trust separation, narrower
   authority, auditable promotion, and governance not hostage to legacy
   convenience.

## Roster integrity note

This round used real seats only:

- Codex via local `codex` CLI
- Gemini via local `gemini` CLI
- Copilot via local `copilot` CLI
- DeepSeek via direct API call using the local decrypted key and explicit CA
  bundle
- OpenCode enrichment via local `opencode` CLI on `nemotron-3-super-free`

No seat was simulated.

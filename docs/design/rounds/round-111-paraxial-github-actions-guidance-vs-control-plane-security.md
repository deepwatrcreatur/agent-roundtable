## Round 111 — Paraxial GitHub Actions Guidance vs Control-Plane Security

**Tags:** security, github-actions, ci-cd, release-engineering, hosting  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** an OpenCode free-model enrichment seat was requested, but the
rerun failed with `Model not found: github/gpt-5-mini`, so it was not counted as
a substantive voice and was not simulated.

### Round question

The maintainer wanted a follow-up to the recent GitHub Actions security rounds,
using a quoted Claude Sonnet summary of Michael Lubas / Paraxial.io's GitHub
Actions recommendations.

The sharper question was:

- how much do those recommendations actually ameliorate the situation
- do they substantially answer the class of failures exposed by
  Mini-Shai-Hulud-style GitHub Actions / release-authority incidents
- or do they mostly bear out the need for a hosting site / forge with a better
  security model

This round was explicitly comparative rather than product-marketing-oriented.

### Grounding used in this round

Fresh official Paraxial grounding gathered before the panel:

- Paraxial's docs and blog frame the GitHub Actions advice mainly as:
  - integrating Paraxial scanning into CI/CD
  - posting PR feedback via the GitHub App
- the example workflow does explicitly set:
  - `permissions: contents: read`
- the docs instruct users to:
  - store `PARAXIAL_API_KEY` in GitHub Actions Secrets
  - run Paraxial scanning on PRs
  - use `--exit-code` / `--add-exit-code` so findings can fail the build
- the blog and GitHub Marketplace listing emphasize:
  - automated scanning of every PR
  - inline PR comments and remediation guidance
- the material does **not** present itself as a comprehensive GitHub Actions
  hardening guide in the StepSecurity / GitHub Security Lab sense

Relevant prior local context:

- **Round 100** — stricter CI providers can narrow the first-stage trust failure,
  but the deeper lesson is release-authority separation
- **Round 101** — better runner substrates are valuable hygiene, not a substitute
  for control-plane redesign
- **Round 103** — safer default CI systems help on the front half of the chain,
  but do not answer the deeper release-authority question
- **Round 104** — GitHub hardening checklists are necessary hygiene, not a
  structural answer; the differentiated answer is host-native separation of
  ordinary CI from trusted release authority

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** substantive
- **DeepSeek API:** substantive
- **OpenCode free-model enrichment:** requested, retried, but unusable because
  the requested model was not available
- **Copilot:** substantive

This round therefore had a **full substantive core roster** plus a failed
optional enrichment attempt.

### Voice summaries

#### Codex CLI

- Strongest on the distinction between:
  - a **scanner-in-CI answer**
  - and a **CI/release-control-plane answer**
- Treated the genuinely useful parts as:
  - scanning every PR
  - failing CI on findings
  - least-privilege `contents: read`
  - and better remediation UX
- But argued these are still mostly:
  - CI hygiene
  - or product-integration guidance
- Most explicit that the key untouched risks include:
  - `pull_request_target`
  - `workflow_run` privilege hops
  - action pinning
  - cache poisoning
  - OIDC trust scoping
  - runner-memory token theft
  - and release-authority separation

#### Gemini CLI

- Strongest on the distinction between:
  - reducing the **known-vulnerability-in-PR** failure mode
  - and addressing the deeper supply-chain / release-authority model
- Treated two recommendations as genuinely moving the needle:
  - `--exit-code` as enforcement instead of advisory-only scanning
  - `permissions: contents: read` as a real blast-radius reduction
- Also emphasized that:
  - “scan every PR”
  - “store API keys in Secrets”
  - and inline PR comments
  are mostly table-stakes or DX guidance
- Most vivid on the central gap:
  this is like improving one apartment in a building whose structural flaw is
  still unresolved

#### Claude CLI

- Most direct that the guidance is **solid application-level hygiene** but leaves
  the structural release-authority problem untouched
- Treated `contents: read` and PR-time scanning as real improvements
- Strongly separated:
  - secrets handling
  - failing the build
  - GitHub App feedback
  from
  - architectural hardening
- Highlighted the same missing attack surfaces:
  - `pull_request_target`
  - cache trust boundaries
  - action pinning
  - and the broader CI-as-release-authority flaw

#### DeepSeek API

- Most forceful that Paraxial's recommendations are useful, but mainly in the
  category of:
  - **operational hygiene inside GitHub Actions**
  - not structural redesign
- Saw `contents: read` as a real reduction in blast radius and `--exit-code` as a
  real shift from passive to enforced findings
- Still concluded that the guidance leaves the long list of Mini-Shai-Hulud-style
  risks mostly untouched, especially:
  - trusted-context misuse
  - cache poisoning
  - runner token theft
  - and release-control-plane coupling
- Most direct one-line judgment:
  Paraxial is a band-aid on a broken architecture, not an answer to that
  architecture

#### Copilot

- I agreed with the strong convergence that Paraxial's material is useful at the
  PR scanning and least-privilege workflow layer, but narrow
- My strongest synthesis point was that the guidance answers:
  - “how should you integrate a scanner into GitHub Actions?”
  much more than:
  - “how should GitHub Actions trust and release authority be designed?”
- I treated this as largely confirming the prior rounds rather than displacing
  them

### First-pass convergence

The substantive voices converged on the following points.

1. **Some of the Paraxial guidance is genuinely good.**
   The panel did not dismiss it as empty marketing.
   The most material improvements were:
   - PR-time scanning
   - failing the build on findings
   - least-privilege `GITHUB_TOKEN` scoping with `contents: read`

2. **Most of the guidance is still hygiene or product-integration advice, not
   architectural hardening.**
   The repeated examples were:
   - store the API key in Actions Secrets
   - wire the scanner into CI
   - show findings in PR comments
   - fail CI on findings

3. **The major GitHub Actions trust-boundary risks from prior rounds remain mostly
   untouched.**
   Across the panel, the repeatedly named gaps were:
   - `pull_request_target` misuse
   - `workflow_run` privilege hops
   - action pinning / action supply-chain integrity
   - cache trust boundaries and cache poisoning
   - OIDC trust scoping
   - runner-memory token theft / secret exfiltration
   - release-authority separation

4. **This does not materially change the answer from the previous GitHub Actions
   security rounds.**
   The panel treated the Paraxial material as improving one layer:
   - code scanning and blast-radius reduction inside existing GitHub Actions

   But it does not answer the deeper question:
   - who gets trusted publish authority
   - how that authority is separated from ordinary CI
   - and how the host prevents the wrong workflow state from counting as a trusted
     release path

5. **If anything, the narrowness of the Paraxial guidance reinforces the prior
   conclusion.**
   It shows how much “GitHub Actions security advice” is still advice about:
   - better YAML discipline
   - better scanning
   - and better workflow hygiene

   rather than a different release-control architecture.

### Real disagreements that remained

There was no major strategic disagreement.

The only mild difference in emphasis was:

- **Gemini** was most positive about `--exit-code` as a meaningful security gate
- **DeepSeek** was slightly harsher in its language about the guidance being a
  band-aid on a flawed architecture
- **Claude** and **Codex** sat between those poles, affirming the local utility
  while still treating the larger answer as architectural

This was a difference of tone, not direction.

### Final synthesis

The strongest answer from this round is:

- Paraxial / Lubas offers **competent GitHub Actions scanner-integration advice**
- some of that advice is genuinely worthwhile and should not be mocked:
  - least-privilege workflow token scope
  - blocking on findings
  - consistent PR-time scanning
- but it operates almost entirely at the:
  - application-vulnerability detection layer
  - workflow hygiene layer
  - and developer-experience layer

It does **not** substantially answer the failure class that motivated the earlier
rounds, because those failures were fundamentally about:

- trusted-context misuse
- workflow privilege transitions
- cache and identity trust boundaries
- runner compromise leverage
- and, above all, release authority being too close to ordinary CI execution

So the round's answer is not:

- “Paraxial makes the clean-break forge unnecessary”

It is closer to:

- “Paraxial improves one useful layer inside today's GitHub model, but mostly
  confirms why that model still wants a better host-native security/control
  plane”

### One-sentence verdict

Paraxial's recommendations materially improve PR-time vulnerability scanning and
some workflow hygiene inside GitHub Actions, but they do not substantially solve
Mini-Shai-Hulud-class trust-boundary and release-authority failures, so they
mostly reinforce rather than overturn the case for a forge with a stronger
security model.

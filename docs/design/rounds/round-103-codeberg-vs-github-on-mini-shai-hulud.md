## Round 103 — Should Security-Conscious Users Switch from GitHub to Codeberg Over Mini Shai-Hulud?

**Tags:** security, hosting, ci-cd, developer-experience
**Status:** Closed  
**Voices used:** Claude CLI, Gemini CLI, Codex CLI, Copilot synthesis  
**Additional note:** the round was grounded in prior CI/security rounds plus
current Codeberg, Forgejo, and Woodpecker documentation; DeepSeek CLI was not
available in this environment and was therefore not simulated

### Round question

The maintainer wanted a full follow-up discussion focused on:

- how **Codeberg** compares with the other options already discussed:
  - GitHub Actions / GitHub-hosted runners
  - GitLab CI
  - CircleCI
  - Buildkite
  - Azure Pipelines
  - Depot
  - Blacksmith
  - the clean-break forge idea with separated release authority
- and whether users who care about the vulnerability class exposed by **Mini
  Shai-Hulud** should broadly switch from GitHub to Codeberg

### Grounding facts used in this round

The round used the following current public facts:

- **Codeberg** currently offers two CI paths:
  - hosted **Woodpecker CI**
  - **Forgejo Actions**, but hosted Actions are limited and Codeberg explicitly
    says users needing hosted CI should prefer Woodpecker
- Codeberg docs say hosted Forgejo Actions are limited due to:
  - outstanding security issues
  - bus factor
- Woodpecker docs say:
  - secrets are **not exposed to pull requests by default**
  - secret exposure to PRs requires explicit opt-in
  - secrets can be restricted to specific plugins/images
- Codeberg's hosted Woodpecker offer also carries caveats:
  - manual onboarding
  - limited RBAC
  - linux/amd64 only
  - service provided as-is

The motivating threat chain remained:

- untrusted PR trust failure
- cache poisoning
- runner-memory token extraction
- trusted release / publish from a legitimate pipeline

### Relevant prior context

This round builds directly on:

- **Round 99** — the main lesson is host/release control-plane, not merely VCS
- **Round 100** — stricter CI providers help, but release-authority separation
  matters more
- **Round 101** — runner hardening helps, but does not replace control-plane
  redesign
- **Round 102** — the clean-break forge idea is real progress only if it reduces
  visible operator burden

### Participation record

What actually happened in this run:

- **Claude CLI:** substantive
- **Gemini CLI:** substantive
- **Codex CLI:** substantive
- **DeepSeek CLI:** unavailable in the environment, explicitly omitted

### Voice summaries

#### Claude CLI

- Strongest on the distinction between:
  - better **entry-point defaults**
  - and true **end-to-end architectural separation**
- Argued that Codeberg + Woodpecker is materially better than plain GitHub
  Actions on the **front half** of the chain because PR secrets are off by
  default.
- Also stressed that Codeberg does not solve the last and most important link:
  release authority should be a separate trust domain from ordinary CI.
- Recommendation was explicitly **not** “all users should switch.”
  Instead:
  - small OSS projects may reasonably prefer Codeberg + Woodpecker
  - security-sensitive orgs should pursue stronger release separation
  - low-friction teams may still rationally stay on GitHub

#### Gemini CLI

- Strongest on the critique that Codeberg's current security posture is improved
  partly through **reduced capability and friction**, not through a fully mature
  next-generation control plane.
- Treated manual onboarding and reduced feature surface as real mitigations, but
  also as evidence of limited operational maturity.
- Most skeptical about recommending Codeberg as a general migration target.
- Final answer was a clear **no** on “should everyone switch,” especially for
  low-friction teams and enterprise/security-heavy organizations.

#### Codex CLI

- Strongest on the concrete threat-chain comparison.
- Emphasized that Codeberg + Woodpecker is genuinely better than GitHub-hosted
  Actions at:
  - PR secret handling
  - avoiding GitHub-style trust footguns
- Also emphasized that Codeberg lacks a true answer for trusted publishing /
  release authority separation.
- Most explicit that switching vendors without redesigning release authority is
  often just **changing where the risk lives**.

#### Copilot

- Agreed with the panel's overall recommendation:
  Codeberg is a meaningful improvement on the early stages of the Mini
  Shai-Hulud chain, but not a universal answer and not the strongest option for
  every team.
- Treated the most important comparative distinction as:
  - **better CI trust boundaries**
  - versus
  - **better release-authority architecture**

### First-pass convergence

All three live CLI voices converged on the following points.

1. **Codeberg is better than common GitHub Actions practice on the initial trust
   boundary.**
   Woodpecker's default posture is materially safer on the most common mistake:

   - untrusted PR code does not automatically get secrets

   This directly narrows the first stage of the Mini Shai-Hulud chain.

2. **Codeberg is not the strongest answer to the full chain.**
   The deeper problem exposed by Mini Shai-Hulud is not only unsafe PR secret
   exposure; it is also:

   - cache trust
   - runner trust
   - and, most importantly, release authority being too close to ordinary CI

   Codeberg does not clearly solve that last problem.

3. **Hosted Forgejo Actions on Codeberg are not a confidence signal today.**
   The panel treated Codeberg's own warning about hosted Actions — outstanding
   security issues and bus factor — as highly relevant. The safer hosted answer
   on Codeberg today is Woodpecker, not “GitHub Actions but elsewhere.”

4. **Operational maturity matters.**
   Codeberg's current hosted CI story has visible limitations:

   - manual onboarding
   - limited RBAC
   - reduced architecture breadth
   - as-is service caveats

   These limitations sometimes improve safety, but they also reduce suitability
   for more complex teams.

5. **The recommendation is segmented, not universal.**
   The panel did **not** recommend that all users who care about this
   vulnerability should switch to Codeberg.

### Comparative recommendation

#### Versus GitHub Actions

Codeberg + Woodpecker is safer by default on the early-stage PR/secrets problem.
That matters.

But GitHub remains stronger on:

- workflow maturity
- ecosystem breadth
- integrated tooling
- lower-friction developer experience

So the comparison is:

- **Codeberg + Woodpecker:** narrower CI trust boundary
- **GitHub:** broader and smoother platform, but with more dangerous ambient
  trust patterns

#### Versus Depot and Blacksmith

Depot and Blacksmith improve the GitHub runner substrate.
Blacksmith in particular remains stronger than Depot on this specific chain
because branch/tag cache isolation is safer by default.

But both still inherit GitHub's workflow/release control plane.

So:

- **Codeberg + Woodpecker** can be better than GitHub + better runners if the
  main problem is unsafe PR trust and secret exposure
- **Blacksmith / Depot** are still not a full answer because runner hardening is
  not release-authority separation

#### Versus GitLab / CircleCI / Buildkite / Azure

The panel did **not** conclude that Codeberg universally beats the stricter
full-provider models from Round 100.

- **Buildkite** remains especially attractive for security-sensitive teams that
  want tighter control of release authority and infrastructure boundaries.
- **GitLab / CircleCI / Azure** remain more operationally mature and more
  suitable for teams needing richer enterprise controls.
- **Codeberg** looks strongest as a values-aligned hosted forge with safer CI
  defaults for smaller or moderately complex open-source teams, not as the
  universal best answer.

#### Versus the clean-break forge idea

The clean-break forge idea remains stronger in principle because it directly
targets the core failure:

- release authority should not be implied by ordinary workflow success

Codeberg does not yet embody that architecture in a decisive way.

### Recommendation by user type

#### Small OSS projects

Codeberg + Woodpecker is a reasonable and often attractive choice if the team:

- values safer default PR secret handling
- can tolerate some operational roughness
- does not need highly mature hosted CI controls

#### Security-sensitive organizations

Do **not** treat Codeberg migration as the answer.
Use stronger release-authority separation and more deliberate control-plane
design, whether on:

- Buildkite-like controlled infrastructure
- self-hosted Forgejo / Woodpecker with separate release authority
- or a future clean-break forge architecture

#### Teams that primarily want low friction

Do **not** switch solely for this reason.
Those teams are usually better served by:

- staying on GitHub
- fixing dangerous workflow patterns
- tightening secrets and cache boundaries
- and moving trusted release out of ordinary CI

### Work-item outcome

No new work item was created from this round.

The panel's recommendation was mainly comparative and strategic, and the
existing work items already cover the deeper product direction:

- `84-release-event-and-publish-authority-separation.md`
- `86-untrusted-contribution-trust-tiers.md`
- `87-safe-default-cache-trust-boundaries.md`
- `88-zero-config-trusted-publishing-ux.md`

### One-sentence verdict

Users who care about Mini Shai-Hulud should **not** universally switch from
GitHub to Codeberg; Codeberg + Woodpecker is better than common GitHub Actions
practice on the early trust-boundary failures, but the stronger long-term answer
is still explicit separation of ordinary CI from trusted release authority.

## Round 100 — Would Other CI Providers Have Narrowed Mini Shai-Hulud?

**Tags:** security, hosting, ci-cd, release-engineering
**Status:** Closed  
**Voices used:** Claude CLI, Gemini CLI, Codex CLI, Copilot synthesis  
**Additional note:** the round was grounded in current public docs/summaries for
GitHub Actions, GitLab CI, CircleCI, Buildkite, and Azure Pipelines; DeepSeek
CLI was not available in this environment and was therefore not simulated

### Round question

The maintainer wanted a follow-up to Round 99:

- GitHub users can choose CI/CD providers besides GitHub Actions
- do any of those providers have a **stricter security model** that likely would
  have thwarted or materially narrowed the Mini Shai-Hulud attack chain
- or is the deeper lesson not "pick a different provider," but redesign how CI
  and release authority relate

### Grounding facts used in this round

The round used the following comparison points from current provider
documentation and summaries:

- **GitHub Actions**
  - dangerous patterns exist around `pull_request_target` and privileged workflow
    contexts when used poorly
- **GitLab CI**
  - pipelines from forks run in the fork by default
  - parent project variables are not exposed by default
- **CircleCI**
  - secrets are not passed to forked pull request builds by default
- **Buildkite**
  - docs strongly recommend not exposing secrets to untrusted pull requests,
    support strict secret access policies, and recommend disabling builds from
    forks for public repos
- **Azure Pipelines**
  - secrets and protected resources are not exposed to fork builds by default
  - docs recommend manual triggering for fork builds, scoped identities, and
    hosted agents for untrusted contributions

The motivating attack chain remained:

- untrusted PR trust failure
- cache poisoning
- runner-memory token extraction
- trusted publisher release from the legitimate pipeline

### Relevant prior context

This round builds directly on:

- **Round 99** — the initial failure is mainly host/CI/release-control-plane,
  while ecosystem spread is the package-manager layer
- **Round 98** — the host should own critical control planes and final release
  gating
- **Round 92** — the successor forge needs stronger security-native release and
  disclosure primitives

### Participation record

What actually happened in this run:

- **Claude CLI:** substantive
- **Gemini CLI:** substantive
- **Codex CLI:** substantive
- **DeepSeek CLI:** unavailable in the environment, explicitly omitted

### Voice summaries

#### Claude CLI

- Strongest on the line:
  **separate publish authority from CI run identity entirely**.
- Thought other providers would have helped **partially**, especially by blocking
  the initial privilege escalation from fork context more reliably.
- Saw GitLab's fork-runs-in-fork model as especially strong on the first-stage
  trust boundary.
- Still warned that later cache poisoning or trusted-pipeline compromise remains
  possible unless release authority is independent.

#### Gemini CLI

- Strongest on the positive case that other providers likely would have helped.
- Emphasized:
  - default-deny secrets for fork builds
  - manual approval for untrusted sources
  - granular/scoped identities
- Still converged that the fundamental lesson is broader than provider choice:
  ordinary test runs should never be able to obtain publish-capable identity.

#### Codex CLI

- Strongest on the phrase:
  **treat release authority as a separate trust domain from ordinary CI**.
- Thought GitLab, CircleCI, Buildkite, and Azure all appear stricter than a
  poorly configured `pull_request_target`-style model and likely would have
  narrowed the initial chain.
- Most explicit that the right baseline is:
  zero secrets, zero privileged tokens, zero publish capability, and no parent
  cache access for untrusted contribution paths.

#### Copilot

- Agreed with the others that provider defaults do matter and some alternatives
  likely would have reduced the attacker's first foothold.
- But treated the more durable lesson as architectural:
  a safe forge cannot let "workflow success" imply "trusted release authority."

### First-pass convergence

All three live CLI voices converged on the following points.

1. **Yes, some alternative providers likely would have narrowed this attack
   chain by default.**
   GitLab, CircleCI, Buildkite, and Azure all appear stricter than a badly used
   `pull_request_target`-style GitHub Actions setup, especially around:
   - fork isolation
   - secret withholding
   - protected resource exposure
   - manual approval or explicit escalation

2. **No provider default by itself is enough.**
   Even a stricter provider does not fully solve:
   - later trusted-pipeline compromise
   - cache poisoning inside trusted contexts
   - runner-memory extraction of release credentials
   if publish authority remains too close to generic CI execution.

3. **The most important design differences are about trust transitions.**
   The key deltas are:
   - untrusted fork code runs with no parent secrets
   - no automatic access to protected resources
   - stricter identity scope
   - manual or explicit promotion into higher-trust contexts
   - stronger hosted-agent boundaries for untrusted code

4. **The main lesson is architectural, not brand-specific.**
   The right lesson is not merely "switch providers."
   It is:
   - separate release authority from ordinary CI
   - default untrusted contribution paths to zero privilege
   - make trusted publishing a separate, audited promotion event

### What the round recommends learning from the comparison

The strongest cross-provider lessons were:

#### 1. Untrusted-by-default fork handling

The successor forge should make it structurally hard for fork-originated or
otherwise untrusted contribution code to:

- access parent secrets
- access publish-capable identity
- access shared protected caches
- run on long-lived trusted runners

#### 2. Explicit trust promotion

Crossing from:

- untrusted CI

to:

- trusted release context

should require a visible higher-trust transition such as:

- maintainer approval
- protected branch / environment checks
- separate release event
- threshold or policy-based authorization

#### 3. Release identity is not CI identity

Publishing, signing, and provenance attestation should sit behind a separate
trust domain, not behind the mere fact that a job ran successfully.

### Work item created from this round

- [`86-untrusted-contribution-trust-tiers.md`](../../work-items/86-untrusted-contribution-trust-tiers.md)

### One-sentence verdict

Several alternative CI/CD providers likely would have narrowed the Mini
Shai-Hulud chain through stricter fork/secrets defaults, but the deeper lesson
is not "pick a different vendor" — it is that any serious successor forge must
separate ordinary CI from trusted release authority and enforce explicit
trust-tier transitions for untrusted contribution paths.

## Round 115 — Exa Search Fit and Guide Integration

**Tags:** search, tooling, economics, guidance, retrieval  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** this round is about Exa as a preferred live web-search provider for agent workflows, not about replacing direct URL fetches, repo-local search, or code-host-native retrieval.

### Round question

The maintainer wanted a fresh round on whether Exa is a good fit for the
project's agent workflows and, if so, how the guides should instruct agents to
use it.

The concrete decision questions were:

- should Exa be the preferred provider for genuine live web research
- should it be the default for all search-like tasks or only an escalation tier
- what usage policy best preserves value under a light budget of roughly
  1000 requests per month
- and how should the guides distinguish Exa from:
  - direct known-URL fetches
  - repo-local retrieval
  - and code-host-native search

### Grounding used in this round

Fresh grounding gathered before the panel:

- **Prior local retrieval context** from earlier search/routing rounds:
  - Round 94 argued that agent retrieval should be judged by end-to-end economic
    surplus rather than human search-box UX
  - Round 95 argued for host-assisted adaptive escalation rather than opaque
    universal routing
  - Round 97 used Hayek/distributed-knowledge framing to argue that routing
    should combine local signals and explicit cost/value cues rather than assume
    one model can centrally know everything
- **Current Exa coding-agent docs** say:
  - the main endpoint is `POST https://api.exa.ai/search`
  - auth is via `x-api-key`
  - the default search type is `type: "auto"`
  - supported search types include:
    - `auto`
    - `fast`
    - `instant`
    - `deep-lite`
    - `deep`
    - `deep-reasoning`
  - for agent workflows, `contents.highlights: true` is the token-efficient
    recommended default
  - `outputSchema` works on every search type
  - `contents.maxAgeHours` controls freshness and can force livecrawl when set to
    `0`
  - deeper search types are slower and more synthesis-heavy than `auto` / `fast`

Important scope boundary carried into the round:

- the question was **not** whether Exa should replace:
  - `web_fetch` for known URLs
  - repo-local grep / glob / git exploration
  - GitHub-native or Sourcegraph-style code retrieval
- it was whether Exa is the right **premium open-web discovery tier** for the
  kinds of external research this project actually does

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

- Strongest on the claim that Exa fits the real workflow gap:
  finding current external information when the agent does not already know the
  source URL.
- Treated Exa as a strong fit for **genuine open-web discovery**, but not as a
  universal retrieval front door.
- Most explicit that the main failure mode would be budget-wasting misuse on:
  - navigational lookups
  - repo-native search
  - or pages whose URLs are already known
- Preferred a policy of:
  - classify the task first
  - direct fetch if the URL is known
  - code-host/repo-native retrieval for code tasks
  - Exa only for genuine open-web discovery, freshness checks, or multi-source
    comparison
- Recommended cheap first-pass defaults:
  - `type: "auto"` or `"fast"`
  - `contents.highlights: true`
  - low result counts
  - deeper search only when justified

#### Gemini CLI

- Strongest on the claim that Exa belongs as a **conditional escalation tool**,
  not a reflexive default.
- Treated Exa as the premium tier in a layered retrieval stack:
  - local/code-host first
  - direct fetch second
  - Exa third
- Most explicit on budget pressure:
  1000 requests per month is enough for meaningful use, but too small for
  careless background search loops.
- Highlighted `outputSchema` as especially valuable for structured comparison and
  extraction work.
- Proposed a practical policy block with a retrieval cascade and a soft limit /
  pause-and-justify posture if Exa calls start stacking up inside a session.

#### Claude CLI

- Strongest on mapping Exa into the prior Round 95 / 97 logic:
  cheap local signals should gate premium retrieval.
- Treated Exa as a **premium escalation tier** for time-sensitive or
  synthesis-heavy web research, not a replacement for known-source fetch or
  code-host-native lookup.
- Most explicit that `auto` can be the wrong reflex if used without thought;
  it preferred:
  - `fast` for routine current web lookups
  - `deep` only when synthesis/comparison is really the task
- Strongest caution was against trusting Exa's grounding as a substitute for
  source verification:
  the agent should still fetch or inspect the cited source page directly before
  making stronger claims.

#### DeepSeek API

- Strongest on the framing that Exa is a “premium retrieval” service:
  useful because it reduces noise-to-signal ratio for agent consumption.
- Treated Exa as economically justified when the query is genuinely about the
  broader web rather than the local code/host state.
- Agreed that the default boundary should be:
  - local grep / glob first
  - direct fetch when URLs are already known
  - Exa only for broad external research or missing documentation
- Most favorable to borrowing a compact guide policy that makes
  `contents.highlights: true` mandatory for first-pass Exa usage and keeps result
  counts small.

#### Copilot

- I agreed with the strong convergence that Exa is a good fit for this project's
  **open-web discovery** problems, but not as a replacement for existing local
  or host-native retrieval.
- My strongest synthesis point was:
  the right architecture is exactly what the earlier search rounds would predict:
  Exa should be a visible, cost-aware escalation tier rather than an ambient
  default search substrate.
- I also agreed that the guide update should stay operational and short:
  teach agents when to use Exa, when not to use it, and what the first-pass
  parameters should be.

### First-pass convergence

The substantive voices converged on the following points.

1. **Exa is a good fit for the project's real live-web research needs.**
   It is well suited to:
   - current docs discovery
   - incident/status research
   - product comparisons
   - unfamiliar external tool/API investigation

2. **Exa should not be the universal default for all search-like tasks.**
   The panel repeatedly treated that as economically and operationally wrong.

3. **The right role for Exa is a premium open-web discovery / synthesis tier.**
   The preferred retrieval order was broadly:
   - repo-local / code-host-native retrieval first
   - direct fetch if the URL is already known
   - Exa when the task is genuinely about external web discovery, freshness, or
     multi-source comparison

4. **Budget discipline matters enough to encode in the guides.**
   With roughly 1000 requests per month, the panel treated wasteful Exa usage as
   a real risk rather than a theoretical one.

5. **Cheap first-pass defaults are the right Exa posture.**
   The strongest shared defaults were:
   - `contents.highlights: true`
   - `type: "auto"` or `"fast"` for first pass
   - small result sets
   - `outputSchema` only when structured extraction helps
   - deeper search types only when the task is genuinely synthesis-heavy

6. **Direct source inspection still matters.**
   Even when Exa is used, cited URLs should remain inspectable and agents should
   not confuse Exa's synthesis/grounding with final proof.

### Real disagreements that remained

There was no major strategic disagreement, but there were real differences in
emphasis:

- **Codex** was most comfortable with `auto` or `fast` as the first-pass default
- **Claude** was most skeptical of leaning on `auto` too casually and preferred a
  sharper distinction between routine `fast` use and rarer `deep`
- **Gemini** was strongest on session-level budget discipline and explicit
  retrieval cascades
- **DeepSeek** was strongest on the premium-retrieval framing and compact policy
  language

These were differences in tuning, not direction.

### Final synthesis

The strongest answer from this round is:

- Exa is worth adopting as the preferred provider for **genuine live open-web
  research**
- but only as a **bounded, cost-aware escalation tier**

The panel rejected two bad extremes:

- **bad extreme A:** “Exa should be the default for anything search-like”
- **bad extreme B:** “Exa is too premium to bother using at all”

The maintained line is:

- use repo-local and code-host-native retrieval when the problem is local
- use direct fetch when the source URL is already known
- use Exa when the agent truly needs external discovery, freshness, or
  multi-source synthesis

That gives the project exactly the kind of inspectable, budget-aware retrieval
policy that the earlier routing rounds were already pushing toward.

### Recommended guide block

The round converged on a guide policy close to this:

> When a task needs external information, classify it first. If you already have
> the target URL, fetch that page directly instead of using Exa. If the task is
> repo/code-host-native, use local search, GitHub-native search, or
> Sourcegraph-style retrieval instead of Exa. Use Exa only for genuine open-web
> discovery, freshness checks, or multi-source comparison. Default to a cheap
> first pass (`type: "auto"` or `"fast"`, `contents.highlights: true`, small
> result set, `outputSchema` only when structured extraction is needed).
> Escalate to `deep-lite`, `deep`, or `deep-reasoning` only when the first pass
> is insufficient and the higher-cost synthesis is justified.

### One-sentence verdict

Exa is a good fit for this ecosystem as a preferred **open-web discovery tier**,
but the guides should frame it as a **bounded premium escalation path**, not as
the default answer to every retrieval problem.

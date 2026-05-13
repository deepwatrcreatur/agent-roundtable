## Round 82 — Private Code, Better Matching, and Privacy-Preserving Attestations

**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, `opencode/minimax-m2.5-free`, `opencode/nemotron-3-super-free`, Copilot synthesis  
**Additional note:** the round was also grounded by a general external summary of privacy-preserving credentials / selective disclosure attestations as a possible middle ground between direct artifact sharing and full behavioral dossiers  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wanted to push back on the prior round's reliance on public
artifacts and public portfolio evidence.

The harder case was:

- much hosted code will be proprietary rather than open source
- companies paying for hosting will often prohibit sharing concrete code examples
- public artifact review may therefore be unavailable in many important hiring and
  role-matching contexts

The central question was whether that privacy constraint materially changes the
ethics:

- if public artifacts cannot usually be shown, does some type of scoring become
  more justified
- or is there a narrower privacy-preserving alternative that still avoids turning
  the platform into a worker-surveillance and screening infrastructure

### Relevant prior context

This round built directly on:

- **Round 69** — cross-employer trust/profile systems could have real business
  value, but risk blacklist and labor-surveillance dynamics
- **Round 79** — even the strongest positive case for matching still only justified
  local workflow assistance, not portable person profiling
- **Round 80** — credit-scoring normalization is a warning sign, not moral
  legitimation, and FCRA-like safeguards do not cure the subjectivity problem
- **Round 81** — ecosystem pragmatism is a real professional strength, but the
  acceptable evidence form was inspectable artifacts, explicit endorsements,
  candidate-curated portfolios, and project-local trust rather than queryable
  cross-employer behavioral data

### External grounding used

The round was informed by the general model of privacy-preserving credentials and
selective disclosure:

- verifiable credentials
- selective disclosure attestations
- candidate-controlled presentation of limited claims
- proving bounded facts without exposing the underlying confidential record

This was treated as a possible middle ground between:

- showing private code directly
- building a cross-employer behavioral dossier

### Participation record

What actually happened:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **MiniMax M2.5 free:** substantive
- **Nemotron 3 Super free:** concise but substantive

### Voice summaries

#### Codex

- Strongest on the replacement architecture:
  not a worker reputation system, but a **candidate-controlled evidence wallet**
  plus verification layer.
- Rejected any global score or aggregate reputation metric.
- Accepted structured employer-issued and reference-like claims only when:
  - factual
  - bounded
  - inspectable
  - candidate-disclosed

#### Gemini

- Strongest on the core framing:
  private artifacts make evaluation harder, but do not ethically justify falling
  back to surveillance proxies.
- Treated privacy-preserving attestations as genuinely helpful for *verification*
  while stressing that they do not solve the deeper *subjectivity* problem.
- Proposed a **candidate-controlled verification wallet** as the narrowest
  acceptable product.

#### MiniMax M2.5 free

- Strongest on the gap analysis:
  the main unresolved problem is external hiring when public evidence is absent.
- Treated attestations as a partial bridge for factual claims such as role,
  tenure, and specific bounded experience.
- Rejected scores and third-party aggregation as the step that recreates the
  earlier surveillance problem.

#### Nemotron 3 Super free

- Strongest on conditions for any acceptable attestation layer:
  - issuer-limited
  - claim-specific
  - candidate-controlled
  - non-aggregatable
  - time-bound
- Rejected all scoring and portable profiling even under private-code
  constraints.

#### Copilot

- Agreed that private code changes the evidence surface but not the ethical red
  line.
- Treated the most important new conclusion as:
  privacy pressure strengthens the case for claim-specific attestations, not for
  portable behavioral scoring.

### First-pass convergence

The round converged on the following points.

1. **Private code materially changes the proof problem.**
   When public artifacts are unavailable, it becomes harder to evaluate workers
   fairly and richly.

2. **That does not justify cross-employer scoring or dossiers.**
   The absence of public code increases pressure to use proxies, but does not make
   worker-surveillance infrastructure ethically acceptable.

3. **Privacy-preserving attestations are the strongest middle ground found.**
   Selective disclosure, verifiable credentials, scoped endorsements, and
   employer-issued factual claims can provide some evidence without revealing the
   underlying proprietary artifact.

4. **Attestations help with verification, not with subjective judgment.**
   They can prove bounded claims like role, tenure, system class, or named
   responsibility. They do not make "pragmatism," "fit," or "good judgment" into
   cleanly verifiable facts.

5. **Scores remain ethically indefensible.**
   Even with private code hidden, compact scores still collapse too much context,
   enable false precision, and drift toward blacklist/whitelist behavior.

6. **The narrow acceptable product becomes candidate-controlled claim
   presentation, not platform-side behavioral intelligence.**

### What changes when artifacts are private

The round agreed that confidentiality changes several practical conditions:

- direct inspection of code and PRs may be impossible
- evaluators are pushed toward proxies
- worker-employer power asymmetry increases because the candidate cannot simply
  "show the work"
- there is stronger temptation to build scoring systems that summarize hidden work

But the panel repeatedly stressed:

this change in available evidence does **not** alter the core objection to
portable behavioral profiling.

If anything, it increases the danger of bad proxies:

- telemetry
- review-speed metrics
- productivity traces
- silent employer-to-employer sharing
- black-box AI summaries of hidden code history

### Whether privacy-preserving attestations help

The converged answer was **yes, conditionally**.

They help when they are:

- **claim-specific**
  - "held role X"
  - "maintained service class Y"
  - "received explicit endorsement Z"
- **issuer-attributed**
  - employer, manager, or maintainer is named
- **candidate-controlled**
  - worker decides when to disclose
- **selectively disclosed**
  - verifier sees only the needed claim, not the full private record
- **time-bounded**
  - claims expire or become stale unless refreshed
- **non-aggregatable by design**
  - credentials should not silently become a portable dossier

The round did **not** treat attestations as magic. They help prove limited facts;
they do not eliminate the interpretive nature of many hiring judgments.

### Whether any score is acceptable

The panel converged on **no** for portable or cross-employer scoring.

Reasons repeated across voices:

- scores collapse too much context
- scores invite false precision
- scores are easily repurposed for screening and exclusion
- scores encourage aggregation and comparability across incomparable contexts
- scores recreate the same dynamic rejected in Rounds 69, 79, 80, and 81

At most, the round tolerated internally local, descriptive workflow indicators
inside one organization for current operations — but not portable worker scores
for external matching.

### Hiring vs current-org vs open-source trust use cases

#### External hiring

This remains the hardest case.

Potentially acceptable evidence:

- candidate-curated confidential case studies
- employer-issued factual attestations
- explicit peer or manager references
- limited verifiable credentials under candidate control

Not acceptable:

- cross-employer portable scores
- queryable behavioral dossiers
- platform-generated trait profiles
- hidden matching engines that synthesize a person-level ranking from proprietary
  traces

#### Current-org routing

This remains the safest operational space:

- current employer already shares the artifact context
- project-local trust and internal evidence can be used for routing and access
- these signals should remain local to the org and not follow workers out

#### Open-source trust

This case is different because open-source work remains publicly inspectable by
default.

So the round did not treat private-code attestations as central to OSS trust.
Public artifacts and project-local trust remain the primary surface there.

### Narrowest acceptable product, if any

The round converged on a narrow product shape:

**a candidate-controlled, selectively disclosable evidence wallet for bounded
professional claims, not a cross-employer reputation system.**

Core properties:

1. **Worker controls disclosure**
   The candidate chooses which claims to present for a given role or evaluator.

2. **Claims are factual and scoped**
   Role, tenure, domain, system class, named responsibility, or explicit
   endorsement — not personality, fit, risk, or inferred judgment scores.

3. **Verifiable provenance**
   Claims are signed or otherwise attributable to the issuer.

4. **No aggregation into global score**
   The platform may verify claims, but must not collapse them into a normalized
   rank or fit number.

5. **No silent query surface**
   Employers cannot search a platform-wide worker database of hidden behavioral
   traits.

6. **No durable portable dossier**
   Credentials should not become an ever-growing behavioral passport.

### What must be ruled out

The round treated the following as hard prohibitions:

- cross-employer portable scores, ratings, or trust ranks
- hidden employer-to-employer sharing of worker performance signals
- behavioral dossiers built from proprietary code telemetry, PR velocity, review
  sentiment, or workplace metadata
- amateur psychological labels or proxy diagnoses
- "culture fit," "risk," "rehireability," or similar behavioral abstractions as
  machine-readable credentials
- black-box matching systems that convert attestations into a single ranking
  number
- mandatory disclosure regimes that destroy candidate control
- third-party aggregation of attestations into a portable worker profile

### Immediate roadmap implications

The converged near-term implications were:

1. if proprietary-code matching is explored, do it through candidate-controlled
   attestations and references rather than scores
2. keep current-org workflow/routing distinct from external labor-market uses
3. define which claims are factual enough to attest and which are too subjective
4. explicitly bar aggregation into a worker credit score or reputation passport
5. treat private-code constraints as a reason for selective disclosure, not as a
   justification for surveillance proxies

### Consensus summary

The consensus answer is:

- **yes**, private code creates a real evidence gap
- **yes**, that gap makes privacy-preserving attestations more attractive
- **no**, that still does not justify portable scoring or behavioral dossiers
- **yes**, a narrow candidate-controlled attestation layer may be ethically
  defensible for bounded factual claims
- **no**, "some kind of scoring" did not survive the round as an acceptable answer

### One-sentence verdict

When proprietary code cannot be shared, the ethical middle ground is
candidate-controlled, selectively disclosed, verifiable claims and references —
not portable scores, queryable behavioral dossiers, or any worker-credit-style
reputation layer.

## Round 99 — Mini Shai-Hulud, `jj` Hosting, and the Host-vs-Ecosystem Boundary

**Tags:** security, hosting, release-engineering, integrity
**Status:** Closed  
**Voices used:** Claude CLI, Gemini CLI, Codex CLI, Copilot synthesis  
**Additional note:** the round used current public reporting on the recent Mini
Shai-Hulud wave as factual grounding plus live local CLI voices; DeepSeek CLI was
not available in this environment and was therefore not simulated

### Round question

The maintainer wanted a fresh round on the recent Mini Shai-Hulud worm and a
specific product question for a successor to GitHub:

- does a `jj`-based hosting platform have **innate protections** against this
  class of attack
- or is this really a problem that must be solved mainly within the **npm/package
  ecosystem**
- and what responsibility remains for a code host that provides CI/CD and release
  automation

### Grounding facts used in this round

The round used the following incident shape as its factual basis:

- the TanStack compromise reportedly chained:
  - a `pull_request_target`-style CI trust failure
  - GitHub Actions cache poisoning
  - OIDC token extraction from runner process memory
- malicious packages were then published through the victim project's own
  legitimate release pipeline using trusted publisher identity
- the malicious artifacts still carried valid provenance/attestation because the
  legitimate pipeline itself had been subverted
- the worm then propagated through package publishing and install surfaces in npm
  and beyond, stealing credentials and infecting further environments and
  package namespaces

### Relevant prior context

This round builds directly on:

- **Round 92** — the threat shift in AI-era security and the need for
  security-native coordination primitives rather than naive trust in public patch
  flow
- **Round 95** — the host should participate in important control-plane decisions
  rather than merely serving as a passive file store
- **Round 98** — the host should own critical control planes and final release
  gating even when external providers contribute evidence

The project is also explicitly interested in:

- `jj`-based hosting
- lineage-aware memory
- explicit provenance
- stronger release, review, and gating primitives

### Participation record

What actually happened in this run:

- **Claude CLI:** substantive
- **Gemini CLI:** substantive
- **Codex CLI:** substantive
- **DeepSeek CLI:** unavailable in the environment, explicitly omitted

### Voice summaries

#### Claude CLI

- Strongest on the claim that the attack surface is the **CI trust boundary**,
  not the version-control data model by itself.
- Rejected the idea that a different VCS alone would solve the problem.
- Still saw useful `jj` value in:
  - better forensics
  - tighter change attribution
  - stricter cache-keying and eligibility semantics
- Strongest platform recommendation:
  release pipelines must become **first-class auditable objects** with approval
  logic independent from arbitrary workflow execution.

#### Gemini CLI

- Strongest on the phrase:
  shift from implicit CI trust to **explicit, host-controlled release gates**.
- Rejected innate `jj` protection, but emphasized `jj` as useful for:
  - blast-radius mapping
  - precise rollback
  - structural lineage attestation
- Treated the incident as a **dual failure**:
  - host/CI over-privileged runtime identity
  - ecosystem/package consumers trusted cryptographically valid artifacts without
    enough contextual lineage
- Strongest on separating signing/identity brokering from raw CI compute.

#### Codex CLI

- Strongest on calling this a **control-plane compromise**, not merely a package
  compromise.
- Emphasized that provenance can remain cryptographically truthful while still
  blessing malicious output if the release pipeline is subverted.
- Rejected any claim that `jj` innately blocks cache poisoning or runner-memory
  token theft.
- Saw the main `jj` contribution in:
  - immutable operation history
  - explicit rewrite lineage
  - ancestry-aware policy
  - more first-class release binding to reviewed changes

#### Copilot

- Agreed with the converged view that the incident does **not** mainly refute
  package provenance; it refutes simplistic provenance models that say
  "valid build identity" is enough.
- Treated the key design move as:
  separate **build**, **publish authority**, and **final release promotion**
  rather than letting one compromised workflow step implicitly own all three.

### First-pass convergence

All three live CLI voices converged on the following points.

1. **A `jj`-based forge does not have innate protection against Mini
   Shai-Hulud-class attacks.**
   `jj` does not by itself stop:
   - CI misconfiguration
   - cache poisoning
   - runner-memory token theft
   - OIDC misuse

2. **`jj` still offers real structural advantages, but mostly for control,
   containment, and forensics rather than raw prevention.**
   Useful advantages include:
   - cleaner immutable operation history
   - better change/rewrite lineage
   - more precise blast-radius mapping
   - stronger binding of releases to reviewed change identities
   - safer cache or promotion policies keyed to immutable lineage rather than
     mutable branch state

3. **The initial failure is mainly host/CI/control-plane failure.**
   The worm-scale spread then becomes an ecosystem/package-manager problem, but
   the root enabling breach was the host granting too much ambient authority to
   compromised workflow execution.

4. **The package ecosystem still has real responsibilities.**
   The npm/package layer must improve:
   - quarantine
   - revocation signaling
   - install-time sandboxing or safer defaults
   - dependency graph kill-switches
   - narrower publisher/package delegation boundaries

5. **Valid provenance is necessary but not sufficient.**
   If the trusted pipeline itself is hijacked, the signed artifact can still be
   malicious. The host therefore needs provenance that includes approval and
   promotion context, not only build identity.

### What the host should own

The round strongly favored host-owned primitives for:

- hardened runners and stronger trust-boundary separation
- cache isolation keyed to immutable trust boundaries
- short-lived credentials with less ambient publish authority
- publish authority separated from ordinary build execution
- release gates independent from "workflow happened to run successfully"
- approval-chain and intent-aware provenance
- suspicious-release quarantine and revocation surfaces
- lineage-aware forensic views across review, build, publish, rollback, and
  incident response

### What package ecosystems must own

The round strongly favored ecosystem-side responsibilities for:

- rapid quarantine and yank signaling
- client-visible risk status and revocation UX
- dependency-graph kill switches
- safer install defaults and narrower script execution trust
- stronger publisher/package delegation and recovery boundaries
- rollback and containment mechanics that work across the dependency graph

### What the round rejected

The round rejected:

1. **"`jj` solves it."**
   Too strong. `jj` helps with lineage and policy shape, not with raw runner
   compromise by itself.

2. **"This is only npm's problem."**
   Too narrow. The initial trusted-publisher compromise was deeply a host/CI
   problem.

3. **"This is only the host's problem."**
   Also too narrow. Once malicious artifacts enter the ecosystem, quarantine,
   client defaults, and rollback become package-ecosystem responsibilities.

### Work items created from this round

- [`84-release-event-and-publish-authority-separation.md`](../../work-items/84-release-event-and-publish-authority-separation.md)
- [`85-package-quarantine-and-revocation-graph.md`](../../work-items/85-package-quarantine-and-revocation-graph.md)

### One-sentence verdict

Mini Shai-Hulud does not show that `jj` hosting is innately safe; it shows that
the real weak point is the CI/release control plane, while `jj` can still make a
successor forge materially better at release binding, containment, rollback, and
forensics if the host also builds first-class release-authority separation and
ecosystem-aware quarantine/revocation primitives.

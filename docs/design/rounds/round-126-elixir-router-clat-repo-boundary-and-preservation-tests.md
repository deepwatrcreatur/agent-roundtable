# Round 126: Elixir `router-clat` Repo Boundary and Preservation Tests

**Status:** closed
**Opened:** 2026-05-22
**Participants requested:** implementation panel, product/boundary panel, testing/reliability panel, GitHub Copilot

## Why this round exists

`nix-router-optimized` already has a meaningful `router-clat` first slice:

- declarative module surface
- Tayga backend/runtime wiring
- a Python control-plane daemon
- persistent state/artifact paths
- bounded observability and runtime validation work

The maintainer then raised a sharper product question:

- should the control plane move into a separate Elixir repository
- and if so, what should the product boundary and preservation-test strategy be

This round exists to avoid treating that as a language-preference question.
The real issue is whether a repo split now improves product quality, or just
adds boundary and release overhead before the contract is stable.

## Relevant prior context

From earlier `nix-router-optimized` CLAT work:

- the project explicitly rejected a long-term “we wrapped `styx46`” identity
- Tayga was accepted only as a bounded backend, not the architecture
- the design direction emphasized a clean control-plane / data-plane split
- the current runtime already has real responsibilities:
  - DNS synthesis
  - mapping allocation/persistence
  - TTL/GC
  - artifact generation
  - reload orchestration
  - status/observability surfaces

So this round was not about whether Elixir can supervise a process. It was about
repo boundary, contract shape, and what tests must exist if Elixir becomes part
of the real product path.

## Question for this round

The panel was asked to answer seven concrete questions:

1. Should the control plane stay inside `nix-router-optimized` for now, or move
   into a separate Elixir repo soon?
2. If a separate repo is justified, what exactly should live there and what must
   remain in `nix-router-optimized`?
3. What public contract should exist between `nix-router-optimized` and the
   control plane so Tayga remains replaceable?
4. What tests are required from day one to prove preserved behavior relative to
   the current Python control plane and the `router-clat` design contract?
5. Should the Elixir effort be treated as a productized path, an alternate
   backend, or a research track first?
6. What are the biggest risks in choosing Elixir here, and where is it
   genuinely better than Python?
7. What concrete first implementation wave should happen next?

## Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **DeepSeek API:** substantive (`deepseek-v4-flash`)
- **Claude CLI:** requested, but did not return a usable answer and was stopped
  after hanging
- **GitHub Copilot:** substantive

This round is therefore recorded as a **degraded roster**. Claude was not
simulated.

## Voice summaries

### Codex CLI

- Strongest on the claim that the **boundary is not stable enough to justify
  extraction yet**.
- Recommended:
  - build the Elixir implementation inside `nix-router-optimized` first
  - keep the architecture extraction-ready
  - and only split into a separate repo after parity and contract stability
- Treated the hard part as preserved behavior, not process supervision:
  - DNS synthesis semantics
  - mapping lifecycle
  - persistence invariants
  - artifact generation
  - reload sequencing
  - observability
- Strongest testing position:
  - golden contract tests
  - black-box parity tests against the Python plane
  - backend-isolation tests
  - NixOS integration tests
- Considered Elixir a good fit for a mature service, but only if the design
  stays boring, explicit, and contract-first rather than OTP-for-OTP's-sake.

### Gemini CLI

- Strongest on the claim that a **separate Elixir repo should happen now** to
  force a clean product boundary.
- Framed the move as a shift from a script-like helper to a router-grade
  supervised service.
- Wanted the Elixir repo to own:
  - mapping/state logic
  - backend adapter behavior
  - observability API
  - and the core control-plane implementation
- Wanted `nix-router-optimized` to remain the declarative and host-integration
  layer.
- Proposed a versioned intent manifest and backend protocol so the system does
  not become Tayga-shaped.
- Strongest tests mentioned:
  - preserved synthesis behavior
  - persistence across restart
  - `clat0` lifecycle synchronicity
  - MTU/MSS behavior preservation
- Treated the Elixir path as a productized replacement, not a research track.

### DeepSeek API

- Also favored **moving to a separate Elixir repo now**, on the grounds that the
  current Python daemon is already distinct enough that a real contract should be
  made explicit instead of remaining implicit inside the flake.
- Proposed a strong separation:
  - Elixir repo owns daemon/runtime logic, mapping state, artifact generation,
    reload orchestration, and tests
  - `nix-router-optimized` owns declarative module surface, systemd packaging,
    state path declarations, and full-stack integration tests
- Strongest contract emphasis:
  - filesystem/state-dir contract
  - readiness/lifecycle contract
  - backend-neutral mapping JSON schema
  - observability socket/metrics contract
  - no direct Tayga-specific coupling in the control-plane core
- Strongest preservation-test emphasis:
  - mapping persistence
  - TTL/GC
  - crash recovery
  - reload orchestration
  - backward compatibility with Python-authored mapping state
- Treated the Elixir path as a productized replacement and explicitly rejected
  keeping it “experimental.”

### GitHub Copilot

- I agreed with the panel that Elixir is a plausible fit for the mature
  control-plane problem, especially for:
  - supervised long-running state
  - timer/GC handling
  - structured telemetry
  - explicit adapter boundaries
- But I aligned with **Codex** on timing:
  the project still benefits from freezing preserved behavior and parity tests
  before paying the cost of a second repo.
- My strongest takeaways were:
  - the system needs a written backend-neutral control-plane contract
  - preserved external behavior matters more than implementation similarity
  - and a repo split should follow proven parity rather than substitute for it

## First-pass convergence

Despite the main boundary disagreement, the obtained voices still converged on
several important points.

1. **Elixir is a credible fit for the mature control-plane problem.**
   No obtained voice argued that the BEAM is a poor match for a long-running
   stateful control plane with timers, persistence, supervision, and telemetry.

2. **The product must not become Tayga-shaped.**
   Every substantive voice wanted a backend-neutral contract with Tayga behind an
   adapter boundary rather than as the public shape of the system.

3. **Preservation testing is mandatory from day one.**
   The panel strongly converged that the project must explicitly prove preserved
   behavior for:
   - DNS synthesis
   - mapping persistence
   - TTL/GC
   - reload/reconcile behavior
   - integration-visible runtime behavior

4. **`nix-router-optimized` must remain the declarative host-integration layer.**
   Even the voices favoring immediate extraction did not want the Elixir repo to
   absorb NixOS module semantics, systemd ownership, or general host wiring.

5. **The control-plane contract should be state-oriented and versionable.**
   The obtained voices repeatedly asked for:
   - a stable desired-state/input schema
   - backend-neutral artifact expectations
   - durable state/persistence rules
   - runtime status/degraded-state reporting

## Real disagreements that remained

There was one major unresolved disagreement.

### 1. When to split into a separate repo

- **Codex** argued for:
  - in-repo Elixir first
  - parity and contract freeze second
  - extraction only after the boundary proves stable
- **Gemini** and **DeepSeek** argued for:
  - immediate extraction
  - using the second repo to force better discipline and cleaner product seams
- **Copilot** aligned with Codex on timing, while agreeing with the others on
  the eventual shape of the boundary

This was a real strategic disagreement, not a phrasing difference.

### 2. How aggressive the rollout stance should be

- **Gemini** and **DeepSeek** both treated the Elixir path as a productized
  replacement very early
- **Codex** was more cautious and wanted an opt-in path until parity is proven
- **Copilot** agreed with the cautious rollout shape

## Final synthesis

The strongest maintained line from this round is:

**Elixir is plausible enough to justify serious work, but the project should
freeze contract and preservation tests before letting repo structure pretend the
boundary is already proven.**

The panel strongly supports:

- a backend-neutral control-plane contract
- preserved-behavior testing from day one
- keeping Tayga behind an adapter boundary
- and leaving `nix-router-optimized` as the declarative deployment/integration
  layer

The real design tension is not “Python or Elixir.”
It is:

- whether a second repo now creates healthy discipline
- or whether it creates premature packaging and compatibility overhead while the
  preserved-behavior contract is still moving

The safest synthesis is therefore:

- write/freeze the preserved behavior and backend-neutral contract first
- build the Elixir path against that contract with parity fixtures
- and only then make the repo-extraction decision permanent if the boundary
  still looks worth the cost

That preserves the value of the round even if the maintainer still prefers
immediate extraction: the test and contract work is clearly first-order either
way.

## Concrete follow-on work from the round

1. Write a dedicated `router-clat` control-plane contract note that freezes:
   - desired-state input
   - durable mapping schema
   - artifact/apply contract
   - runtime status/degraded-state contract
   - backend adapter interface
2. Add an explicit preservation-test plan covering:
   - DNS synthesis parity
   - persistence/restart
   - TTL/GC
   - crash recovery
   - reload/reconcile behavior
   - backend-isolation tests
   - NixOS VM integration tests
3. Queue an implementation item for an Elixir control-plane path behind an
   explicit backend/control-plane selector rather than a silent replacement.
4. Queue a later extraction/repo-split decision item rather than assuming that
   repo structure is already settled.

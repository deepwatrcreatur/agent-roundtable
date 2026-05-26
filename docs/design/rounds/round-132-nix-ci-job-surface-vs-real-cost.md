## Round 132 — NixCI Job Surface vs Real Cost

**Tags:** nix, ci, nix-ci, checks, linkfarm, flake, economics  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis

### Round question

The maintainer wanted a follow-up round on whether `nix-ci.com` charges could be
reduced by exposing fewer jobs per commit.

The concrete question was not just “should CI look cleaner?”
It was:

- whether reducing the number of exported `checks.<system>.*` outputs would
  actually reduce `nix-ci.com` spend
- whether `pkgs.linkFarm` is the right way to group many small checks into fewer
  top-level CI jobs
- whether a repo like `nix-router-optimized` should keep exporting a very
  fine-grained job surface
- and what the maintainer should do next month if the real cost driver is
  repeated eval/build overhead rather than job count by itself

### Grounding used in this round

Local evidence carried into the round:

- the maintainer explicitly wanted a round on reducing `nix-ci.com` charges by
  using fewer jobs in a commit and grouping them with `linkFarm`
- public `nix-ci.com` pricing says billing is by worker-seconds of actual job
  execution
- public `nix-ci.com` docs/comparison say it automatically discovers flake
  outputs and creates jobs from them
- the local flake output counts are very uneven:
  - `nix-router-optimized`: `174` exported `checks.x86_64-linux.*`
  - `unified-nix-configuration`: `3`
  - `agent-roundtable`: `1`
- in `nix-router-optimized`, many checks are small
  `mkNixosEvalCheck` / `mkNixosEvalFailureCheck` / `runCommand`-style
  derivations spread across `tests/`
- in `agent-roundtable`, the exported surface is already very small: the repo’s
  own `flake.nix` aggregates the helper-script check with `pkgs.symlinkJoin`
  instead of exporting many leaves

Relevant prior local context carried in:

- **Round 31 / Q46** already maintained the “Nix-first CI” line:
  flake logic should remain canonical inside the repo, while the external CI
  system is only the execution surface

Important scope boundary:

- the question was **not** whether `linkFarm` is a valid Nix primitive
- it was whether `linkFarm`-style aggregation is a real **cost-control**
  mechanism, or mainly a **surface-shaping** mechanism

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** substantive
- **DeepSeek API:** substantive via direct HTTP API and local decrypted key
- **Copilot:** substantive

This round therefore had a **full five-seat substantive roster**.

### Voice summaries

#### Codex CLI

- Strongest on the distinction between **fewer visible jobs** and **fewer
  worker-seconds**.
- Treated `linkFarm` as acceptable for **surface shaping**, but weak as a
  billing fix because it still depends on the same underlying derivations.
- Saw the strongest local contrast in the exported surfaces:
  `nix-router-optimized` with `174` checks versus `unified-nix-configuration`
  with `3` and `agent-roundtable` with `1`.
- Recommended bringing `nix-router-optimized` closer to the smaller-surface
  pattern while separately attacking duplicated eval/build work if real spend is
  the target.

#### Gemini CLI

- Most sympathetic to the claim that **job count reduction itself** can save
  money, because every extra CI job pays setup, provisioning, and status-report
  overhead.
- Most favorable to **`pkgs.linkFarm` specifically** as the grouping mechanism,
  treating it as the idiomatic way to create a small number of suite outputs.
- Still agreed that the current `174`-job exported surface in
  `nix-router-optimized` is excessive and should be reduced to a few logical
  suites.
- Most willing to frame the main win as a combination of lower overhead and
  much cleaner CI presentation.

#### Claude CLI

- Strongest on the argument that the project should prefer **real suite
  derivations** over a pure symlink farm.
- Pointed to the repo’s existing `symlinkJoin` pattern in `agent-roundtable`
  as evidence that small exported surfaces are already compatible with the local
  Nix style.
- Explicitly favored `runCommand`-style suite aggregation with trivial outputs
  over `linkFarm`, because the semantics are cleaner for “all of these checks
  must succeed.”
- Recommended grouping `nix-router-optimized` into roughly `3`–`5` suites while
  leaving the fine-grained checks available for local/manual use.

#### DeepSeek API

- Strongest on the claim that **`linkFarm` by itself is mostly cosmetic** from a
  billing perspective.
- Emphasized that worker-second pricing means the same underlying builds still
  happen unless duplicated work is actually removed.
- Recommended a custom aggregator derivation or other shared-eval approach
  rather than treating `linkFarm` as the cost optimization itself.
- Was also one of the clearest voices on the debugging downside:
  grouping can make reruns and failure attribution worse if logs are not kept
  legible.

#### Copilot

- I agreed with the main distinction the panel kept returning to:
  `linkFarm` / `symlinkJoin` is good for **compressing the exported CI surface**,
  but not automatically good for **reducing billed execution time**.
- I also emphasized the local evidence that the project already has the
  smaller-surface pattern in two of the three repos:
  `agent-roundtable` exports one aggregated check and
  `unified-nix-configuration` exports three.
- My strongest synthesis point was that the next move should be a few **real
  suite checks** in `nix-router-optimized`, with `linkFarm` kept as an optional
  thin wrapper rather than the main economic theory.

### First-pass convergence

The substantive voices converged on the following points.

1. **`nix-router-optimized` is the real outlier.**
   The problem is not spread evenly across the workspace:
   `agent-roundtable` at `1` exported check and
   `unified-nix-configuration` at `3` are already much closer to the right
   Nix-first CI shape.

2. **Reducing the exported job surface is still worth doing.**
   Even the more skeptical voices agreed that `174` separate exported checks are
   too many for the default CI boundary and create unnecessary UI/status noise
   plus some per-job overhead.

3. **`linkFarm` alone is not the real billing lever.**
   The panel broadly agreed that simply wrapping the same leaves in a symlink
   farm does not magically erase the underlying worker-seconds if all the same
   derivations still need to be realized.

4. **The best stable shape is coarse CI suites plus finer-grained local checks.**
   The round strongly favored exposing a few high-level CI suites while keeping
   the smaller checks available for local debugging and targeted manual runs.

5. **The repo should preserve its Nix-first CI line.**
   No voice argued for moving logic out of the flake or treating some outside CI
   service as the canonical source of truth.

### Real disagreements that remained

There were two narrower disagreements.

- **Gemini** was more willing than the others to credit `linkFarm` itself as the
  main practical mechanism, arguing that per-job provisioning and coordination
  overhead can still make the smaller exported surface economically meaningful.
- **Codex**, **Claude**, **DeepSeek**, and **Copilot** all treated that as too
  strong:
  they preferred to describe `linkFarm` as a surface tool and to reserve the
  real cost claim for approaches that also reduce repeated eval/build work or at
  least model the suite as a more honest aggregator derivation.

There was also a softer implementation difference:

- **Claude** preferred `runCommand`-style suites as the cleanest fit
- **Gemini** preferred `pkgs.linkFarm`
- **Copilot** and **Codex** were comfortable with either as long as the economic
  claim stayed honest and the exported surface shrank

So the disagreement was not over whether the current surface is too big.
It was over how strongly the project should tie `linkFarm` itself to the spend
reduction story.

### Final synthesis

The strongest maintained answer from this round is:

- the project **should** reduce the exported `checks` surface in
  `nix-router-optimized`
- but it should **not** tell itself a comforting false story that `linkFarm`
  alone solves the billing problem
- the likely gains from fewer exported jobs are:
  - less CI/UI/status clutter
  - some per-job scheduling / provisioning overhead reduction
  - a simpler commit-level signal
- the larger billing win, if one exists, will come only from also reducing
  duplicated evaluation / build work or modeling the suites so that the CI
  runner performs less repeated setup

The panel rejected two bad extremes:

- **bad extreme A:** keep exporting `174` tiny checks because perfect granularity
  is always worth it
- **bad extreme B:** wrap the same `174` checks in `linkFarm` and call the cost
  problem solved

The maintained line is:

- export a few meaningful CI suites
- keep the fine-grained checks available locally
- use `linkFarm` / `symlinkJoin` only as one possible presentation tool
- and measure worker-seconds before and after rather than assuming the job count
  story is the whole economic truth

### Recommended next-month sequence

1. **Audit the `nix-router-optimized` check surface by type.**
   Separate the `174` exported checks into categories like:
   - positive eval checks
   - failure eval checks
   - heavier `runCommand` or integration-style checks

2. **Redesign the exported flake `checks` into a handful of suites.**
   Aim for roughly `3`–`8` top-level CI suites rather than `174` individual
   exported jobs.

3. **Prefer real suite derivations over a purely cosmetic wrapper.**
   `linkFarm` is acceptable if the goal is only surface compression, but the
   stronger option is a suite derivation or other aggregation pattern that keeps
   failure semantics honest and may reduce repeated setup work.

4. **Keep fine-grained checks available for local/manual use.**
   The project should preserve targeted developer debugging rather than forcing
   every investigation through one giant CI monolith.

5. **Measure worker-seconds before and after.**
   The round explicitly rejected guessing here.
   The maintainer should compare real `nix-ci.com` spend and job behavior across
   a small before/after window.

### Verdict

Reduce `nix-router-optimized` to a few exported Nix-first CI suites, treat `linkFarm` as optional surface aggregation rather than the main cost lever, and validate the change against real before/after worker-second measurements.

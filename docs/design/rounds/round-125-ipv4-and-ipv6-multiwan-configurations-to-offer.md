## Round 125 — IPv4 and IPv6 Multi-WAN Configurations to Offer

**Tags:** router, multiwan, ipv4, ipv6, failover, pvd, nptv6, nat66, policy-routing  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** Gemini emitted its usual keychain fallback warnings first,
but did return substantive seat text, so it counts as a full roster round.

### Round question

The maintainer wanted a real roundtable on what `nix-router-optimized` should
actually offer for **both IPv4 and IPv6 multi-WAN**.

This was not just a theory question about Linux networking possibilities.
It was a product-boundary question:

- which multi-WAN shapes deserve first-class support
- which ones should stay advanced or experimental
- whether IPv4 and IPv6 should be presented symmetrically
- and what the honest support boundary is for a router flake that already has:
  - `router-mwan`
  - `router-ha`
  - MAC cloning / WAN failover mechanics
  - policy-routing hooks
  - PvD support
  - `router-nptv6`
  - and an `ipv6Masquerade` / NAT66 escape hatch

### Grounding used in this round

Local repo grounding carried into the round:

- `modules/router-mwan.nix` currently implements a simple, comprehensible
  **health-checking and route-metric switching** model for multiple WANs
- `README.md` already advertises:
  - WAN HA with MAC cloning for certain failover topologies
  - Multi-WAN failover with automatic health checking and priority switching
- `modules/router-networking.nix` already exposes:
  - policy-routing hooks
  - `ipv6Masquerade`
  - and PvD / `pvds` support
- `docs/IPV6-PVD.md` explicitly frames PvDs as a way to use multiple uplinks and
  avoid translation where clients support it
- `docs/work-items/24-router-nptv6-module.md` frames NPTv6 as the cleaner
  stable-prefix fallback compared with NAT66

This meant the real issue was not “invent multi-WAN from zero,” but:

- how to present the existing pieces coherently
- what to bless as normal operator-facing configurations
- and what to keep boxed behind advanced boundaries

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

- Strongest on the claim that IPv4 and IPv6 multi-WAN should be treated as
  **intentionally different products**
- Favored:
  - first-class IPv4 failover / prioritized uplinks
  - advanced-only weighted IPv4 distribution
  - and an IPv6 stack led by PvD plus policy routing, with NPTv6 as the
    stable-prefix fallback
- Most explicit that broad “load-balancing” language would create support
  expectations the repo does not actually satisfy

#### Gemini CLI

- Strongest on the idea of a **two-tier product line**:
  polished failover vs advanced balancing / translation patterns
- Most open to a future advanced IPv4 ECMP-style module, but only with very
  severe caveats
- Favored a more ambitious IPv6 ladder:
  PvD first, then source-based policy routing, then NPTv6, with NAT66 clearly
  discouraged
- Emphasized MTU asymmetry, sticky-session breakage, and source-address
  selection as the core support traps

#### Claude CLI

- Strongest on keeping the default support boundary **narrow by design**
- Most skeptical of weighted IPv4 ECMP and similar “sounds nice, breaks in
  practice” balancing stories
- Most willing to elevate **NPTv6** as the first-class IPv6 multi-WAN answer
  because it works regardless of client PvD support
- Strongest on the need to auto-generate IPv6 source-based routing rules if the
  repo ever presents multiple active IPv6 uplinks as normal

#### DeepSeek API

- Strongest on the framing of:
  - a **Unified Connectivity** model for IPv4
  - and an **Explicit Path** model for IPv6
- Most supportive of keeping IPv4 failover as the mainstream path while allowing
  advanced weighted ECMP as a separate opt-in module if ever added
- Most bullish on NPTv6 with stable ULA-inside / translated-outside behavior as
  the most operator-friendly IPv6 fallback
- Also reinforced that IPv6 multi-WAN is not just “IPv4 load balancing with
  bigger addresses”; source selection and prefix correctness dominate

#### Copilot

- I agreed with the panel's main asymmetry:
  IPv4 multi-WAN can be sold as a polished failover product now, but IPv6
  multi-WAN should be offered as a more explicit toolbox / decision tree
- My strongest synthesis point was:
  the flake should not promise a symmetric “multi-WAN” matrix where IPv4 and
  IPv6 look equivalent, because that would overstate what the current pieces
  actually guarantee
- I also agreed that the repo's existing pieces already suggest the right shape:
  - `router-mwan` = failover / prioritization
  - PvD = native multi-prefix path
  - NPTv6 = stable-prefix escape hatch
  - NAT66 = compatibility escape hatch only

### First-pass convergence

The substantive voices converged on the following points.

1. **IPv4 and IPv6 multi-WAN should not be presented as symmetrical products.**
   This was the strongest round-wide convergence.

   IPv4 is mainly:

   - default-route preference
   - failover
   - and selected traffic steering

   IPv6 is mainly:

   - source-address correctness
   - delegated-prefix handling
   - client support variance
   - and choosing between native multi-prefix and translation patterns

2. **For IPv4, the current failover / prioritization model is the right
   first-class product.**
   The round strongly favored keeping `router-mwan` positioned as:

   - active/standby failover
   - prioritized uplinks
   - and possibly selected policy-routed traffic classes

   The recurring recommendation was:
   do **not** market the current or near-term IPv4 story as generic “load
   balancing.”

3. **True IPv4 balancing, if ever offered, should be advanced and narrow.**
   There was some room for future weighted outbound balancing or ECMP-like
   options, but only as:

   - new-flow steering
   - explicitly experimental
   - not health-magic
   - not state-sync
   - not connection-preserving HA

   No substantive voice supported broad, polished “carrier-grade load balancing”
   positioning.

4. **For IPv6, the repo should offer a decision ladder, not one magical answer.**
   The panel converged on the need for a ladder built from the existing pieces:

   - native multi-prefix / PvD where clients support it
   - source-aware policy routing where path steering must be explicit
   - NPTv6 when stable internal prefixing matters
   - NAT66 only as a last resort

5. **NAT66 should remain available but discouraged.**
   No substantive voice wanted NAT66 to become the recommended default path for
   IPv6 multi-WAN.

   The maintained line is:

   - allow it as an escape hatch
   - document it honestly
   - and steer operators toward PvD or NPTv6 first

6. **The biggest support burden is expectation management, not only missing code.**
   Recurrent support traps were:

   - users hearing “multi-WAN” and expecting bonding or aggregate throughput
   - session breakage during failover or rebalance
   - IPv6 source-address / upstream mismatch causing ingress filtering failure
   - PvD support variance across clients
   - prefix churn under dynamic delegation
   - and documentation that sounds broader than module behavior

### Real disagreements that remained

The main disagreement was **which IPv6 pattern should be treated as the most
“first-class” operator-facing default**.

- **Codex** and **Gemini** leaned more toward:
  - native multi-prefix plus PvD as the clean architectural answer
  - with NPTv6 as the stable-prefix fallback
- **Claude** and **DeepSeek** leaned more toward:
  - NPTv6 as the most supportable practical default when client behavior is
    unpredictable
  - with PvD better framed as an advanced or capability-dependent path

This was a real disagreement, but it did **not** break the broader convergence.

All voices agreed that:

- the repo should support both patterns
- the choice should be explained by a decision guide
- and NAT66 should stay below both of them in recommendation order

### Final synthesis

The strongest answer from this round is:

- **For IPv4, offer a polished failover / prioritized-uplink product line now.**
- **For IPv6, offer an explicit multi-WAN toolbox with a decision guide rather
  than a pretend one-size-fits-all feature.**

More concretely:

1. Keep the IPv4 first-class story centered on:
   - failover
   - priority switching
   - health checks
   - and selected policy-routed traffic steering
2. Treat any future IPv4 balancing / ECMP story as:
   - advanced
   - narrow
   - and clearly not equivalent to session-preserving HA
3. Present IPv6 multi-WAN as a choice among:
   - **PvD / native multi-prefix**
   - **NPTv6**
   - **policy routing**
   - and **NAT66** only as last resort
4. Do **not** present IPv4 and IPv6 as a symmetric product matrix just because
   both involve “multiple uplinks”

The maintained line is therefore:

- **IPv4 multi-WAN = product**
- **IPv6 multi-WAN = supportable toolbox plus decision guidance**

### Concrete follow-on work from the round

The strongest follow-on items implied by the round are:

- tighten `router-mwan` positioning in docs so it clearly means:
  - failover
  - priority switching
  - and not generic load balancing
- add a dedicated decision guide for IPv6 multi-WAN that helps operators choose
  among:
  - PvD
  - NPTv6
  - policy routing
  - NAT66
- add clearer docs or tests around IPv6 source-based routing correctness when
  multiple active uplinks are in play
- if the repo ever adds weighted IPv4 balancing, ship it under a distinct
  advanced boundary rather than widening the meaning of `router-mwan`

The strongest practical recommendation right now is:

- keep the current IPv4 failover story
- avoid overselling balancing
- and make the IPv6 story more opinionated by documenting the ladder rather than
  leaving operators to infer it from scattered modules

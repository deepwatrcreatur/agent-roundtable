# Round 127 — Router Kea HA Direction After Fresh Live Evidence

**Tags:** router, kea, ha, standby, incident, failover, product-boundary  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, `opencode/nemotron-3-super-free`, Copilot synthesis

### Round question

The maintainer wanted a real roundtable on what the project should now do about
router DHCP HA after fresh live evidence changed the factual picture.

This was not a generic HA theory question. It was a product and operations
question about a specific router pair.

### Grounding used in this round

The shared prompt grounded every seat in the same current facts:

- fresh 2026-05-22 live evidence showed:
  - `router` is actively serving fresh DHCP on `10.10.10.2`
  - `router` live `/etc/static/kea/dhcp4-server.conf` has no
    `hooks-libraries`
  - `router` Kea control socket exposes no HA commands
  - `router-backup` has LAN carrier on `ens19` and management on `ens18`
  - `router-backup` Kea is inactive because `ExecCondition=exit 1`
  - `router-backup` has no `/run/kea/dhcp4.sock`
  - `router-backup` live DHCP4 config has the same non-HA shape
- current `unified-nix-configuration` also evaluates:
  - `services.router-kea.dhcp4.ha.enable = false` on `router`
  - `services.router-kea.dhcp4.ha.enable = false` on `router-backup`
- `hosts/nixos/router/role.nix` explicitly says the family-facing router is the
  sole participant while the backup is used as a development and recovery
  target
- the dormant `dhcp4.ha` block still points at management-plane addresses and
  carries a comment that DHCP HA is still a client-path regression
- the old incident framing based on E43 was stale; fresh E44 says the pair is
  not running Kea HA at all

### Questions asked

The panel was asked:

1. Should the project restore active Kea HA on the router pair as a real
   product goal, or explicitly standardize the current non-HA/single-active
   DHCP model instead?
2. What is the strongest argument for restoring Kea HA, and what is the
   strongest argument against it?
3. If the project does not restore Kea HA now, how should the incident and
   support boundary be reframed so this is honest rather than ambiguous?
4. What operational role should `router-backup` have in the preferred design?
5. What concrete next sequence of work items or decisions should happen?
6. What would count as enough evidence to mark the question settled?

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **DeepSeek API:** substantive (`deepseek-v4-flash`)
- **OpenCode free-model enrichment seat:** substantive
  (`opencode/nemotron-3-super-free`)
- **Copilot:** substantive

This round therefore had a **full substantive core roster** plus one real
experimental enrichment seat.

### Voice summaries

#### Codex CLI

- Strongest on the claim that the project should **standardize the current
  non-HA, single-active DHCP model now**.
- Treated the strongest pro-HA argument as automatic DHCP continuity on primary
  failure.
- Treated the strongest anti-HA argument as the already-documented
  client-impacting `WAITING` failure mode on the actual pair.
- Best operational label: **promotion target** rather than vague HA language.
- Wanted:
  - explicit single-active product decision
  - stale incident language closed as superseded
  - a manual promotion runbook
  - HA only revisited under a fresh redesign with explicit proof gates

#### Gemini CLI

- Also recommended **explicit non-HA / single-active standardization**.
- Strongest on the principle that a family-facing router must boot and serve in
  isolation; the Kea HA state machine violates that if peer absence suppresses
  local service.
- Best reframing: not “broken HA” but **managed manual failover**.
- Best role label: **warm standby / development target**.
- Wanted:
  - remove dormant HA blocks and ambiguous comments
  - replace silent `ExecCondition` behavior with an explicit promotion toggle
  - document and drill manual failover

#### DeepSeek API

- Most explicit that the project should **abandon Kea HA as a near-term product
  goal for this pair**.
- Strongest pro-HA argument: eliminating DHCP as a single point of failure.
- Strongest anti-HA argument: restoring it would reintroduce a known regression
  risk for no currently demonstrated benefit.
- Wanted the incident closed with a clear statement that the current design is
  deliberately non-HA and the backup is a cold/manual promotion target.
- Strongest cleanup ask: remove the dormant HA configuration entirely from the
  live design path if it is not an active goal.

#### `opencode/nemotron-3-super-free`

- Short but clear.
- Recommended standardizing the current non-HA / single-active DHCP model.
- Best concise framing:
  - backup is a manual promotion target / management-only spare
  - adjust docs and monitoring to match the intentional non-HA boundary
- Counted as a useful enrichment seat, not a substitute for the main quorum.

#### Copilot

- I aligned with the overall convergence:
  the live state and the current source state now agree that Kea HA is off.
- The strongest reason to stop calling this an “HA convergence” problem is that
  the current question is not transport mismatch anymore; it is whether the
  project still wants HA as a product goal.
- My strongest synthesis point was:
  **do not reopen DHCP-path risk on the family-facing router without first
  making an explicit architectural decision that HA is worth the complexity and
  then defining a new proof bar.**

### Convergence

The voices converged strongly on the following points.

1. **The current honest product boundary is non-HA / single-active DHCP.**
   No substantive voice argued that the project should quietly continue with the
   current ambiguity.

2. **The live incident framing must change.**
   The stale E43 story about mixed HA URLs is no longer the active truth.
   Fresh evidence says the pair is not running Kea HA at all.

3. **`router-backup` should be framed as a promotion target, not an HA peer.**
   The exact label varied slightly:
   - promotion target
   - warm standby
   - cold/manual standby
   But the shared substance was the same:
   it is not an automatic DHCP failover peer today.

4. **Dormant HA language is now harmful.**
   All substantive voices wanted the repo to stop implying an active HA product
   story if `ha.enable = false` and the standby node is intentionally prevented
   from starting Kea.

5. **Manual promotion/runbook work is higher value than immediate HA revival.**
   The near-term operational need is a truthful recovery model, not another
   risky attempt to silently restore native Kea HA.

### Real disagreements

There was no major strategic disagreement.

The only small differences were:

- whether `router-backup` is best described as:
  - **cold standby**
  - **warm standby**
  - or **promotion target**
- whether dormant HA config should be:
  - removed immediately
  - or left as an explicitly deferred future-design hook

These are sequencing and language disagreements, not architecture-level
conflicts.

### Round conclusion

The round’s answer was:

- **Do not treat active Kea HA restoration as the default next move.**
- **Standardize the current non-HA, single-active DHCP model explicitly.**
- **Reframe the incident as “HA is not in service” rather than “HA is broken but
  almost converged.”**
- **Define `router-backup` as a manual promotion target with a clear runbook.**
- **If DHCP HA remains a future product goal, reopen it as a fresh design item
  with a much higher proof bar tied to this actual router pair.**

### Concrete next actions implied by the round

1. Update repo docs and comments so they no longer imply active or near-active
   Kea HA for this pair.
2. Keep incident `2026-04-23` open only until the stale framing is replaced and
   the support boundary is made explicit.
3. Add or refine a manual promotion runbook for `router-backup`.
4. Decide whether dormant HA config should be removed entirely or preserved only
   behind a clearly deferred future-design boundary.
5. If HA is ever revisited:
   - require a new design checkpoint
   - require proof that peer absence does not disable DHCP on the primary
   - require repeatable live validation on this actual pair before any claim of
     restored support

### Satisfaction markers returned

- **Codex CLI:** `[satisfied]`
- **Gemini CLI:** `[satisfied]`
- **DeepSeek API:** `[satisfied]`
- **OpenCode / Nemotron free seat:** `[satisfied]`
- **Copilot:** `[satisfied]`

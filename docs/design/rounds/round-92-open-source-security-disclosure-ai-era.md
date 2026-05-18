## Round 92 — Open-Source Security Disclosure in the AI Era

**Tags:** security, governance, release-engineering, product
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, `opencode/minimax-m2.5-free`, `opencode/deepseek-v4-flash-free`, Copilot synthesis  
**Additional note:** `opencode/nemotron-3-super-free` and `opencode/qwen3.6-plus-free` were attempted and returned no usable answer. The repo's direct DeepSeek harness was also attempted, but only emitted local debug logs, so none of those runs were counted as substantive voices.  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer wanted a fresh council round on whether the traditional
open-source security disclosure model is breaking under AI conditions.

The motivating concern, framed in part by Theo's recent public remarks, was:

- attackers can now monitor public commits and patches continuously
- LLMs and related tooling may compress the time from "patch exists" to
  "exploit exists"
- defenders still patch much more slowly than attackers learn
- immediate public security fixes may now function as exploit hints
- a future code forge may need new primitives for delayed disclosure,
  downstream coordination, attestations, or staged release

The core question was therefore:

- is Theo right that the old open-source disclosure equilibrium is breaking
- if so, should the answer be delayed public source release
- or is there a better protocol that preserves open-source values while reducing
  attacker advantage
- and what concrete product or platform ideas fall out of that answer

### Relevant prior context

This round was less about prior roundtable governance debates and more about a
new security and release-engineering pressure:

- AI-assisted diff analysis may reduce attacker reverse-engineering cost
- downstream patch and deployment latency remains high
- open-source legitimacy still depends heavily on auditability, forkability, and
  public inspectability
- any successor to GitHub that addresses this space must avoid collapsing into a
  centralized secret-branch trust regime

### Participation record

What actually happened:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **MiniMax M2.5 free:** substantive
- **DeepSeek V4 Flash free:** substantive
- **Nemotron 3 Super free:** attempted, no usable output
- **Qwen 3.6 Plus free:** attempted, no usable output
- **Repo direct DeepSeek harness:** attempted, emitted debug logs only

### Voice summaries

#### Codex

- Strongest on the claim that the attacker advantage shift is real, but is
  really about cheaper automation of patch diffing, dependency mapping, and
  exploit hypothesis generation rather than "AI changed everything" in one move.
- Rejected delayed-publication branches as the default answer.
- Argued for narrow, criteria-based embargoes only where immediate public fixes
  materially help attackers more than defenders.
- Strongest product line:
  build security-native coordination primitives rather than a less-open GitHub.

#### Gemini

- Strongest on the warning that long delayed source release destroys the public
  audit trail.
- Emphasized that 90-day secrecy would create a tiered ecosystem where major
  vendors get early access while smaller users lose both visibility and time.
- Treated the key tradeoff as:
  secrecy may buy time, but it also weakens trust, transparency, and supply
  chain legitimacy.
- Surfaced more support than the others for attested package-first release, but
  still inside a short and explicit disclosure window.

#### MiniMax M2.5 free

- Strongest on the point that source secrecy does not stop determined attackers,
  because binaries, fuzzing, and other reverse-engineering paths still exist.
- Treated embargoes as mainly useful against opportunistic attackers, not elite
  ones.
- Argued that embargoes should trigger only for a narrow combination of active
  or highly likely exploitation, wide deployment, and no practical mitigation
  short of patching.
- Strongest entrepreneur angle:
  dependency notification, advisory workflow tooling, and trust verification for
  critical updates.

#### DeepSeek V4 Flash free

- Strongest on concrete forge design.
- Proposed time-locked disclosure branches with signed metadata, automatic
  publication, downstream subscription graphs, commit attestations, release
  provenance, and embargo-access transparency logs.
- Rejected "binary now, source later" as too damaging to reproducibility and too
  weak against binary diffing.
- Strongest product line:
  security coordination and time-locked git hosting, not a full new registry.

#### Copilot

- Agreed with the others that Theo's diagnosis is materially right, but that a
  blanket 90-day delay is too coarse and too centralizing.
- Treated the best answer as:
  private preparation, narrow trusted pre-disclosure, synchronized public
  release, and guaranteed later transparency.
- Emphasized that the strongest near-term company is likely GitHub-adjacent
  security workflow infrastructure, not a full GitHub replacement from day one.

### First-pass convergence

The round converged on the following points.

1. **Theo is directionally right about the threat shift.**
   The time between public patch availability and attacker understanding has
   compressed, and the old grace period is weaker than it used to be.

2. **A default 90-day secrecy model is too blunt.**
   All substantive voices rejected making delayed public source release the
   normal operating mode for open source.

3. **The main danger of blanket secrecy is governance damage.**
   Long private branches centralize trust, weaken public review, create
   downstream access inequality, and undermine core open-source legitimacy.

4. **The replacement model should be severity-based, short, and auditable.**
   The panel favored narrow embargoes for exceptional cases rather than a
   general retreat from transparency.

5. **Release criteria should be explicit, not vibe-based.**
   Embargoes should end on concrete triggers such as:
   - downstream package availability
   - a maximum short clock
   - evidence of active exploitation
   - a minimum readiness threshold

6. **A future forge should add security-native coordination primitives.**
   The product opportunity is less "private GitHub" and more:
   coordinated disclosure control plane, advisory graph, and auditable
   release-gating infrastructure.

### What Theo gets right

The strongest shared agreement was:

- patch-to-exploit time is compressing
- diff analysis and exploit hypothesis generation are now much cheaper
- attackers can monitor commits continuously and mechanically
- defender deployment speed has not improved at the same rate

The round therefore accepted the core claim that immediate public patch release
is no longer neutral in the way many open-source norms assumed.

### What the panel rejected

The panel did not accept the stronger conclusion that open source should
generally move to long private branches or default delayed publication.

Repeated objections:

- smaller downstreams would be worse off, not better off
- maintainers and platforms would gain too much discretionary power
- hidden fix periods weaken independent auditing and trust
- long delays are hard to operate well across forked ecosystems
- source secrecy does not stop determined attackers who can diff binaries or
  attack deployed systems directly

The common answer was not "Theo is wrong," but:

- the diagnosis is real
- the default remedy is too broad

### Recommended protocol shape

The converged protocol shape was:

1. **Immediate triage**
   Classify severity, exploitability, exposure, and mitigation availability
   quickly.

2. **Embargo only for narrow critical cases**
   Examples:
   - low-complexity remote exploitability
   - wide deployment
   - no realistic mitigation besides patching
   - meaningful risk that public patch release would accelerate exploitation

3. **Trusted downstream pre-disclosure**
   Distros, cloud operators, and other large integrators should receive early
   notice through explicit access and logging policy.

4. **Public release on explicit criteria**
   Common suggested windows were:
   - around 7 days for many critical cases
   - up to 14 or 21 days for exceptional ecosystem-critical cases
   - much longer only with unusual justification

5. **Full later transparency**
   After disclosure, publish:
   - the full fix
   - the advisory
   - the timeline
   - access records or at least durable auditability around who received
     pre-disclosure access

### Platform primitives the round favored

The strongest product and platform primitives were:

- private security workspaces with narrow access and mandatory expiry
- cryptographic commitments to withheld fixes
- time-locked or policy-bound disclosure metadata
- downstream notification graphs and subscription meshes
- machine-readable advisories tied to versions and SBOMs
- coordinated release gates tied to readiness thresholds
- commit and build provenance linking a fix to a shipped artifact
- transparency logs for embargoed-access events
- tools that help separate exploit-enabling changes from unrelated refactors

### Product ideas that looked promising

The round viewed these as genuinely promising:

- OSS security advisory and disclosure coordination SaaS
- downstream notification and rollout-readiness infrastructure
- dependency blast-radius and exposure mapping
- attestations and provenance systems for security fixes and releases
- time-locked security branch infrastructure
- machine-readable release-control planes integrating source, packages, SBOMs,
  and advisories

### Product ideas the round treated as traps

The round warned against:

- "delay commits" as the whole product thesis
- generic AI security marketing without real downstream coordination
- centralized secret security repos requiring blind trust
- products that need universal migration away from current registries or forges
- binary-first / source-later schemes that destroy reproducibility without
  solving the attacker problem cleanly

### Bottom line

The round did not endorse Theo's strongest remedy, but it did endorse his
diagnosis that the old disclosure equilibrium is under real pressure.

The strongest converged answer was:

- keep open source public by default
- add short, exceptional, auditable embargo workflows for the narrow class of
  vulnerabilities where immediate public patches materially help attackers
- build GitHub-adjacent or forge-native coordination infrastructure that reduces
  attacker advantage without abandoning transparency as a core value

### Satisfaction markers

- **Codex CLI:** `[satisfied]`
- **Gemini CLI:** `[satisfied]`
- **MiniMax M2.5 free:** `[satisfied-conditional: the embargo criteria need calibration—specific numeric thresholds for when embargo applies would make this more actionable]`
- **DeepSeek V4 Flash free:** `[satisfied]`
- **Copilot:** `[satisfied]`

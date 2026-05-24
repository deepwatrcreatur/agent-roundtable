## Round 129 — Local Harness Collisions vs Isolated Cloud Sandboxes

**Tags:** hygiene, workspaces, worktrees, opencode, replit, exe.dev, hosting  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, OpenCode free-model seat, Copilot synthesis  
**Additional note:** Gemini initially failed on the full prompt inside its own
router and was recovered with a shorter retry. OpenCode was used as an explicit
enrichment seat via `opencode/nemotron-3-super-free`.

### Round question

The maintainer wanted a follow-up round on a recurring operational pain:

- agents are still colliding in shared local checkouts
- repeated worktree guidance has not made the collisions disappear
- local cleanup still often turns into stash/replay/cherry-pick repair
- and it is unclear whether better local harnesses will eventually solve this,
  or whether the real answer is stronger sandboxing outside the shared machine

The sharper decision questions were:

- is this mainly a harness/defaults problem or a workspace-isolation problem
- how much should the project expect from local harnesses such as OpenCode
- whether Replit's isolated-task model is structurally closer to the right
  answer
- whether exe.dev is a credible near-term mitigation path for collision-prone
  work such as `vaglio` deployment work or a router test VM
- and what next-6-month operating model should replace today's repeated
  instruction tightening

### Grounding used in this round

Relevant prior local context carried in:

- **Round 108** — OpenCode is useful for experimental free-model access, but
  harness choice by itself does not solve deeper coordination problems
- **Round 116** — dirty-checkout failures persist because the shared checkout is
  still the easiest writable default
- **Round 117** — `jj` helps local mutation semantics but does not solve
  claims, leases, authority, or promotion sequencing
- **Round 119** — the future hosted control plane should stay narrow: claims,
  leases, lineage, promotion gates, and visible human control

Fresh external grounding carried in:

- **Replit docs / changelog**
  - active tasks run in isolated copies of a project
  - parallel background task limits exist at the product tier level
  - apply-back review and conflict handling are explicit product surfaces
  - newer multi-artifact projects share backend/deployment/data while still
    supporting parallel agent work
- **exe.dev docs**
  - `ssh exe.dev new` provisions fresh internet-reachable VMs
  - Codex, Claude, and Shelley are preinstalled on new VMs
  - persistent disks, HTTPS/IAM defaults, and repo-launch paths are built in
  - Shelley can consume repo instructions such as `AGENTS.md`
- **OpenCode**
  - useful as a real enrichment path for free/cheap extra seats
  - but historically not treated as the core serious quorum

Important scope boundary carried into the round:

- the question was **not** whether local harnesses are useless
- it was whether they can ever be the main answer to shared-checkout collisions
  in the face of repeated practical failure

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive after a shorter retry prompt
- **Claude CLI:** substantive
- **DeepSeek API:** substantive via direct HTTP API and local decrypted key
- **OpenCode free-model seat:** substantive via `opencode/nemotron-3-super-free`
- **Copilot:** substantive

This round therefore had a **full substantive core roster plus one substantive
enrichment seat**.

### Voice summaries

#### Codex CLI

- Strongest on the claim that this is primarily a **workspace-isolation
  problem**, not a harness-UX problem
- Treated local harnesses as helpful for invocation, provider routing, and
  worktree ergonomics, but not capable of fixing the default writable-path
  problem
- Preferred exe.dev as the near-term practical fit because it improves isolation
  without forcing a Replit-shaped product shift
- Recommended a three-tier near-term model:
  - local worktrees for low-risk work
  - exe.dev VMs for collision-prone/deployment work
  - Replit only as a deliberate hosted-task pilot

#### Gemini CLI

- Strongest on the argument that shared-checkout collisions are fundamentally a
  **mutable-filesystem chokepoint**
- Most explicit that local harnesses cannot solve concurrent mutation of one
  checkout because they do not own file locking, rollback, or durable leases
- Treated Replit as structurally strong because its isolation is enforced rather
  than advisory
- Favored exe.dev for dedicated VM isolation and argued that stronger
  instructions in shared repos eventually lead to state corruption and desperate
  recovery actions

#### Claude CLI

- Strongest on the line that this is not a disobedience problem but a **missing
  lease primitive** problem
- Most explicit that OpenCode is still the same shared-checkout model with a
  different frontend if it stays local
- Framed Replit as stronger on bundled apply-back semantics and exe.dev as the
  more natural fit for the project's current stack and deployment shape
- Recommended a concrete tiered model:
  - local worktrees for simple serial work
  - exe.dev for `vaglio` and router-test VM work now
  - Replit later only if its workflow constraints fit

#### DeepSeek API

- Strongest on the claim that the problem is **writable defaults plus lack of
  isolation**, not a lack of smarter harness prompts
- Most explicit that Replit and exe.dev are both sandbox providers rather than
  the full coordination plane from Round 119
- Favored exe.dev as an immediate practical mitigation while warning that it
  does not solve claims, leases, or branch-level conflict by itself
- Most forceful against the “just add stronger instructions” path, describing it
  as an infinite regress of brittle local rules

#### OpenCode free-model seat

- Reinforced the same central line as the stronger seats:
  local harnesses can reduce friction but cannot replace actual isolated working
  copies
- Framed Replit as lighter-weight hosted isolation and exe.dev as heavier but
  more flexible VM isolation
- Favored a split where local worktrees remain for low-risk work, exe.dev is
  used for deployment/infrastructure tasks, and Replit is used where its
  apply-back workflow is worth the platform dependence

#### Copilot

- I agreed with the convergence that repeated collisions are the result of the
  wrong default execution boundary, not insufficient prose
- My strongest synthesis point was that the project should stop asking shared
  local repos to behave like a coordination system when they are merely mutable
  filesystems
- I also agreed that exe.dev is the most plausible immediate next step because
  it improves isolation without requiring an early strategic commitment to a
  Replit-shaped hosted product

### First-pass convergence

The substantive voices converged on the following points.

1. **This is fundamentally a workspace-isolation problem.**
   Better local harnesses can improve ergonomics, but not make one shared
   mutable checkout safe for concurrent agent writes.

2. **Local harnesses remain useful, but only at the invocation layer.**
   They help with model access, provider routing, prompt discipline, and maybe
   worktree bootstrap, but not with claims, leases, or collision-proof
   mutation.

3. **Replit demonstrates the structurally right isolation shape.**
   Its isolated task copies and apply-back flow show what enforced separation
   looks like when the host owns the workflow.

4. **exe.dev is the best near-term mitigation for this project's highest-risk
   work.**
   It supplies real sandboxing now, fits the current stack better than Replit,
   and can immediately absorb `vaglio`/router-test work without redesigning the
   whole product.

5. **Neither Replit nor exe.dev replaces the future control plane.**
   They solve isolation at different layers, but not the claims/leases/lineage
   coordination boundary that Round 119 described.

6. **Trying to solve this mainly with stronger repo instructions is the wrong
   direction.**
   The repeated failure mode is procedural escalation around a bad writable
   default.

### Real disagreements that remained

There was no major strategic disagreement, but there were real differences in
timing and emphasis:

- **Codex** was most explicit that Replit should be treated only as a pilot, not
  the main system assumption
- **Gemini** was most absolute that shared-checkout collision is a structural
  problem and not realistically fixable by local-harness evolution
- **Claude** was strongest on the lease/file-lock framing
- **DeepSeek** was most emphatic that exe.dev is only half the answer because it
  solves isolation without solving coordination

These were differences in rollout posture, not direction.

### Final synthesis

The strongest answer from this round is:

- **do not expect local harnesses to solve shared-checkout collisions as the
  main path**
- they can help around the edges, but the real fix is to stop treating one local
  writable checkout as common agent space
- use actual isolation for the risky work now
- and keep the future control plane question separate from the immediate
  sandboxing question

The panel rejected two bad extremes:

- **bad extreme A:** “keep refining instructions and local hygiene until the
  collisions go away”
- **bad extreme B:** “move everything to a hosted product immediately and let
  that become the architecture”

The maintained line is:

- local worktrees remain useful for low-risk serial work
- exe.dev should be used soon for the worst collision-prone and deployment
  workloads
- Replit is strategically informative because it proves the value of enforced
  isolation plus apply-back flow
- but the project should not confuse that with owning its own control plane

### Recommended next-6-month operating model

1. **Local worktrees by default for simple single-agent work.**
   Keep them for bounded, serial code/docs work where the maintainer still wants
   local speed.

2. **exe.dev VMs by default for collision-prone and environmentful work.**
   Start with:
   - `vaglio`-adjacent deploy/test work
   - router test VM work
   - long-running or infrastructure-oriented agent tasks

3. **Treat each exe.dev VM as one task sandbox.**
   The durable artifact is the branch/PR/output, not the VM itself.

4. **Evaluate Replit as a hosted-task UX reference, not yet the core stack.**
   Use it to learn from isolated task copies and apply-back semantics, not as an
   immediate architectural dependency.

5. **Keep building toward the narrow hosted control plane.**
   Isolation reduces collisions now, but claims/leases/lineage remain the next
   real product layer.

### Satisfaction marker

This round is satisfied if:

- the project stops treating shared local checkouts as the normal concurrent
  write surface
- exe.dev is trialed soon for `vaglio` and router-test work
- and future work on harnesses stays scoped to invocation ergonomics rather than
  pretending to replace isolation


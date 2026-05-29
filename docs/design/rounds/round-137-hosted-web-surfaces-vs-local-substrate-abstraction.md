# Round 137: Hosted Web Surfaces vs Local Substrate Abstraction

## Question

Theo argued that source control should not require a "real OS + filesystem" and
that current worktrees are fundamentally broken for agent-heavy development.
Does that imply this project should move toward a GitHub + Codespaces or
Replit-like hosted development surface, instead of a local TUI / agent CLI
running on a local filesystem such as APFS?

## Why this round exists

Recent rounds already narrowed several nearby questions:

- Round 129 concluded that local harness/frontend changes alone do not solve
  mutable-workspace collisions and that isolated cloud sandboxes can be useful
  for risky work.
- Round 130 concluded that the long-run design should be a narrow hosted control
  plane above multiple execution substrates, not a single bundled hosted product.
- Round 134 concluded that VFS / virtual working copies mainly address checkout
  materialization and monorepo I/O, not the deeper ownership/collision problem.
- Round 136 concluded that the right filesystem-layer move is a capability-based
  workspace-backend contract, with Btrfs, ZFS, and APFS as backends beneath a
  wrapper path rather than as the architecture itself.

This round asks whether Theo's stronger rhetoric should alter that direction, or
whether it mainly reinforces the same boundary in sharper terms.

## Fresh external grounding

- GitHub describes Codespaces as a cloud development environment closely
  integrated with GitHub repositories and development workflows.
- Replit presents a browser-first cloud development environment with integrated
  AI assistance and hosted runtime/execution loops.

These products matter here not as adoption targets in themselves, but as clear
reference shapes for a hosted substrate that reduces dependence on the user's
local filesystem and OS.

## Panel

### Seat 1 - Codex

Codex's main line was that Theo's complaint is a strong reason to improve the
workspace abstraction and execution UX, but not a reason to collapse the
project's strategy into "be Codespaces/Replit."

Its strongest distinctions were:

- Theo's point about not needing a "real OS + filesystem" is mostly a complaint
  about materialization and API shape.
- The harder unsolved problem for this project is ownership, collision, and
  governance around mutable state.
- Hosted sandboxes help with isolation and reproducibility, but a hybrid
  control-plane-above-multiple-substrates design is the only shape that solves
  the deeper governance problem without forcing a browser-first product.

Codex recommended defining the capability contract first, then implementing both
the local wrapper path and a hosted sandbox adapter beneath it.

### Seat 2 - Claude

Claude argued most strongly that Theo's complaint is valid as a criticism of
today's workspace API, but does not itself justify a product pivot to a hosted
web IDE.

Its clearest points were:

- Theo is mostly attacking the fact that current workspaces are over-exposed as
  raw filesystem paths and checkout mechanics rather than presented as a cleaner
  logical workspace surface.
- VFS-style work can relieve that API/materialization pain, but neither VFS nor
  a hosted product alone solves ownership, capability, or audit boundaries.
- A Codespaces/Replit-style default would buy easy isolation at the cost of
  architectural lock-in, cost sensitivity, and abandoning users who need local
  or offline execution.

Claude's verdict was that Theo's complaint should become an abstraction-quality
test for the workspace contract, not a command to make the browser tab the
product.

### Seat 3 - GPT-5.4 mini

The mini seat converged with the others and framed the issue as "the local
filesystem is one backend, not the architecture."

Its most useful synthesis was:

- Theo's complaint should push the project away from filesystem-centric
  architecture.
- It should not push the project all the way into a hosted web development
  surface as the main shape.
- The correct response is to preserve local CLI/TUI clients while adding a
  hosted control plane that can allocate local filesystems, virtual copies, or
  remote isolated sandboxes depending on the task.

This seat particularly emphasized using hosted execution for risky,
collision-prone, or highly parallel work while keeping local execution as a
first-class path for cheaper and more direct workflows.

## Main distinctions clarified

### 1. Materialization/API-shape complaints are real, but narrower

Theo's point 4 is best understood as saying:

- developers and agents should not need to care so much about raw checkout
  paths, worktree plumbing, mounted volume semantics, or filesystem quirks;
- reading files, applying patches, diffing branches, and preparing task-local
  views should be available through a cleaner workspace abstraction.

This is a serious complaint, but it is mostly about how the workspace is exposed
to tools and agents.

### 2. Ownership/isolation/governance remain the deeper local bottleneck

The project's recent rounds have repeatedly found that the harder problem is not
simply "how do we materialize files cheaply?" but:

- who owns the mutable workspace;
- which actor has mutation rights right now;
- how live resources are isolated;
- how collisions are prevented or at least made visible;
- how the system records leases, claims, and audit trails around state changes.

Hosted environments help, but only because they are one practical way to supply
better isolation. They are not the whole answer.

### 3. Hosted web surfaces are a substrate option, not the architectural center

Codespaces- and Replit-like products demonstrate a useful substrate:

- strong per-session isolation;
- reproducible ephemeral environments;
- less exposure to local OS/filesystem quirks;
- easier policy control over risky work.

But turning that substrate into the whole product would conflict with the
maintained line from Round 130:

- the control plane should remain narrow and portable;
- execution should stay plural rather than bundled into a single hosted surface;
- local and hosted execution should both remain possible behind a common
  contract.

## Comparison of the three practical modes

### Local wrapper path over local filesystems

Strengths:

- fastest feedback and lowest latency;
- best fit for privacy-sensitive, offline, and low-cost workflows;
- keeps the current CLI/TUI path viable.

Weaknesses:

- local filesystem semantics still leak unless the abstraction is strong;
- collision/isolation remain fragile without explicit capability and lease
  discipline;
- APFS/Btrfs/ZFS differences remain operationally relevant beneath the surface.

### Hosted Codespaces/Replit-like execution

Strengths:

- stronger default isolation;
- easier ephemeral task environments;
- easier reproducibility and substrate standardization.

Weaknesses:

- cost, network dependency, and operational/vendor dependence;
- browser-first shape is not obviously the right primary UX for this project;
- hosted execution still does not by itself answer governance unless it is
  paired with explicit capability and policy boundaries.

### Hybrid control plane over multiple substrates

Strengths:

- matches the maintained direction from earlier rounds;
- keeps local CLI/TUI clients while allowing hosted execution where it is most
  useful;
- treats Btrfs/ZFS/APFS, virtual copies, and hosted sandboxes as interchangeable
  backends beneath a common policy layer;
- solves for ownership and orchestration above the substrate rather than hoping
  one substrate eliminates governance problems.

Weaknesses:

- demands a clearer contract and a bit more architectural discipline now;
- less marketable in one sentence than "browser IDE" or "local power tool";
- requires careful sequencing so the abstraction does not stay purely notional.

## Final synthesis

Theo's point 4 should change the architecture only in a bounded way:

- it should further dislodge the idea that a real local filesystem is the
  architecture;
- it should not overturn the recent consensus that the right long-run shape is a
  hosted control plane above multiple execution substrates;
- it should not cause a premature pivot into a browser-first hosted IDE product.

The main lesson is:

1. local-filesystem-centric workflow is too exposed;
2. hosted substrates are useful and probably necessary for some tasks;
3. the real architectural requirement is a workspace/execution contract that
   lets local and hosted substrates sit behind the same policy and lease model.

In simpler terms: Theo is right that agents deserve something better than raw
Git worktrees on a local disk, but the answer is not "replace the CLI with
Codespaces." The answer is to stop treating the local disk as architectural
truth.

## Recommended next move

The next practical move is not to build a hosted web product surface first.

It is to make the control-plane/substrate boundary explicit:

1. define the workspace/execution capability contract at the control-plane
   layer;
2. keep the `dmux` wrapper path as the first local substrate beneath that
   contract;
3. add a hosted sandbox adapter later as a second substrate, especially for
   risky, collision-prone, or highly parallel work;
4. judge the design by collision reduction, lease clarity, reproducibility, and
   operator control rather than by whether the user enters through a browser tab
   or a terminal.

## Verdict

Do not pivot the project toward a Codespaces/Replit-style hosted web IDE as the
main shape.

Do treat Theo's complaint as further evidence that:

- local filesystems must become replaceable backends rather than architectural
  truth;
- hosted execution is an important substrate option;
- the durable center should remain a narrow hosted control plane plus a common
  workspace/execution contract above multiple substrates.

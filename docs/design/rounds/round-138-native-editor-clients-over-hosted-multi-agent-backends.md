# Round 138: Native Editor Clients over Hosted Multi-Agent Backends

## Question

If the project should not collapse into a browser-first web IDE, what should sit on
top of the hosted backend instead? Could a VS Code plugin or Zed integration act
as the primary coding client while a hosted backend provides the real workspace
primitives: `jj`-aware working copies, subvolume/dataset isolation, leases,
snapshots, and multi-agent coordination? How should we think about tools and
projects like `cmux` and `t3code` in that picture?

## Why this round exists

The last few rounds established two important boundaries:

- Round 130 favored a narrow hosted control plane above multiple execution
  substrates rather than a single bundled hosted product.
- Round 134 argued that VFS / virtual working-copy work mainly improves
  materialization and I/O, not ownership or collision control.
- Round 136 argued for a capability-based workspace-backend contract so Btrfs,
  ZFS, APFS, and similar substrate choices stay beneath the architecture.
- Round 137 argued that Theo's critique of filesystem-centric source control does
  not require a browser-tab IDE; the backend should become the truth layer, not
  the user's local disk.

This round asks what the client layer should look like if we keep that line: not
"browser or bust," but also not "local filesystem as architecture."

## External grounding used here

- VS Code has a mature extension model and existing remote-development patterns,
  which makes it a plausible first client for a backend-defined workspace API.
- Zed already thinks in terms of AI-assisted coding and remote/editor
  responsiveness, which makes it an interesting candidate client even if its
  extension/runtime hooks are currently less mature for deep backend control.
- `jj` remains relevant as the versioned workspace substrate because it is more
  naturally aligned with multiple concurrent change lines than classic Git
  worktree ergonomics.
- The names `cmux` and `t3code` were treated here as examples of terminal-centric
  or workflow-centric parallel-agent coordination surfaces. The important point
  is not their exact branding but the class they represent: operator shells and
  multiplexed control surfaces for many agents at once.

## Panel

### Seat 1 - Codex

Codex argued that a native editor client plus hosted backend is not only
coherent, but probably better than a web IDE as the default architectural shape.
Its reasoning was:

- browser IDEs are good at packaging and distribution, but they bundle frontend,
  backend, runtime, and workspace authority too tightly;
- native editors preserve latency, familiarity, trust, and existing workflows;
- the hosted backend should own the real workspace semantics while editor
  clients remain replaceable frontends.

Codex considered VS Code the strongest near-term client because its extension and
remote-development model is mature enough to surface leases, snapshots,
agent-owned workspaces, and collision warnings without forcing a browser-first
product.

It viewed Zed as promising but still more like a phase-two client after the
backend protocol is stable.

### Seat 2 - Claude

Claude pushed hardest on the distinction between protocol and presentation.
Its strongest points were:

- the protocol is the product; editor integrations, terminal multiplexers, and
  web surfaces are all just clients of that protocol;
- VS Code can likely host a thin first integration through extension points,
  custom filesystem views, and remote-development conventions;
- Zed is philosophically attractive because it is fast, modern, and already
  interested in AI/collaboration, but it currently looks farther away from the
  extension/lifecycle surface needed for serious hosted multi-agent control.

Claude also argued that `cmux`/`t3code`-like projects are better understood as
operator shells or orchestration surfaces than as backend workspace systems.
They can complement the architecture, but they do not replace the need for the
backend to own leases, isolation, snapshots, and mutation rights.

### Seat 3 - GPT-5.4 mini

The mini seat largely converged with the others and put the matter simply:

- a native editor client plus hosted backend is the right alternative to a web
  IDE;
- VS Code is the most plausible first serious client;
- Zed is interesting but farther from hosting the needed backend-aware
  multi-agent semantics;
- `cmux` and `t3code` belong more in the workflow/orchestration layer than in
  the workspace-truth layer.

This seat especially emphasized that the backend contract must be designed first,
otherwise any editor plugin will degenerate into a leaky remote-shell adapter.

## Main distinctions clarified

### 1. The browser is not the point; backend primitives are the point

The project does not need to insist on a browser tab as the coding interface.
What it needs is a backend host that provides the right primitives:

- isolated mutable workspaces;
- `jj`-aware branching / working-copy semantics;
- fast creation and destruction via subvolumes, datasets, snapshots, or similar
  substrate capabilities;
- leases, capabilities, and clear mutation ownership;
- snapshot and rollback boundaries for risky work;
- visibility into which agent owns which workspace and what changed.

If those primitives exist behind a clean protocol, the user-facing coding surface
can be a native editor, terminal multiplexer, browser client, or several at
once.

### 2. VS Code looks like the most practical first client

Roundtable consensus favored VS Code as the first serious editor client for this
backend model because:

- its extension ecosystem is broad and proven;
- remote-development precedent makes backend connectivity a familiar shape;
- it can surface tree views, commands, diffs, diagnostics, and agent-control UI
  without inventing a whole editor from scratch;
- it lowers adoption cost because many users already live there.

The main caution is that VS Code still has many local-filesystem assumptions, so
it should be treated as a client over a backend protocol, not as the place where
backend semantics are invented.

### 3. Zed is plausible, but not the first reference client

Zed has real appeal here:

- fast editing and strong local responsiveness;
- growing AI-assisted coding posture;
- an architecture that may make a modern remote or structured backend experience
  feel very good.

But the round judged it farther from the target than VS Code today because the
necessary extension/lifecycle hooks for a deep multi-agent backend workflow are
less mature and less widely proven.

So the line is not "Zed is wrong" but rather:

- VS Code first to validate the backend contract and UX slices;
- Zed second once the contract exists and the right hooks can be targeted more
  cleanly.

### 4. `cmux` / `t3code`-style tools are operator shells, not the truth layer

This round treated `cmux` and `t3code` as examples of a useful adjacent class of
systems: tools that help operators run or observe many coding agents in parallel.

That class is valuable because it can provide:

- pane-based or session-based multiplexing;
- human oversight over many agents at once;
- task fan-out and status monitoring;
- a shell-like or cockpit-like control surface for swarm work.

But that class is not enough by itself. It usually does not own:

- authoritative workspace identity;
- lease issuance or revocation;
- snapshot and rollback policy;
- subvolume/dataset lifecycle;
- concurrency arbitration around mutable state.

So these tools are better seen as complementary clients or operator shells above
the hosted backend, not as replacements for the backend architecture.

## Comparison of the practical shapes

### Browser-first hosted IDE

Strengths:

- easy packaging and onboarding;
- highly controlled environment;
- straightforward hosted story.

Weaknesses:

- over-couples UI with backend/runtime authority;
- risks repeating the mistake of treating one client shape as architecture;
- weaker fit for users who prefer serious local editors.

### Native editor client over hosted backend

Strengths:

- preserves user ergonomics and trust;
- keeps the protocol/backend as the durable center;
- allows multiple client types over the same primitives;
- matches earlier rounds better than a browser-first bundle.

Weaknesses:

- requires a stronger protocol and cleaner contract up front;
- plugin work can become messy if attempted before backend semantics are crisp.

### Multiplexer / operator shell over hosted backend

Strengths:

- good for observing and steering many agents;
- natural fit for operational swarm workflows;
- complements both editor and browser clients.

Weaknesses:

- not enough by itself for authoritative workspace semantics;
- can encourage process-level parallelism without true state isolation if used
  alone.

## Final synthesis

The roundtable converged on a clear answer:

- the project should not insist on a browser-tab coding interface;
- it should insist on a backend host that implements the correct primitives;
- native editors can absolutely be first-class clients of that backend;
- VS Code looks like the best first editor client;
- Zed looks like a promising second-wave client;
- `cmux`/`t3code`-style systems belong in the orchestration/operator-shell layer,
  not in the backend truth layer.

In simpler terms: the architecture should be "hosted multi-agent backend first,
plural clients above it," not "browser IDE first" and not "editor plugin hacks
all the way down."

## Recommended next move

The next concrete move is not to build a full web IDE or to over-invest in one
editor plugin before the protocol exists.

It is to define and validate the backend/client contract in a thin vertical
slice:

1. backend issues a workspace lease;
2. backend creates an isolated, `jj`-aware working copy using the right
   substrate primitives;
3. client opens that workspace through a protocol rather than raw SSH or raw
   local-path assumptions;
4. backend surfaces ownership, snapshot, and rollback events;
5. one editor client (likely VS Code) and one operator shell (`dmux`/zellij-like)
   both consume the same contract.

That slice would test the architectural separation directly.

## Verdict

Yes: a VS Code plugin or Zed-like client over a hosted backend is a coherent and
likely preferable alternative to a browser-first editor.

The important separation is now sharper:

- we do **not** insist on a browser tab as the coding interface;
- we **do** insist on a backend host that owns the right workspace primitives;
- editor clients and operator shells should both sit above that same backend
  contract rather than re-implementing coordination in ad hoc ways.

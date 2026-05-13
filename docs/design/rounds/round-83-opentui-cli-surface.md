# Round 83 — OpenTUI, Terminal UX, and Whether It Should Shape the Local CLI

**Status:** Closed  
**Voices used:** Copilot research, OpenTUI primary docs, local repo grounding  
**Additional note:** this round was grounded in the current OpenTUI README/docs,
the existing board/TUI direction in this repo, and prior rounds on product
boundaries and optional interfaces

### Round question

The maintainer wanted a new round on whether the project should adopt
**OpenTUI** for the local CLI/TUI surface:

- should OpenTUI become the preferred terminal stack for the project
- should it shape the operator-facing board view
- or should it remain only a reference point while the project keeps its current
  narrower CLI/TUI-capable environment

### Relevant prior context

This round built directly on:

- **Round 62** — the split between discussion, execution dispatch, and
  long-horizon memory/governance
- **Round 64** — the generic execution VM should include a practical CLI/TUI
  toolchain without overcommitting to a heavy UI runtime
- **Round 70** — borrow useful ideas from adjacent systems without adopting a
  foreign runtime wholesale
- **Round 72** — optional interfaces are acceptable, but they must not become
  canonical memory or governance
- **Round 76** — external standards/artifacts are worth adopting when they
  improve portability, but local activation/governance stays stricter
- **Round 78** — preserve useful ritual ideas from external systems, but avoid
  ambiguous ambient dependencies

### External grounding used

OpenTUI's current public docs describe it as:

- a native terminal UI core written in **Zig**
- currently exposed primarily through **TypeScript** bindings
- component-based with layout primitives and higher-level framework bindings
- intended for rich terminal applications and used by OpenCode
- currently **Bun-exclusive**, with broader runtime support still in progress

This mattered because the project is currently:

- Elixir/Phoenix-centered for the web surface
- Nix-centric for packaging
- explicit about keeping canonical state in repo-native records / board tables,
  not in any UI layer

### First-pass convergence

The round converged on the following points.

1. **OpenTUI is interesting, but it is not the missing core architecture.**
   The project's main UI question is still the Round 62 split:
   board semantics, daemon contract, and durable memory. OpenTUI can at most be
   a presentation choice on top of that.

2. **The best fit is as an optional operator-facing convenience layer.**
   A local TUI that surfaces board work items, runtime heartbeats, human gates,
   and skill resolution would fit the current architecture if it remains a thin
   read-only or low-authority client.

3. **It should not become the canonical UI.**
   The repo already has a Phoenix/LiveView web direction and a CLI/TUI-capable
   maintainer environment. Making OpenTUI canonical would unnecessarily add a
   second major UI/runtime commitment.

4. **OpenTUI's runtime assumptions are a real cost.**
   The current upstream shape implies Bun + TypeScript + Zig build/runtime
   concerns. That is plausible for an optional tool, but much too opinionated for
   the core platform path right now.

5. **The project wants the architecture, not the brand.**
   What is attractive here is not "use OpenTUI because OpenCode does" but:
   component-based terminal rendering, better operational visibility, and a more
   pleasant local board client. Those benefits can be borrowed without committing
   to OpenTUI specifically.

6. **A TUI must remain subordinate to the board service.**
   It may render state from the board and maybe trigger narrow approved actions,
   but it must not become a shadow orchestration system or a second source of
   task truth.

### Strongest case for adopting it

The strongest affirmative case was:

- it offers a modern terminal UX rather than raw line-oriented output
- it validates that a richer local operator surface is worthwhile
- it could make the board daemon and attempt history more legible over SSH
- it aligns with the repo's continuing interest in CLI/TUI workflows for local
  maintainers

### Strongest reasons to keep it bounded

- the platform's core problems are still semantic and durable, not visual
- Bun/TypeScript/Zig are a stack detour relative to the current Elixir/Nix core
- building a serious TUI duplicates work unless the API/query layer is already
  clean
- there is real scope-creep risk: once a TUI exists, it starts pressuring the
  board into UI-driven mutations instead of API-driven governance

### Concrete recommendation now

1. Treat OpenTUI as a **reference implementation style**, not a required
   dependency.
2. If a TUI is built, keep it **optional** and **non-canonical**.
3. Make the board/API contract clean first; only then decide whether the client
   is LiveView-only, OpenTUI-based, or something else.
4. Prefer a very small proof-of-concept board viewer over a broad UI rewrite.
5. Revisit the choice only if operator demand for a richer terminal surface
   becomes concrete.

### One-sentence verdict

OpenTUI is worth treating as an optional UX reference for a future board client,
but not as the canonical CLI architecture or as a new core runtime commitment.

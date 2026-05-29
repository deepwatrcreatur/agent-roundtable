# `dmux` Vaglio TUI Contract

**Status:** Maintained

## Purpose

Define the narrow operator-facing TUI contract for a local Vaglio workflow built
on top of upstream `dmux`, the local harness RPC boundary, and the existing
board/control-plane model.

This note closes the old "extend `dmux` with a Vaglio round pane" framing by
making the real requirement explicit: an optional wrapper-first terminal surface
that remains subordinate to canonical board and daemon state.

## Maintained line

The project should pursue a `dmux`-adjacent TUI as:

- optional
- wrapper-first
- local-operator oriented
- low-authority by default

It should not:

- fork `dmux` as the first move
- make the TUI the canonical UI
- move board, claim, or lease truth into pane-local state

In short: the TUI is a convenience client over existing contracts, not a new
coordination center.

## Why `dmux`

`dmux` is useful here because it already fits the right operational shape:

- pane and session management
- local terminal ergonomics
- easy composition with CLI tools
- good fit for operator-first rather than browser-first workflows

The maintained repo line is to stay wrapper-first on upstream `dmux` and add
only narrow sidecars or helpers if real use shows hard seam failures.

## Boundary

### What the TUI may own

- rendering a round or work-item cockpit for the local operator
- launching or attaching to a local session
- triggering approved local RPC calls
- presenting summaries, status, and warnings
- surfacing board state and related evidence links

### What the TUI must not own

- canonical board truth
- claim or lease issuance
- durable attempt lineage
- hidden workspace lifecycle policy
- hidden provider/harness substitution

This keeps the TUI as a local surface instead of a shadow orchestration system.

## Required dependencies

The TUI sits above these already-defined layers:

- `docs/design/LOCAL_HARNESS_RPC_CONTRACT.md`
- `docs/design/LOCAL_DAEMON_CONTRACT.md`
- `docs/design/BOARD_EXECUTION_MODEL.md`
- `docs/design/JJ_VIRTUAL_WORKING_COPIES.md`

The TUI depends on those layers being real and queryable; it should not invent
parallel semantics of its own.

## Core user stories

### 1. One-keystroke round launch

An operator should be able to start a bounded local round or task session from a
known workspace with a single `dmux` command or keybinding.

The TUI launches:

- the pane layout
- the selected local harness session
- the related board or evidence view

without requiring the operator to manually rebuild the environment each time.

### 2. Live turn visibility

The operator should be able to observe:

- which harness profile is active
- current progress/output stream
- warnings or degraded harness health
- the current work item or round context

without leaving the terminal.

### 3. Fast evidence access

The TUI should make it easy to jump to:

- board cards
- relevant `/forgejo-shell` demo surfaces
- reports
- local logs or transcript summaries

This aligns the terminal surface with the existing web/public surfaces rather
than competing with them.

## Pane model

The TUI should assume a small wrapper-defined pane model rather than a large
custom runtime.

Suggested minimum panes:

1. **work pane**
   - active harness session or command output
2. **context pane**
   - current work item, round summary, or prompt context
3. **status pane**
   - lease/claim/health warnings, next signals, recent events

This is a layout recommendation, not a canonical rendering mandate.

## Status-line contract

The original item asked for round status in the tmux status line. The maintained
version is narrower and more explicit.

The status line may show compact signals such as:

- current work-item or round label
- harness profile
- health state
- claim/lease warning state
- stress or robustness hint when available

But the status line should be treated as a summary projection, not a source of
truth.

## Command surface

The TUI should prefer a tiny wrapper command family over hard-coded pane logic
spread across shell snippets.

Minimum command classes:

- `open_round`
- `open_work_item`
- `attach_session`
- `show_status`
- `cancel_local_run`

Those commands may map internally to:

- `dmux` session creation
- local harness RPC calls
- board/API reads

The important thing is that the operator sees one consistent local entrypoint.

## Transport and integration rules

The TUI should speak to the local runtime through the local harness RPC layer,
not by embedding provider-specific invocation logic itself.

That means:

- no direct ad hoc `codex`/`gemini`/`claude` process management in the TUI layer
- no TUI-only hidden fallback rules
- no bypass of daemon-side health or lease reporting when those layers exist

If the TUI launches a local session, it should still preserve:

- requested harness identity
- effective execution path
- degraded/fallback visibility

## Optionality rule

The TUI remains optional.

The project already has:

- web surfaces for public/demo and board browsing
- CLI and daemon contracts for local control

So the `dmux` surface should be treated as a maintainer-velocity convenience,
not as a required product/runtime commitment.

## Relationship to OpenTUI and other richer stacks

OpenTUI and similar projects may remain useful reference points for terminal UX,
but they are not required by this contract.

The maintained rule is:

- borrow interaction ideas if useful
- avoid making a new Bun/TypeScript/Zig runtime the core path
- keep the TUI contract independent of any one rendering stack

## Practical verdict

The maintained deliverable for this item is not "fork `dmux` and build a second
platform UI."

It is:

- a wrapper-first `dmux` integration contract
- over the local harness RPC boundary
- with one-keystroke session launch and compact terminal status projection
- while preserving board/control-plane truth outside the TUI itself

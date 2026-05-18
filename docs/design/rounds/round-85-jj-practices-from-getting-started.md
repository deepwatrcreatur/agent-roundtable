# Round 85 — `jj` Getting-Started Practice, Agent Workflows, and What to Adopt Now

**Status:** Closed  
**Tags:** tooling, structural  
**Voices used:** Copilot research, Ellie Huxtable article grounding, local repo
docs and prior `jj` rounds  
**Additional note:** this round directly informed updates to
`docs/JJ_GUIDE.md`

### Round question

The maintainer wanted the article
`https://ellie.wtf/notes/jj-getting-started/` digested and incorporated into
project practice, and preferred a dedicated round on:

- what practical `jj` habits from the article should become local norms
- how those habits interact with existing repo-native `jj` design
- what good practices agents and humans here should adopt immediately

### Relevant prior context

This round built directly on:

- **Round 57** — bookmark naming and legitimacy boundaries
- **Round 58** — git compatibility at the edge, `jj` as the real core model
- **Round 63** — bounded embedded memory and local retrieval near code
- **Round 65** — the real `jj` advantage is narrow and operational, not magical
- **Round 74** — explicit records plus `jj` supersession are part of the natural
  repo-native knowledge base
- the existing `docs/JJ_GUIDE.md`

### External grounding used

The Ellie Huxtable note emphasized several practical points:

- `jj` makes sense for people already living in a frequent amend/force-push style
- `jj new main` is an ergonomic way to start new isolated work
- changes are the primary unit; commit IDs are mutable snapshots
- `jj edit <change-id>` makes returning to and evolving prior work much easier
- `jj undo` is a real safety valve
- bookmarks replace branches, but do not automatically move to new child changes

The article was valued less as a full `jj` manual than as a clear statement of
the day-to-day ergonomics that make `jj` attractive.

### First-pass convergence

The round converged on the following points.

1. **The article's core workflow fits the project well.**
   `jj new main`, small evolving changes, and easy return via `jj edit` all match
   the repo's preference for explicit, resumable, rewrite-friendly work.

2. **The project should embrace the change-centric mental model more explicitly.**
   This means treating change IDs as the durable reference for active work and
   using commit IDs mainly for static snapshots/diffs.

3. **The article's ergonomic advice is necessary but not sufficient for agents.**
   Agents also need path-scoped metadata, supersession marking, conflict
   visibility, and bounded retrieval patterns so the `jj` advantages become
   operationally real instead of just pleasant in theory.

4. **`jj undo` should become part of the documented safety posture.**
   The project already values reversibility and explicit history; `jj undo`
   belongs in the standard recovery toolkit.

5. **Bookmark intentionality matters.**
   The article's warning that bookmarks do not move automatically should be
   treated as a local practice constraint, especially for agents creating follow-up
   child changes.

6. **The project should not overclaim from `jj` ergonomics alone.**
   The article explains why `jj` feels better for rewrite-heavy work, but it does
   not eliminate the need for explicit policy, naming, durable memory, or
   validation discipline.

### Concrete practices to adopt now

- start new isolated work with `jj new main` or another explicit parent
- use `jj describe -m ...` early so active intent is visible
- prefer `change_id` for ongoing task references
- use `jj edit <change-id>` when resuming an earlier line of work
- use `jj undo` as the first recovery move for a mistaken repository operation
- mark **Supersedes:** in change descriptions when replacing an earlier approach
- include **Path:** metadata for bounded local retrieval
- preserve conflict states as deliberate review objects when they reflect real
  design disagreement

### What changed as a result of this round

`docs/JJ_GUIDE.md` was updated to incorporate:

- advanced revset patterns
- explicit mutation/supersession guidance
- path-scoped metadata conventions
- conflict-as-state guidance
- delta extraction for iterative agent work
- bookmark naming reminders
- `jj undo` as a standard recovery practice

### One-sentence verdict

Adopt the article's simple change-centric `jj` habits now, but extend them with
the project's stronger agent-facing rules around supersession, bounded retrieval,
conflict visibility, and disciplined bookmark naming.

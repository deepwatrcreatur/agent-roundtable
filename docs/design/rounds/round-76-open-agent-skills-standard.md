## Round 76 — Open Agent Skills Standard and Project Alignment

**Tags:** tooling, structural, protocol
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Copilot synthesis  
**Additional note:** The requested free `opencode` voices were attempted, but the
configured model IDs were unavailable from the provider during this run and were
therefore excluded from synthesis  
**Claude:** Omitted by maintainer preference for this run

### Round question

The maintainer asked for a follow-up round on the **December 2025 open Agent
Skills standard** and adjacent systems:

- have we already built on this standard in any real sense
- should we
- how should the project relate Agent Skills to **MCP**
- how should it relate Agent Skills to orchestration frameworks such as
  **OpenAI Swarm / Agents SDK** and **Microsoft Agent Framework**

The practical concern was whether the project should:

- adopt the external `SKILL.md` format directly
- merely borrow its ideas
- or keep a narrower internal artifact model

### Relevant prior context

This round built directly on:

- **Round 62** — the split between discussion, execution dispatch, and
  governance / long-horizon memory
- **Round 70** — selective borrowing from orchestration tools without adopting
  heavyweight foreign runtimes wholesale
- **Round 71** — repo-embedded skills are worth adding, but only narrowly:
  explicit, versioned, vendor-neutral, transparently activated, and logged
- work items **73**, **74**, and **75** — board schema, local daemon contract,
  and lightweight workflow definitions

Those prior rounds already established:

- the board owns execution dispatch and attempt lineage
- Vaglio owns longer-horizon memory / governance / lineage
- workflows are already becoming a concrete bounded artifact type
- any future skills system must remain explicit, inspectable, and non-covert

### Local state checked for this round

The repo state at the time of this round showed:

- no `SKILL.md` files in the repo
- no implemented board/orchestrator fields such as `required_skills`,
  `recommended_skills`, `skill_ref`, or equivalent
- existing workflow support via `workflow_ref`, but not yet a concrete skill
  artifact and resolver
- existing project interest in **MCP**, especially for tool/data connectivity

### Grounding facts used in this round

#### Agent Skills

Public Agent Skills docs now describe an open format in which a skill is a
directory containing at minimum a `SKILL.md` file with YAML frontmatter and
Markdown instructions.

The required fields are:

- `name`
- `description`

Optional fields include:

- `license`
- `compatibility`
- `metadata`
- experimental `allowed-tools`

The model uses **progressive disclosure**:

1. load only `name` and `description` at discovery time
2. load full `SKILL.md` on activation
3. load scripts / references / assets only when needed

The public client showcase now includes major agent surfaces such as:

- Claude / Claude Code
- OpenAI Codex
- GitHub Copilot
- VS Code
- Gemini CLI
- OpenCode
- OpenHands
- Goose

#### MCP

Public MCP docs describe **Model Context Protocol** as an open protocol for
connecting AI applications to external data sources, tools, and workflows.

This round treated MCP as:

- a connectivity / tool / data protocol
- **not** a skill artifact format

#### OpenAI Swarm

The current `openai/swarm` README describes Swarm as an **experimental,
educational** framework for lightweight multi-agent coordination via agents,
tools, and handoffs. The same README now says it has been replaced by the
production **OpenAI Agents SDK**.

This round therefore treated Swarm mainly as:

- an orchestration pattern reference
- not a standard for portable skill artifacts

#### Microsoft Agent Framework

The current `microsoft/agent-framework` README describes it as an open,
multi-language framework for production-grade agents and multi-agent workflows
in Python and .NET, with orchestration patterns, checkpointing, HITL,
observability, declarative agents, and an Agent Skills feature.

This round therefore treated Microsoft Agent Framework as:

- a framework/runtime layer
- not merely a file-format spec

### Participation record

What actually happened:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Requested `opencode` voices:** unavailable due to provider model lookup
  failures, excluded

### Voice summaries

#### Codex

- Strongest on the distinction between:
  - conceptual convergence with Agent Skills
  - actual implementation adoption
- Concluded the project has **not** actually adopted Agent Skills yet.
- Recommended adopting `SKILL.md` as an on-disk compatibility target while
  keeping local governance and audit semantics stricter than the base standard.
- Drew a clean line:
  - Agent Skills = reusable instruction/context bundles
  - MCP = tool/data/workflow connectivity
  - orchestration frameworks = runtime structure and execution control

#### Gemini

- Strongest on the affirmative interoperability case.
- Recommended directly adopting `SKILL.md` for repo-local skill artifacts,
  because the file-based format aligns with the project's existing preference for
  explicit, versioned, vendor-neutral artifacts.
- Insisted that board governance must remain authoritative over permissions and
  tool access, regardless of anything a skill file requests.

#### Copilot

- Agreed with the converged answer that the project has only reached a similar
  idea independently so far; it has not implemented real Agent Skills support.
- Treated the best path as:
  adopt the external file format as a compatibility layer while keeping local
  orchestration semantics, logging, and policy enforcement stronger and separate.

### First-pass convergence

The round converged clearly on the following points.

1. **The project has not yet built on Agent Skills in implementation.**
   The project has a very similar concept from Round 71, but it does not yet
   have `SKILL.md` artifacts or board/orchestrator skill resolution support.

2. **The convergence is substantive, not accidental.**
   Round 71's locally developed concept is already very close in spirit to the
   external standard:
   explicit, versioned, transparent, vendor-neutral artifacts with explicit
   activation.

3. **The external Agent Skills format is worth adopting, but narrowly.**
   The round did not support inventing a private near-clone if the public
   `SKILL.md` format already captures the portable on-disk artifact well enough.

4. **The project still needs a stricter local adapter layer.**
   The base standard does not by itself enforce:
   - orchestration-resolved activation
   - attempt-history logging
   - local governance policy
   - stricter provenance / lineage / supersession expectations

5. **MCP is adjacent, not interchangeable.**
   The round strongly rejected treating MCP and Agent Skills as the same thing.

6. **Swarm / Agents SDK and Microsoft Agent Framework are runtime/framework
   references, not the skill spec.**
   The project should not confuse a portable skill artifact with a framework's
   orchestration model.

### What the round recommends adopting directly

The round supported adopting the external Agent Skills format directly at the
artifact layer:

- a repo skill is a directory
- the directory contains `SKILL.md`
- the project parses at least the stable baseline fields:
  - `name`
  - `description`
  - optionally `license`, `compatibility`, `metadata`

This gives the project:

- interoperability across multiple agent surfaces
- a simple filesystem-native artifact
- progressive disclosure compatible with token efficiency goals
- a standard shape that avoids needless reinvention

### What the round says to keep local and stricter

The round was equally clear that several things must remain local and
authoritative:

- board/orchestrator resolution policy
- explicit activation decisions
- attempt/event-log recording of which skills were selected and loaded
- permission/capability control
- provenance / lineage / supersession semantics

The round explicitly rejected using the external skill file as the source of
truth for permissions.

In particular, the standard's experimental `allowed-tools` field should be
treated as:

- advisory at most
- never a capability grant

### Positioning relative to MCP

The round recommends the following division:

- **Agent Skills** package reusable operational knowledge and instructions
- **MCP** connects agents to external tools, data sources, and workflows

Skills may describe how to use an MCP-exposed tool, but that does not make MCP a
skill format or skills a tool-transport protocol.

### Positioning relative to orchestration frameworks

The round recommends the following division:

- **Skills** = reusable instruction/context artifacts
- **Workflows** = execution policy / retry / timeout / HITL / resume structure
- **Frameworks** like Swarm / Agents SDK / Microsoft Agent Framework = runtime
  orchestration layers that may consume or expose skills, but are not identical
  to the skill artifact itself

The project should therefore:

- learn from Swarm / Agents SDK about handoff/orchestration patterns
- learn from Microsoft Agent Framework about production multi-agent workflow
  structure and observability
- avoid inheriting those runtime stacks wholesale just because they also talk
  about skills

### Safest next implementation step

The strongest converged next step was narrow and concrete:

1. Add a first-class local skill artifact/resolver model.
2. Let it ingest repo-local directories containing standard `SKILL.md`.
3. Add explicit board/orchestrator fields such as:
   - `required_skills`
   - `recommended_skills`
   - `resolved_skills`
4. Record skill activation explicitly in attempt/event history.
5. Treat permissions/tool access as board/orchestrator policy, not skill-file
   authority.

### What should be rejected or deferred

The round rejected or deferred:

- hidden auto-activation from local agent config
- using `allowed-tools` as an authority boundary
- marketplace/registry work before basic local skill support exists
- remote skill fetch as an early feature
- plugin/runtime systems hidden behind the language of "skills"
- adopting external orchestration frameworks wholesale merely because they have a
  skill feature

### Closure

The round closes with the following design rules.

#### 1. The project has not adopted Agent Skills yet

It has only reached a strongly similar local concept independently.

#### 2. Adopt `SKILL.md` at the artifact layer

Use the public format instead of inventing a private near-clone.

#### 3. Keep local policy stricter than the base standard

Permissions, activation, logging, and provenance stay under board/orchestrator /
Vaglio authority.

#### 4. Keep skills distinct from MCP and from orchestration frameworks

These are adjacent layers, not replacements for one another.

#### 5. Build the narrow adapter first

Start with repo-local `SKILL.md` parsing plus explicit board references and
activation logging before any broader ecosystem ambitions.


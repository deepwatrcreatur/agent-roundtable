## Round 64 — Generic Execution VM / Agent Tooling Substrate

**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, DeepSeek API, Copilot synthesis  
**Claude:** Omitted by maintainer preference for this run

### Round question

The task board / execution engine needs a VM, or at least a standardized NixOS /
Home Manager environment, with a solid inventory of tools.

Agents often reach for utilities such as:

- Pillow
- OCR tools
- image processing tools
- screenshot-analysis helpers
- debugging helpers

and do not find them available locally.

Many relevant tools already exist in `unified-nix-configuration`, but the
maintainer wants a more generic setup that is not tightly coupled to their
personal workstation profile.

Long term, this execution substrate should run on `pve-strix` and act as dogfood
for the system.

### Relevant local context

This round built directly on:

- Work Item 55 — Local Subscription Harness Verification
- Work Item 57 — Autonomous Agent Task Delegation System
- Work Item 59 — Isolated Testing Sandbox

It also used live repo context from `unified-nix-configuration`, including the
existing mix of:

- NixOS outputs
- Home Manager modules
- `agenix` secret handling
- prototype agent-tooling work

### Voice summaries

#### Codex

- Strongest on the **layered substrate** answer:
  - generic NixOS VM as the reproducible base image
  - small Home Manager agent profile layered on top
- Emphasized reuse of existing agent-stack / fleet work rather than cloning the
  maintainer's workstation.
- Pressed hardest on keeping system responsibilities and user responsibilities
  separate.

#### Gemini

- Strongest on the "both, but with clear primacy" answer:
  - VM image first
  - Home Manager profile second
- Provided the most explicit baseline tool inventory, especially around:
  - OCR
  - screenshots
  - scripting
  - debugging
  - Nix / repo tools
- Sharpened the need for placeholder / swappable secrets rather than
  maintainer-bound configuration.

#### DeepSeek

- Strongest on treating the execution environment as a **generic reusable
  substrate**, not a personal workstation clone.
- Emphasized modular secrets and capability injection so the VM can be reused by
  other operators with different credentials.
- Pressed hardest on direct integration with the task board and harness paths so
  the VM is part of the execution fabric, not just a convenient toolbox image.

#### Copilot

- Agreed with the layered NixOS + Home Manager approach.
- Emphasized that the NixOS VM should be the primary artifact because it is the
  one that maps most cleanly to future `pve-strix` deployment and reproducible
  agent execution.
- Accepted the strongest common boundary:
  the generic execution substrate should expose clean interfaces for:
  - secrets
  - subscription harnesses
  - task-board connectivity
  without inheriting the maintainer's personal workstation shape.

### First-pass convergence

All four voices converged on the following points.

1. **The right answer is layered, not singular.**
   The project should provide both:
   - a generic NixOS VM output
   - a reusable Home Manager profile / module

2. **The NixOS VM should be primary.**
   It is the most reproducible and the best fit for direct deployment on Proxmox
   / `pve-strix`.

3. **The Home Manager layer should remain secondary but real.**
   It supports:
   - reuse on existing systems
   - user-scoped tooling
   - local dogfooding without forcing the whole VM image

4. **The tool inventory must be explicit and discoverable.**
   The environment should stop depending on whether an operator happens to have a
   utility installed already.

5. **Secrets and subscriptions must be swappable.**
   The generic substrate should support placeholders / interfaces, not
   maintainer-bound credentials baked into the module.

6. **The VM should integrate directly with the task board and harnesses.**
   It is not just a nice dev shell. It is the execution substrate for the board.

### Converged tool-inventory direction

The panel converged on a baseline inventory spanning:

- repo / shell tools:
  - `git`
  - `gh`
  - `ripgrep`
  - `fd`
  - `jq`
  - `yq`
  - `tmux`
- Nix tools:
  - `nix`
  - `home-manager`
  - rebuild / diff / inspection helpers
- OCR / image / media tools:
  - `tesseract`
  - `imagemagick`
  - Pillow-capable Python environment
  - PDF / screenshot helpers
- debugging / inspection tools:
  - `strace`
  - `lsof`
  - `tcpdump`
  - related diagnostics
- agent / browser / automation tools where appropriate:
  - headless browser helpers
  - subscription harness CLIs
  - scripting environments

The important consensus was not any one binary. It was that the environment must
publish an explicit baseline rather than rely on incidental operator state.

### Closure

The round closes with the following design rules.

#### 1. Ship a generic `execution-vm` NixOS output

This should be the primary artifact:

- reproducible
- deployable to Proxmox
- suitable for future `pve-strix` use

#### 2. Also ship a reusable Home Manager agent-toolchain profile

This should remain:

- optional
- modular
- usable on top of another system

but it should not replace the VM as the primary execution substrate.

#### 3. Separate interfaces from instance data

The generic environment should define clean options for:

- secrets
- harness configuration
- task-board endpoint
- optional provider credentials

while keeping maintainer-specific encrypted data out of the generic module body.

#### 4. Make tool inventory explicit and inspectable

Operators and agents should be able to answer:

- what tools are guaranteed here?
- which packages belong to which capability group?
- which extras are optional?

without reading through unrelated personal configuration.

#### 5. Integrate the VM as execution substrate beneath the board

The board should dispatch into this environment.
The VM should not be treated as an afterthought or side utility.

### Immediate roadmap implications

The converged near-term sequence was:

1. extract / define a generic agent toolchain module from existing Nix material
2. create a generic `execution-vm` NixOS configuration output
3. add a secrets / harness shim with placeholder defaults and operator-supplied
   replacements

### Consensus summary

The consensus answer is:

- **yes**, build both a generic NixOS VM output and a Home Manager layer
- **primary artifact:** the VM
- **secondary artifact:** the reusable user-level toolchain profile
- **critical guardrails:** explicit tool inventory, swappable secrets, and clean
  task-board / harness integration


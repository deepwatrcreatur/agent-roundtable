## Round 110 — phpIPAM vs Repo-Native Host Inventory

**Tags:** phpipam, ipam, inventory, source-of-truth, hosts, networking  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, OpenCode free-model enrichment, Copilot synthesis  
**Additional note:** this round included an explicit OpenCode free-model
enrichment seat. The first launch attempt failed because the shared prompt file
was created in parallel with the seat jobs; the durable record captures the
successful rerun against the verified prompt.

### Round question

The maintainer wanted a discussion round on whether `phpIPAM` would be a good
fit for organizing IP-address-to-host mappings.

The round was not framed as a generic “is phpIPAM good?” question. It was
grounded in the current local architecture:

- `unified-nix-configuration/lib/hosts.nix` already declares itself the
  authority for operational/network-layer metadata and the single source of
  truth for homelab hosts
- that file already owns or derives:
  - host IP addresses
  - SSH access metadata
  - DNS names and aliases
  - DHCP reservations
  - public ingress routing labels
  - DDNS labels
- `unified-nix-configuration/outputs/checks.nix` already validates large parts
  of that authority boundary, including duplicate-IP detection and inventory
  alignment
- `ansible/inventory/hosts.yml` still overlaps partly with that domain, so the
  system already has some duplication pressure
- and the repo explicitly documents source-of-truth boundaries in files such as
  `docs/router-source-of-truth.md` and `docs/host-metadata-boundary.md`

Public phpIPAM grounding used in the round:

- phpIPAM presents itself as a free/open-source web IPAM tool
- it offers subnet/IP management, VLAN/VRF management, device tracking, custom
  fields, scans/status checks, and REST API access
- it is a mature long-running PHP/MySQL-style web application with its own
  mutable database and operational surface

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive
- **Claude CLI:** substantive
- **DeepSeek API:** substantive via direct HTTP API with local credential
- **OpenCode free-model enrichment:** substantive
- **Copilot:** substantive

### Voice summaries

#### Codex CLI

- Strongest on the distinction between:
  - **authority**
  - and **operator convenience**
- Treated phpIPAM as potentially useful for:
  - subnet-centric browsing
  - utilization visibility
  - scan/status views
  - and multi-user interactive IPAM workflows
- But argued that in the present setup it would cut across an already explicit
  source-of-truth boundary and mostly create drift risk.
- Recommended:
  - do not adopt phpIPAM as authority
  - improve repo-native browsing and generation instead

#### Gemini CLI

- Most willing to name a small real gap:
  - visual subnet maps
  - quick UI queries
  - and easier browsing for non-technical users
- Even so, concluded that the current repo already *is* the IPAM in practice.
- Treated phpIPAM as a poor fit because it introduces:
  - another mutable system
  - extra operational surface
  - and sync burden for limited gain

#### Claude CLI

- Most explicit that phpIPAM would mainly create a **second authority that can
  drift**.
- Argued that for this single-maintainer homelab, phpIPAM’s main team-oriented
  features are largely the wrong fit:
  - RBAC
  - workflows
  - web editing
  - subnet delegation
- Recommended:
  - do not adopt phpIPAM
  - if a nicer view is wanted, generate lightweight inventory views directly
    from `lib/hosts.nix`

#### DeepSeek API

- Most direct that phpIPAM solves **no missing authority problem** in the
  current setup.
- Emphasized that:
  - the repo already has a working integrated source-of-truth flow
  - phpIPAM would add operational overhead
  - and the likely result is drift between the web app and the repo
- Recommended:
  - do not adopt phpIPAM at all in the current context

#### OpenCode free-model enrichment

- Mostly reinforced the same conclusion.
- Recognized that phpIPAM offers a friendlier UI and browsing surface, but still
  concluded that for a single maintainer the cost and drift risk outweigh the
  benefit.
- The seat’s written satisfaction marker said `Not satisfied`, but the actual
  content still converged on the same recommendation as the rest of the panel:
  do not adopt phpIPAM in the current homelab workflow.

#### Copilot

- I agreed with the panel’s main boundary:
  - `lib/hosts.nix` is already the authoritative inventory surface
  - phpIPAM is not filling a missing authority role here
  - its strongest possible value would be only as a browsing/query UI
- My strongest synthesis point was that the better next move is not a database
  IPAM but lighter repo-native views and generation that preserve the current
  authority model.

### First-pass convergence

The panel converged on the following points.

1. **phpIPAM should not become the new source of truth.**
   No substantive voice supported replacing the repo-native authority model with
   phpIPAM.

2. **The current repo already behaves like an IPAM.**
   `lib/hosts.nix` plus downstream generation and checks already covers the core
   IP-to-host mapping problem in a declarative, reviewable way.

3. **The strongest phpIPAM value here would only be browsing convenience.**
   The real advantages identified were:
   - visual subnet browsing
   - ad-hoc querying
   - scan/status views
   - and potential multi-user workflows

4. **For this maintainer’s current setup, those advantages do not outweigh drift
   and operational cost.**
   The recurring risks were:
   - second mutable authority
   - sync complexity
   - narrower data model than `lib/hosts.nix`
   - and extra application/database maintenance

5. **If the real pain is readability, the better answer is repo-native views.**
   The repeated alternative was to generate:
   - HTML/JSON/CSV views
   - subnet utilization reports
   - search/query helpers
   - or tighter Ansible inventory generation/validation
   from the existing repo authority.

### Real disagreements that remained

There was only a narrow disagreement about whether phpIPAM might still be worth
trying as a non-authoritative convenience layer.

- Codex allowed that a **read-only mirror fed from the repo** could be
  defensible later if there were a concrete browsing/UI need
- Gemini also left room for UI-oriented value
- Claude and DeepSeek were more conservative and preferred not adopting it at
  all in the current context

No substantive voice recommended a read/write adjunct or a new database-backed
authority.

### Final synthesis

The strongest conclusion is:

1. Keep `lib/hosts.nix` as the single authority for IP/host operational
   metadata.
2. Do **not** adopt phpIPAM as:
   - the new source of truth
   - or a read/write sync peer
3. If inventory usability becomes painful, improve the current model by adding:
   - repo-native reports
   - generated views
   - search/query tools
   - and tighter elimination of the remaining duplicated inventory surfaces
4. Only if there is a later concrete need for a browsable web view should the
   project even consider phpIPAM, and then only as a possible **read-only mirror
   generated from repo data**, not as an editing authority

The practical recommendation now is therefore simple:

- **do not adopt phpIPAM**
- strengthen the repo-native inventory UX instead

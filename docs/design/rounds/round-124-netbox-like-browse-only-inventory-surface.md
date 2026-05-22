## Round 124 — NetBox-Like Browse-Only Inventory Surface

**Tags:** inventory, netbox, browse-surface, source-of-truth, control-plane, ui  
**Status:** Closed  
**Voices used:** Codex CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** Gemini CLI was launched for this round but returned only
keychain fallback / credential-loader noise rather than usable seat text, so it
is not counted as a substantive voice.

### Round question

The maintainer wanted a roundtable discussion on how to add inventory browsing
similar in spirit to NetBox while remaining committed to:

- declarative repo config as the sole authority
- browse-only presentation for the inventory surface
- and a willingness to borrow NetBox's design and layout patterns without trying
  to copy its mutable database-backed model

The sharper design questions were:

- whether inventory browsing should live inside the same main Vaglio / board
  surface or as a separate companion app
- which object hierarchy should come first when the underlying authority is
  Nix-derived host metadata rather than a CMDB
- which NetBox patterns are genuinely worth borrowing
- and what the best first slice is if the goal is obvious browsing value soon,
  not a reimplementation of NetBox

### Grounding used in this round

Local project grounding carried into the round:

- **Round 110** concluded that `lib/hosts.nix` and surrounding checks already
  form the authority boundary for inventory / IPAM concerns, and that the right
  next move is repo-native browse/query/reporting rather than a mutable external
  authority such as phpIPAM
- **Work item 96** established the pattern of a derived kanban read model that
  turns canonical execution state into a stable human-facing browse surface
- **Work item 97** established that the first browseable surface should be
  read-first, filterable, drill-down friendly, and explicit about what is
  canonical versus derived convenience
- `BOARD_EXECUTION_MODEL.md` and `LOCAL_DAEMON_CONTRACT.md` both reinforce the
  architectural habit of preserving narrow canonical state while projecting more
  legible read models for operators

Public NetBox grounding used in the round:

- NetBox is a browseable source-of-truth UI with strong list/detail navigation,
  cross-linking, badges, filters, breadcrumbs, and contextual summary panels
- the docs explicitly show rich device pages collecting role, device type, site,
  location, rack, platform, primary addresses, OOB IP, cluster membership, and
  context
- the docs also show prefix pages collecting CIDR, status, VRF, role, scope,
  VLAN, and utilization-relevant information
- but NetBox remains a mutable database-backed authority, which this project
  explicitly does **not** want to become

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Claude CLI:** substantive
- **Gemini CLI:** launched, but produced only keychain fallback / credential
  messages and no usable seat text
- **DeepSeek API:** substantive
- **Copilot:** substantive

This round therefore had a **degraded but substantive roster**.

### Voice summaries

#### Codex CLI

- Strongest on the product split:
  inventory should live inside the same main control-plane surface, but as a
  sibling `Inventory` section rather than mixed into kanban lanes
- Most explicit that the UI should copy the **read-model** pattern already used
  by the board:
  canonical repo config -> derived indexes -> browse UI
- Favored a host-first object model rooted in repo-native metadata rather than
  NetBox's fuller enterprise ontology
- Recommended highly visible provenance:
  `Derived from repo config`, `Read-only`, `Last generated at`, and source-file
  links on every inventory page

#### Claude CLI

- Most explicit that the inventory surface should feel like `git log`, not like
  a CMDB:
  you browse declared state and edit by committing config
- Strongest on the host-detail page as the primary page:
  hostname, role, platform, deployment target, interfaces, addresses, services,
  tags, and source-file location
- Emphasized that site / rack / location hierarchy should only appear if the
  repo genuinely declares it, and that small homelab scale should remain the
  reference case
- Added the strongest control-plane link:
  host detail and board work items should cross-link when the same host is in
  scope

#### DeepSeek API

- Most willing to borrow the **visible shape** of NetBox directly:
  inventory as a co-located top-level section with list pages, filter sidebars,
  utilization bars, tag pills, and recent-change views
- Most explicit about concrete v1 object buckets:
  devices, prefixes, IPs, tags, and recent inventory changes
- Strongest on using a single generated `inventory.json` or equivalent artifact
  as the browse surface input
- Also surfaced the main operational risk:
  allowing any UI-driven overrides would immediately collapse the authority
  boundary

#### Copilot

- I agreed with the panel's main architectural line:
  inventory should be a browse-only derived read model inside the same main
  surface, not a separate mutable tool
- My strongest synthesis point was that NetBox should be copied mostly for
  **information architecture**:
  list/detail rhythm, cross-links, filters, badges, breadcrumbs, and contextual
  panels
- I also agreed with the strongest constraint from Round 110:
  the project should not let the desire for browseability pressure it into
  inventing enterprise metadata or a second authority

### First-pass convergence

The substantive voices converged on the following points.

1. **Inventory browsing should live inside the same main Vaglio / board surface,
   but as a separate section.**
   No substantive voice wanted a wholly separate inventory product.
   The maintained line is:
   shared shell, shared auth, shared derivation pipeline, but distinct
   navigation and mental model from execution kanban.

2. **The inventory UI should be a derived read model over declarative repo
   state.**
   The recurring architecture was:

   - canonical repo config
   - inventory extractor / derivation step
   - stable intermediate/indexes
   - browse UI

   No voice supported mutable inventory forms or a DB-first authority.

3. **The first object model should stay repo-native and host-centric.**
   The strongest shared recommendation was:

   - start with `hosts` as the anchor object
   - make `prefixes/subnets` the second major object type
   - add `services`, `tags`, `sites`, or `locations` only as declared metadata
     warrants

   The round consistently rejected importing a large NetBox ontology merely to
   look more "complete."

4. **The most valuable NetBox patterns here are layout and browse mechanics, not
   its mutable operating model.**
   The repeated design features worth copying were:

   - list/detail navigation
   - dense summary cards or tables
   - badges and pill-style metadata
   - faceted filters
   - breadcrumbs and hierarchy where real
   - strong cross-links between related objects
   - prefix utilization views
   - and global search across object classes

5. **The UI must make its derived, read-only nature impossible to miss.**
   The recurring mechanisms were:

   - visible `Read-only` / `Derived from repo` banners
   - commit hash or evaluation timestamp
   - source-file links
   - and no create/edit/delete affordances for inventory state

6. **The best first slice is small and obvious: hosts plus prefixes.**
   The shared v1 shape was:

   - a host list page
   - a host detail page
   - a prefix list or prefix detail surface if prefix data is already available
   - basic filters for role, site, tag, platform, and subnet membership
   - and optional recent-change visibility sourced from git history

### Real disagreements that remained

There was only a narrow disagreement about **how much NetBox hierarchy to show
in v1**.

- **DeepSeek** was most open to a visible `Sites -> Locations -> Racks ->
  Devices` style hierarchy if the data can be derived cleanly
- **Codex** and **Claude** were more conservative and wanted the browse surface
  rooted in what the repo already declares, even if that means a flatter
  homelab-shaped structure

This was not a disagreement about authority, only about presentation ambition.
All substantive voices agreed that hierarchy must follow declared metadata
rather than forcing the repo into an enterprise schema.

### Final synthesis

The strongest answer from this round is:

- build inventory browsing as a **read-only derived section inside the same main
  Vaglio / board surface**
- copy NetBox mainly for its **information architecture** and visual browsing
  conventions, not for its mutable CMDB/IPAM operating model
- keep the authority boundary absolute:
  the repo remains canonical, and every inventory page should show provenance
  back to repo declarations
- make `hosts` the anchor object, `prefixes` the second object type, and grow
  outward only when the declarative metadata genuinely supports more structure
- and ship a small, useful first slice rather than trying to reach NetBox
  breadth

The maintained line is therefore:

1. **Do not build a second source of truth.**
2. **Do build a richer repo-native browse surface.**
3. **Let NetBox influence navigation, filtering, and detail-page composition.**
4. **Do not let NetBox pressure the project into fake metadata, CRUD, or CMDB
   sprawl.**

### Concrete first slice from the round

The most defensible first implementation slice is:

- add a top-level `Inventory` section inside the existing main surface
- generate a documented intermediate read model from inventory-relevant repo
  declarations
- ship:
  - `Hosts` list
  - `Host detail`
  - `Prefixes` list/detail if prefix data is already readily derivable
- include filters for:
  - role
  - site
  - tag
  - platform
  - subnet membership
- show on each page:
  - provenance banner
  - source-file link
  - evaluation / commit timestamp
  - related board work items when applicable

That gives immediate NetBox-like browse value without compromising the
declarative source-of-truth boundary.

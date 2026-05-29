# Hybrid Cloud Deployment Model

**Status:** Maintained

## Purpose

Define the current deployment line for hosted surfaces, local operator tooling,
and remote execution substrates without collapsing the product into a
browser-first hosted IDE or a single cloud vendor.

## Maintained line

The system should use a narrow hosted control plane above multiple execution and
storage substrates.

That means:

- local CLI and TUI workflows remain first-class clients
- hosted web surfaces are useful public and operator-facing clients
- remote execution substrates are allowed and often useful
- no single hosted IDE or cloud platform becomes the architecture

The hosted layer should first absorb active coordination state, not all durable
project truth.

## Architectural split

### Hosted control plane

The hosted control plane is the shared coordination layer for:

- claims
- leases and heartbeats
- attempt lineage and supersession
- promotion and gate state
- substrate adapter metadata
- minimal operator inspection surfaces

It may be self-hosted, homelab-hosted, or placed on a managed platform, but its
job is narrow coordination rather than becoming the full development product.

### Durable project truth

Durable project truth should remain portable across hosts and providers:

- repo-local canonical markdown artifacts
- board repo state
- derived indexes and reports
- forge-linked history and evidence artifacts

Hosted products may cache, mirror, or project this data, but they should not be
its only authoritative home.

### Execution substrates

Execution should remain plural behind a common contract. Valid substrate classes
include:

- local workspaces on operator machines
- homelab containers or VMs
- isolated remote sandboxes
- managed cloud VMs
- future higher-level executor backends

The important boundary is that substrate-specific semantics stay beneath the
control-plane and workspace contracts.

## Hosted surfaces are clients, not the center

Public or collaborative web surfaces are still useful:

- public demo routes such as `/forgejo-shell`
- public or operator board surfaces such as `/board`
- report and evidence pages
- optional narrow control dashboards

But these surfaces should be understood as clients over the same backend
objects, not as the sole product shape.

## What changed from the earlier Railway framing

The old item described "deploy the web UI to Railway while keeping the engine in
the homelab." That framing is now too narrow and too vendor-shaped.

The maintained replacement is:

- allow hosted public surfaces where they help
- keep execution and durable state portable
- treat Railway, Fly, Replit, Codespaces, exe.dev, or similar systems as
  optional substrates or packaging choices
- avoid making any one hosted platform the hidden architecture

## Deployment guidance

### Good hybrid-cloud uses

- expose a public read-mostly or operator-facing web surface from a managed
  platform
- run risky or bursty execution on remote isolated sandboxes
- keep sensitive or low-latency execution local when that is the better fit
- replicate or export governance state so a provider outage is not a loss of
  truth

### Anti-patterns

- treating a browser IDE as the primary architectural truth
- making hosted vendor APIs the only home for claims, leases, or decision
  history
- coupling workspace semantics to one provider's remote-dev model
- assuming cloud placement alone solves governance, collision, or authority

## Relationship to nearby design notes

This note depends on and narrows:

- `docs/design/GOVERNANCE_OBJECT_MODEL.md`
- `docs/design/BACKEND_ADAPTER_CONTRACT.md`
- `docs/design/CONTROLLED_EXECUTOR_CONTRACT.md`
- `docs/design/JJ_VIRTUAL_WORKING_COPIES.md`

It is also the maintained synthesis of the hosting/product rounds:

- Round 130: hosted control plane above multiple substrates
- Round 137: hosted web surfaces are not the architecture
- Round 138: native editor or operator clients can sit over the hosted backend

## Practical verdict

The project should not pursue "Railway deployment" as a standalone architectural
goal.

It should pursue a hybrid model in which:

- a narrow hosted control plane can coordinate multiple substrates
- local and hosted clients both remain valid
- public web deployment is a packaging choice, not the definition of the system

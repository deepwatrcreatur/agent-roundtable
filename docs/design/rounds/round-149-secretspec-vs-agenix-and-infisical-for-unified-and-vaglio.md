## Round 149 — SecretSpec vs. Agenix and Infisical for Unified and Vaglio

**Tags:** secrets, credentials, agenix, infisical, vaglio, unified-nix-configuration  
**Status:** Closed  
**Voices used:** GPT-4.1, GPT-5.4 mini, Claude Sonnet 4.6, Copilot synthesis

### Round question

The maintainer wanted a round on whether [SecretSpec](https://secretspec.dev)
would improve either:

- `unified-nix-configuration`
- the `vaglio` appliance / Roundtable host path

The question included an important local caveat:

- `vaglio` already includes API keys encrypted via `age`
- the local environment has already considered hosting **Infisical** as a future
  credential broker
- if SecretSpec required supporting services, those could in principle be stood
  up just as Infisical could be

So the real question was not merely “is SecretSpec neat?” but:

**Does SecretSpec improve the architecture that already exists here, and if so at
which layer: host authority, broker authority, or app/runtime consumption?**

### Grounding used in this round

Relevant local grounding used:

- `unified-nix-configuration/main/secrets.nix`
- `unified-nix-configuration/main/modules/common/secrets-management.nix`
- `unified-nix-configuration/main/modules/home-manager/agenix-user-secrets.nix`
- `unified-nix-configuration/main/docs/agenix-first-secrets.md`
- `unified-nix-configuration/main/den/aspects/homeserver-roundtable.nix`
- `unified-nix-configuration/main/users/deepwatrcreatur/hosts/workstation/default.nix`
- `homeserver/docs/work-items/02-infisical-credential-broker-foundation.md`
- `unified-nix-configuration` work items around restoring `vaglio` and the
  Roundtable host path

Fresh external grounding used from SecretSpec docs:

- `secretspec.toml` is a **committed declarative secret contract**
- SecretSpec separates declaration from storage backend
- it supports profiles, provider fallback chains, generation, and optional
  **reason-for-access** policy
- it primarily injects secrets at **runtime** via environment variables or
  temporary file paths
- it integrates naturally with `devenv`
- it does **not** require a central service by itself; centralization only
  appears if the chosen backend is something like Vault/OpenBao, AWS, GCP,
  1Password, etc.

This distinction mattered because it sharply separates SecretSpec from the
already-discussed **Infisical** direction:

- **Infisical** is a broker / vault / authority candidate
- **SecretSpec** is a declaration-and-consumption contract

### Participation record

What actually happened in this run:

- **GPT-4.1:** substantive
- **GPT-5.4 mini:** substantive
- **Claude Sonnet 4.6:** substantive
- **Copilot:** substantive synthesis

This round therefore closes with a **three-seat substantive roster** plus direct
local and external grounding.

### Voice summary

#### GPT-4.1

- Strongest on the boundary that SecretSpec is **not** a replacement for
  `agenix` / `age`.
- Treated its best role as a **narrow developer/devshell or app-local runtime
  contract**, not as host-level secret authority.
- Strongest on the claim that SecretSpec is useful where runtime injection and
  backend flexibility matter, but wrong for NixOS boot-time or host authority.

#### GPT-5.4 mini

- Strongest on the framing:
  **useful overlay, not replacement**.
- Most direct on the idea that SecretSpec could unify how secrets are
  **consumed** by applications and tooling without replacing how they are
  encrypted and distributed.
- Strongest on the clean three-layer split:
  - `agenix` = encrypted-at-rest transport / delivery in this repo today
  - Infisical = possible future broker / authority
  - SecretSpec = optional interface / contract layer above those

#### Claude Sonnet 4.6

- Sharpest negative view.
- Strongest on the claim that SecretSpec should **not be adopted now** because
  it would introduce a third delivery mechanism before the current
  SOPS→agenix migration and before any Infisical broker is actually live.
- Strongest on the operational point that SecretSpec is a **consumer, not a
  store**, so without a real backend it becomes mostly another layer above the
  same local file-based reality.
- Most direct on the sequence:
  **finish agenix stabilization first; decide broker authority first; only then
  revisit app/dev-runtime contract layers.**

### What the current local architecture already is

Before judging SecretSpec, the round had to restate what is already true.

#### 1. `unified-nix-configuration` is already agenix-first

The current secret architecture is not theoretical; it is real and already
load-bearing:

- repo-committed `.age` blobs live under `secrets-agenix/`
- `secrets.nix` acts as the explicit recipient map
- host and service secrets are wired through `age.secrets`
- user secrets are decrypted by `agenix-user-secrets` into
  `~/.local/share/agenix-user-secrets/`
- the local design doc explicitly says the target state is
  **agenix-first**, with SOPS only as a migration layer

This means the project already has:

- encrypted-at-rest storage
- explicit recipient discipline
- boot-time / activation-time delivery
- repo-diffable authority

#### 2. `vaglio` is currently a Nix-managed host path, not a mature standalone app

This matters a lot.

The local `vaglio-test-sandbox` repo is effectively empty, while the real live
`vaglio` path is represented as a host in `unified-nix-configuration`.

The Roundtable / Vaglio secret reality therefore looks like:

- `vaglio` receives secrets through the same `agenix` / `age.secrets` model
- `homeserver-roundtable.nix` wires concrete `age.secrets."...".path` values
  into service options
- `roundtable-secret-key-base` and LLM API keys are already delivered through
  file paths, not through an app-local runtime-secret broker

So today the “Vaglio appliance” question is really a question about a
**Nix-managed appliance host**, not a generic web app expecting `.env`-style
runtime injection.

#### 3. There is already a local planned broker direction: Infisical

The local homeserver work item on credential broker foundations already says:

- the environment is considering **Infisical** as the preferred credential
  broker / authority
- the main unresolved question is how it would coexist with existing secret
  patterns without creating ambiguous ownership

That is important because it means SecretSpec is not being evaluated in a
vacuum.
It must be compared not only to current `agenix`, but also to a possible future
**broker layer**.

### Strongest case for SecretSpec

The strongest pro case is not that SecretSpec should replace the current stack.
It is:

**SecretSpec could provide a cleaner, machine-readable runtime-secret contract
for developer tooling and app-local consumption than the current scatter of
wrapper conventions and path expectations.**

Concretely, today there are already places where applications and wrappers
depend on conventions like:

- `/run/agenix/...`
- `~/.local/share/agenix-user-secrets/...`
- fallback path logic in wrappers and Home Manager modules

That means the current system is strong on storage and delivery, but weaker on a
single declarative answer to:

- which secrets this project needs
- which are required in which environment
- which are optional
- which profile applies
- why the access is happening

SecretSpec is genuinely good at those questions.

Its strongest real benefits here would be:

1. **Committed app/runtime contract**
   A checked-in `secretspec.toml` can make secret requirements explicit in a
   way that shell wrappers and README fragments currently do not.

2. **Cleaner devshell / devenv ergonomics**
   SecretSpec integrates naturally with `devenv` and runtime injection, which is
   a better fit for per-project development shells than rethinking host-level
   Nix secret authority.

3. **Provider abstraction above local or future backends**
   If a project later wants to read from Infisical, 1Password, keyring, Vault,
   or env-backed CI injection without changing the app contract, SecretSpec is
   built for exactly that.

4. **Reason-for-access policy**
   This is a meaningful feature in an agent-heavy environment.
   The ability to require a reason for secret access from agents is a real
   governance improvement that the current local file-path model does not expose
   as a first-class project contract.

### Strongest case against SecretSpec

The strongest anti case is:

**SecretSpec would add a third secret-handling layer before the current local
architecture has finished stabilizing, and it does not solve the most important
current problem.**

More concretely:

1. **It is not a storage or authority layer**
   SecretSpec does not replace `.age` blobs, recipient maps, or machine/user key
   distribution.
   It is a consumer contract, not the encrypted-at-rest authority.

2. **It does not improve NixOS host/service injection**
   The existing pattern:
   `config.age.secrets."foo".path`
   flowing directly into service options is already exactly what host-level Nix
   configuration wants.
   SecretSpec adds indirection here without solving a real defect.

3. **The current migration is still in progress**
   The repo still carries migration logic around the older SOPS layer.
   Introducing SecretSpec before the agenix-first path is fully settled would
   create avoidable architecture confusion.

4. **`vaglio` is not yet the kind of app SecretSpec best serves**
   Vaglio today is a Nix-managed appliance / Roundtable host, not a mature
   standalone application repo with its own runtime secret contract.

5. **Without a real broker/backend, SecretSpec risks becoming a nicer env-file
   story layered over the same local file reality**
   That may be acceptable in some app repos, but it is not enough to justify
   becoming part of the core infrastructure boundary here.

### Direct comparison

#### SecretSpec vs. current agenix / age usage

The strongest maintained comparison is:

- `agenix` / `age` is the right fit for:
  - repo-committed encrypted blobs
  - explicit recipient discipline
  - boot-time service files
  - host and user identity-based decryption
  - file-path delivery into NixOS and Home Manager

- SecretSpec is the right fit for:
  - per-project runtime secret declaration
  - runtime env / temp-file injection
  - per-profile requirements and defaults
  - provider abstraction
  - app/dev-runtime secret consumption

These are different jobs.

The round therefore rejects the idea that SecretSpec should replace agenix.

#### SecretSpec vs. Infisical

This was the most important structural split in the round.

- **Infisical** is a candidate **credential broker / authority**
- **SecretSpec** is a candidate **project/runtime contract**

If Infisical is adopted later, the plausible relationship is:

- Infisical owns dynamic credential authority and brokering
- SecretSpec, if used at all, sits **above** it for app-local consumption
- `agenix` remains useful for repo-native static secrets and appliance/host
  delivery where that pattern is still the right fit

The round strongly rejects conflating these layers.

### Recommended boundary

The strongest maintained answer from this round is:

#### 1. Do not adopt SecretSpec as a replacement for agenix in `unified`

`unified-nix-configuration` should keep:

- `.age` blobs as repo-native encrypted artifacts
- `secrets.nix` as the explicit recipient map
- `age.secrets` for service file injection
- `agenix-user-secrets` for user/home activation delivery

That architecture is already real and appropriate.

#### 2. Do not adopt SecretSpec as the primary secret authority for the Vaglio appliance

The current Vaglio / Roundtable host path already has the correct shape for a
Nix-managed appliance:

- service secrets are delivered by `agenix`
- services consume concrete file paths
- host configuration remains declarative and repo-native

That should remain true.

#### 3. If SecretSpec is used later, keep it narrowly above the authority layer

The only persuasive future role identified in this round is:

- **developer/devshell runtime secret contracts**
- **app-local consumption contracts**
- possibly **devenv**-integrated tooling slices

Examples of the kind of future slice that might justify it:

- a project-local agent/dev shell that wants explicit machine-readable
  declarations of required LLM/API credentials
- a standalone app repo that wants backend-agnostic runtime injection across
  local machines, CI, and a future broker

#### 4. Sequence matters: broker decision first, SecretSpec later if still useful

The strongest Sonnet contribution sharpened this:

- finish stabilizing the agenix-first path
- decide whether Infisical or another broker actually becomes real
- only then revisit whether a SecretSpec contract layer adds real value in some
  bounded app/dev-runtime slice

### Durable conclusions this project should preserve

1. **SecretSpec is not a new secret authority for this project.**
   It is, at best, a contract/interface layer above an authority.

2. **The current agenix-first architecture for `unified-nix-configuration`
   remains correct.**
   SecretSpec should not replace repo-native encrypted blobs, recipient maps, or
   `age.secrets`-based service delivery.

3. **The Vaglio appliance does not currently present the kind of independent
   app-secret surface that justifies SecretSpec adoption.**
   Its real current secret boundary is the host/appliance boundary already
   managed in `unified`.

4. **If Infisical is adopted later, SecretSpec may become worth revisiting as a
   narrow app/dev-runtime contract layer above it.**
   Not before.

5. **Do not add a third competing secret path during the still-live
   SOPS→agenix stabilization period.**
   The current high-value work is finishing and simplifying the existing secret
   boundary, not introducing a new abstraction.

6. **The best currently visible future role for SecretSpec is bounded and
   optional:**
   project-local developer/runtime secret contracts, especially in `devenv`
   slices where reason-for-access policy and provider abstraction become
   genuinely useful.

### Recommendation now

The maintained recommendation is:

**Do not adopt SecretSpec for `unified-nix-configuration` or the Vaglio
appliance now.**

Keep the current agenix-first architecture for host and user secrets.

Continue treating Infisical, if pursued, as the candidate broker/authority
discussion.

Only revisit SecretSpec later if there is a concrete project-local developer or
runtime secret-consumption problem that survives after the broker and agenix
boundaries are settled.

**One-sentence verdict for the round:** SecretSpec is an interesting declarative
runtime-secret contract layer, but it should not be adopted now for
`unified-nix-configuration` or the Vaglio appliance because the current
agenix-first host/appliance boundary is already the correct authority layer, the
broker question still belongs to Infisical-class tools, and SecretSpec only
becomes plausible later as a narrowly bounded app/dev-runtime interface above a
settled backend rather than as a new primary secret system.

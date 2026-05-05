# 65 — The Librarian & Merit Manifest

**Status:** `ready`
**Tag:** `[tools]`

## Goal
Prevent "DIY reinventing" and token waste by ensuring agents use high-quality existing tools and libraries.

## Scope
- Define the **Merit Manifest** (`MERIT.json`): a machine-readable registry of Vouched libraries, CLI tools, and frameworks for the project.
- Implement the **Librarian Agent**: a Jido-based orchestrator role that runs during the "Initial Triage" of any round.
- **Workflow**:
    1. Librarian scans the BRIEF and `#tags`.
    2. Librarian cross-references with the Merit Manifest and the global `ATTRIBUTION.md`.
    3. Librarian injects a "Mandatory Tooling" block into the prompts for subsequent agents.
- **Bailiff Integration**: The "Reinvention Bailiff" blocks any PR that implements logic already provided by a Vouched tool in the manifest.

## Acceptance Criteria
- 0% DIY implementation of core primitives when a Vouched library is available.
- Significant reduction in token usage per round by shifting from "Generate" to "Compose."
- Higher architectural integrity by building on "Best-of-Breed" foundations.

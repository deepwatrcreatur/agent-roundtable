# 63 — Binary Blob & Build Script Bailiff (The "XZ Shield")

**Status:** `ready`
**Tag:** `[integrity]`

## Goal
Implement an automated guardrail that flags the specific vectors used in the XZ attack (binary blobs and build script obfuscation).

## Scope
- Implement a Jido-based "Risk Oracle" that scans incoming `jj` commits.
- **High Risk Triggers**: 
    - Introduction/Modification of binary files (test artifacts).
    - Changes to build-system files (m4, autoconf, cmake).
    - New contributors with low "Transitive Trust" scores in the SNA graph.
- **Protocol Action**: Automatically escalate these commits to a "Mandatory Adversarial Round" (Item 43).

## Acceptance Criteria
- Commits matching these patterns cannot be "Vouched" without a documented Disconfirmation Pass.
- The UI highlights these "Social-Technical Mismatches" as high-stress hotspots.

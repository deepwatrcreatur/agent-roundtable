# Round 84 — DSPy, Research Operations, and Structuring Deliberative Knowledge

**Status:** Closed  
**Voices used:** Copilot research, DSPy primary docs, local repo grounding  
**Additional note:** this round focused on DSPy's architectural patterns rather
than treating it as an immediate dependency candidate

### Round question

The maintainer wanted a round on **DSPy / DSPy OSS** as a system for agents
contributing to research, and specifically:

- whether DSPy should be incorporated into the local research/deliberation stack
- which parts, if any, should influence how the project organizes the knowledge
  produced from rounds of discussion
- whether the right move is direct adoption, selective borrowing, or rejection

### Relevant prior context

This round built directly on:

- **Round 62** — discussion, execution board, and governance memory should remain
  separated
- **Round 63** — embedded design memory needs bounded retrieval and explicit local
  context
- **Round 71** — repo-embedded skills should be explicit, versioned, and
  activation-logged
- **Round 73** — a graph/index layer should remain derived rather than canonical
- **Round 74** — the real knowledge base is the explicit repo-native record set
- **Round 75** — durable execution requires explicit validation and persisted
  workflow state
- **Round 76** — adopt portable artifacts where useful, but keep local policy and
  activation semantics stricter

### External grounding used

DSPy publicly presents itself as:

- **Declarative Self-improving Python**
- a framework for programming LMs through structured modules/signatures rather
  than hand-written prompt strings
- a system for composing modules, retrieval, and agent loops
- a framework that can optimize prompts/weights from examples and metrics

The important distinction for this round was between:

- DSPy as a **codebase/runtime**
- DSPy as a set of **good abstractions** for structuring research operations

### First-pass convergence

The round converged on the following points.

1. **The project should not adopt DSPy as a core dependency.**
   The Python stack mismatch is real, and the project's core execution model is
   already converging around Elixir/BEAM plus repo-native records and board
   semantics.

2. **DSPy's strongest contribution is conceptual, not infrastructural.**
   The most useful piece is its insistence on explicit signatures/modules instead
   of vague prompt piles. That aligns strongly with local work on skills,
   workflows, and bounded knowledge artifacts.

3. **Automatic prompt optimization is mostly the wrong fit here.**
   The project is trying to make agent behavior more inspectable and governable.
   DSPy's optimizer story moves in the opposite direction if adopted naively:
   more hidden tuned behavior, less legible deliberative provenance.

4. **The right borrowing target is a repo-native research-operation layer.**
   The project should define explicit research operations with:
   - inputs
   - outputs
   - validation rules
   - provenance
   - supersession
   - linked rounds/decisions

5. **Validation examples should remain validation, not covert training.**
   The repo absolutely should collect good examples and failing examples for
   operations, but in a governance/audit role rather than as a hidden optimization
   substrate.

6. **This extends Rounds 71 and 76 more than it replaces them.**
   DSPy-like signatures are best understood here as one possible next layer above
   `SKILL.md`: explicit operation schemas for research, synthesis, evidence
   evaluation, and knowledge maintenance tasks.

### What is worth borrowing

- explicit signatures for bounded operations
- modular composition of research steps
- structured output validation
- separation between the operation contract and the model/provider used to fulfill
  it
- disciplined evaluation examples for regression detection

### What should be rejected

- Python/runtime adoption as a core architectural dependency
- opaque prompt optimization as the primary way of improving research quality
- hidden learned behavior that outruns the repo's explicit governance/memory model
- any implication that the knowledge base should become a bundle of optimized
  prompt artifacts rather than explicit records

### Concrete recommendation now

1. Do **not** integrate DSPy directly into the board or roundtable runtime.
2. Create a local concept of **research operations**:
   explicit schema files for tasks like evidence evaluation, synthesis, retrieval,
   and contradiction checking.
3. Link those operation definitions to:
   - round decisions
   - validation examples
   - supersession history
   - future board execution records
4. Treat DSPy as a source of design patterns for signatures and validation, not as
   the governing runtime.

### One-sentence verdict

Do not adopt DSPy itself; instead, borrow its explicit signature-and-validation
discipline to create repo-native research-operation artifacts that stay legible,
versioned, and governed by the existing round/board/knowledge architecture.

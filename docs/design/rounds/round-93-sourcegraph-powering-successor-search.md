# Round 93 — Should Sourcegraph Power Search on the Successor to GitHub?

**Status:** Closed  
**Tags:** market, strategy, product, tooling  
**Voices used:** Copilot synthesis, GitHub official code-search grounding, Sourcegraph official positioning  
**Additional note:** this round focused on whether Sourcegraph should become the
default search layer on a future forge/successor product, not merely whether
integration is possible

### Round question

The maintainer wanted a follow-up round on Sourcegraph's relationship to Vaglio
or a successor-to-GitHub product:

- should the successor simply let Sourcegraph power semantic search
- why has GitHub not already taken that route
- did GitHub miss a business opportunity, or is there a good reason for GitHub
  to keep search as a native product capability
- does GitHub's current choice leave a real opening for Sourcegraph, and if so,
  what kind

### External grounding used

GitHub's own public explanation of code search says:

- GitHub built its new code search engine (**Blackbird**) from scratch, in Rust
- they had already tried existing general search solutions for years and found
  them poor on user experience, slow on indexing, and expensive to host
- GitHub's stated reasons for building its own engine were:
  - a desired new integrated user experience around searching, browsing,
    navigating, and reading code
  - the unique technical requirements of code search as distinct from general
    text search
  - GitHub's unusual scale and update-rate challenge
- GitHub's public product framing emphasizes tightly integrated search, code
  navigation, and code view on GitHub.com

Sourcegraph's own public positioning says:

- GitHub code search is often sufficient for code hosted exclusively on GitHub,
  especially at smaller scale
- Sourcegraph's strongest fit is large, complex, and/or multi-code-host
  environments
- Sourcegraph emphasizes universal code search, IDE-like cross-repo navigation,
  and broader enterprise code intelligence across GitHub, GitLab, Bitbucket,
  Perforce, and more

### Relevant prior context

This round builds directly on:

- **Round 62** — the successor product should separate discussion, execution, and
  longer-term memory rather than collapse everything into one tool
- **Round 65** — local `jj` advantage is real but narrow
- **Round 67** — any moat is more likely in decision/correction memory than in
  generic hosting
- **Round 89** — canonical memory and derived machine-readable layers should be
  kept explicit
- **Round 90** — Sourcegraph is stronger at semantic discovery; the local system
  should differentiate above search
- **Round 91** — the Bun case sharpened the point that Sourcegraph wins the
  "find risky code" problem while lineage-aware memory helps after discovery

### First-pass convergence

The round converged on the following points.

1. **It is probably not best to make Sourcegraph the canonical default search
   engine of the successor product.**
   Search is too foundational to the forge experience. If the product wants to
   be a real successor rather than a thin orchestration shell around someone
   else's discovery layer, it should eventually own a native search experience.

2. **That does not mean Sourcegraph should be ignored.**
   Sourcegraph may still be a very strong:
   - integration partner
   - acceleration layer
   - optional enterprise add-on
   - migration bridge while the successor's native search is immature

3. **GitHub did not simply "miss" the opportunity.**
   GitHub's public rationale shows the opposite: they viewed code search as a
   strategic, product-defining capability requiring:
   - deep product integration
   - strong control over UX
   - control over indexing economics and latency
   - control over permissions, trust, and platform boundaries
   - architecture tuned to GitHub's scale and product model

4. **The opening for Sourcegraph is real, but narrower than "GitHub forgot to do
   search."**
   The opening exists because GitHub optimizes for:
   - GitHub-hosted code
   - native GitHub workflows
   - broad default experience across a massive general-purpose forge

   Sourcegraph can instead specialize in:
   - multi-host enterprise code estates
   - deeper cross-repo and cross-system code intelligence
   - organizations whose code is fragmented across many systems
   - teams that want stronger search/intelligence without moving their whole
     development system

### Why not simply let Sourcegraph power the successor's search?

The round's answer was **not as the long-term core, though possibly yes as a
temporary or optional layer**.

The reasons against making it the canonical default were:

1. **Search is core product surface, not plumbing**
   The successor's search UX should be tightly tied to:
   - code view
   - history view
   - review
   - branch/change lineage
   - local memory and decision surfaces

   Outsourcing the main search layer would give away too much of the product's
   everyday interaction loop.

2. **Dependency risk**
   If the successor depends on Sourcegraph for a core function, it becomes
   vulnerable on:
   - pricing
   - licensing
   - roadmap divergence
   - deployment constraints
   - product-priority mismatch

3. **Permissions / trust boundary complexity**
   Search is where private code, tenancy, and cross-repo visibility rules become
   extremely sensitive. A successor forge will usually want maximum control over
   those boundaries.

4. **Economic and product-learning reasons**
   Search is a major source of usage understanding. Owning it teaches the
   platform:
   - which queries matter
   - which workflows stall
   - where navigation is weak
   - where additional structure is needed

   Giving that surface away too early would also give away valuable product
   learning.

### Why GitHub hasn't done this already

The round's answer is that GitHub has **good structural reasons** not to.

GitHub's own blog says they spent years trying existing solutions and still
built Blackbird because:

- code search has unique technical needs unlike ordinary text search
- GitHub wanted a new integrated user experience around code understanding
- GitHub's scale is unusual enough that off-the-shelf or code-specific external
  options did not fit cleanly

So the best explanation is not "GitHub failed to notice search matters."
It is:

- GitHub considered search strategic
- GitHub wanted product and systems control
- GitHub believed its scale and UX goals justified first-party investment

### Does GitHub's current approach still leave an opening?

Yes, but the opening is not simply "better search on GitHub."

The opening is in places where GitHub is structurally less optimized:

1. **Multi-host code estates**
   GitHub's native search is naturally centered on GitHub-hosted code.

2. **Organizations with fragmented code and infrastructure**
   If code lives across GitHub, GitLab, Bitbucket, Perforce, local mirrors, or
   regulated internal systems, Sourcegraph's cross-host story is materially
   stronger.

3. **Teams wanting deeper search/intelligence without changing forge**
   Sourcegraph can sell into an existing ecosystem rather than demanding a host
   migration.

4. **Specialized enterprise code-intelligence workflows**
   For large migrations, audits, security investigations, or deep legacy-system
   understanding, a dedicated code-intelligence company can often go deeper than
   a broad forge's default baseline.

### What this means for the successor product

The round recommended a layered stance.

#### Short-to-medium term

The successor could reasonably:

- build a native baseline search experience
- support optional Sourcegraph-backed augmentation for organizations that already
  use it
- import or link Sourcegraph search sessions and Deep Search outputs into local
  decision-memory artifacts
- avoid making Sourcegraph a hard dependency for every user

#### Long term

If the successor aspires to be a true forge/platform rather than a niche memory
  companion, it should own:

- core code search UX
- permissions-sensitive search behavior
- search/navigation integration with its own history and review model

But it may still integrate with Sourcegraph at the edges where Sourcegraph has
real strengths.

### Best integration framing

The strongest product framing is:

- **native search is table stakes**
- **Sourcegraph integration is optional power, not the canonical substrate**
- **the local moat remains above search**

That means:

- use native search for default product coherence
- use Sourcegraph where customers already depend on it or where cross-host
  enterprise discovery is the main need
- keep the differentiated value in lineage-aware decision memory, not in search
  delegation alone

### What not to claim

The round was especially firm that the project should **not** say:

- "we should outsource search entirely because Sourcegraph already solved it"
- "GitHub missed the importance of search"
- "the successor should never build its own search"
- "Sourcegraph's existence proves forges should stay weak at search"

These were treated as overreactions.

### What to say instead

The stronger commercial language is:

- "Search is a core forge capability, so the successor should own a native
  baseline."
- "Sourcegraph remains a strong integration partner where cross-host enterprise
  discovery is the real problem."
- "GitHub did not ignore search; it chose to internalize it because search is
  strategic, integrated, and scale-sensitive."
- "The enduring opening is not that GitHub forgot search, but that a broad forge
  and a specialized code-intelligence company optimize for different things."

### One-sentence verdict

The successor to GitHub should probably not make Sourcegraph the canonical
default search engine, because search is too central to product coherence,
permissions, and platform learning; GitHub's choice to build Blackbird reflects
that strategic reality, while the real opening for Sourcegraph remains in
multi-host enterprise code intelligence and optional deep-discovery integration
rather than in becoming the default substrate of every forge.

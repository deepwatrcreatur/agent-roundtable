## Round 108 — Pi vs OpenCode for Free Models and DeepSeek

**Tags:** harnesses, pi, opencode, deepseek, free-models, orchestration  
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI, Claude CLI, DeepSeek API, Copilot synthesis  
**Additional note:** the round also attempted a direct Pi CLI seat, but the local
Pi installation failed both attempts with `No models available` and a request for
provider API-key/model configuration. That failure is itself relevant evidence in
this round rather than a recoverable seat omission.

### Round question

The maintainer wanted a follow-up discussion on whether the Pi coding agent is a
good alternative to OpenCode for this project's harness needs, especially if the
goals are:

- reaching free or cheap non-vendor models
- accessing DeepSeek through an API key
- and preserving reproducible, repo-native multi-agent rounds

The round was explicitly grounded in prior archive evidence:

- earlier rounds that used free OpenCode voices such as:
  - `opencode/big-pickle`
  - `opencode/minimax-m2.5-free`
  - `opencode/nemotron-3-super-free`
  - `opencode/ring-2.6-1t-free`
- the older DeepSeek conclusion that direct HTTP/API integration was cleaner than
  routing DeepSeek through OpenCode for one-shot round participation
- and the local design history that already treated Pi as an interesting thin
  harness reference, but not as part of the required v1 roster

### Participation record

What actually happened in this run:

- **Codex CLI:** substantive
- **Gemini CLI:** substantive after a retry that explicitly forbade tool use
- **Claude CLI:** substantive
- **DeepSeek API:** substantive via direct HTTP API with local credential
- **Pi CLI:** attempted twice, failed twice with `No models available`, so the
  round records that failure as operational evidence instead of inventing a Pi
  voice
- **Copilot:** substantive

### Voice summaries

#### Codex CLI

- Strongest on keeping the question **seat-specific rather than ideological**.
- Treated Pi as promising where the project wants:
  - a thin one-shot harness
  - explicit `--provider` / `--model` / `--api-key` control
  - stateless runs such as `-p --no-session --mode json`
- Treated OpenCode as stronger where the project wants:
  - a unifying server/provider surface
  - future session-backed seats such as Copilot/OpenCode Go
  - or broader provider aggregation rather than a narrow one-shot wrapper
- Reaffirmed that DeepSeek should remain direct HTTP because that is already a
  closed local decision and Pi does not add enough value to overturn it.

#### Gemini CLI

- Most favorable to Pi as a **runtime shape** for programmatic provider routing.
- Argued that Pi is cleaner than OpenCode for:
  - modular provider selection
  - structured one-shot execution
  - and future API-key-based seats
- But still treated Pi as **inferior for zero-cost/free-model access today**
  because the local probes showed it does not expose usable models without
  extra key plumbing.
- Recommended keeping OpenCode only for the legacy free-model niche while using
  Pi for bring-your-own-key providers.

#### Claude CLI

- Drew the sharpest boundary between:
  - vendor-tuned CLIs
  - thin key-routing harnesses
  - and session/tool-injection servers
- Treated Pi as best for:
  - provider-agnostic API-key routing
  - light one-shot invocation
  - and script-friendly JSON output
- Treated OpenCode as best for:
  - bundled free-tier model access
  - session-backed tools
  - and future server-style seats
- Explicitly said free OpenCode voices should remain experimental rather than
  serious deliberation seats.

#### DeepSeek API

- Most skeptical about Pi in the current environment.
- Emphasized that Pi looks better **in theory than in demonstrated local
  practice** because the local `--list-models` probes were empty and the live Pi
  seat failed to hydrate a usable model.
- Treated OpenCode as still stronger for historically demonstrated free-model
  access.
- Strongly reaffirmed that DeepSeek should stay on direct HTTP/API integration,
  with Pi at most as a future optional wrapper after real provider verification.

#### Copilot

- I agreed with the shared hybrid line:
  - Pi is a useful thin harness, not the new universal answer
  - OpenCode is still useful where the project wants bundled free-model access or
    a session/server layer
  - DeepSeek remains best handled directly over HTTP/API
- The failed live Pi seat mattered materially: it moved the answer away from
  trend enthusiasm and toward an operational boundary.

### First-pass convergence

The round converged on the following points.

1. **Pi is not a replacement for OpenCode.**
   No substantive voice supported a full migration away from OpenCode or a claim
   that Pi should become the only generic harness.

2. **Pi's real value is as a thin BYOK harness.**
   The strongest recurring case for Pi was:
   - explicit provider/model selection
   - stateless one-shot calls
   - JSON-friendly output
   - and easier programmatic wrapping for API-key-backed providers

3. **OpenCode remains stronger for the project's specific free-model history.**
   The existing archive contains real evidence of OpenCode's free voices being
   usable, even if inconsistently. Pi currently does not reproduce that without
   external credential setup.

4. **Direct HTTP remains the right DeepSeek path.**
   The round did not overturn the earlier local decision. If the project wants a
   dependable DeepSeek seat in one-shot rounds, direct API integration remains
   the cleanest path.

5. **Vendor harness choice should remain model-family-specific.**
   The panel repeatedly rejected flattening all seats behind one abstraction.
   Claude-style seats benefit from vendor-tuned harnesses; DeepSeek does not need
   one; Pi is most attractive where no tuned vendor CLI is essential.

### Real disagreements that remained

The disagreement was mostly about how enthusiastic the project should be about
Pi right now.

- Codex and Copilot treated Pi as a useful **secondary harness** now
- Gemini and Claude were more architecturally favorable to Pi as the likely best
  long-run thin BYOK adapter
- DeepSeek was the most skeptical and argued the recommendation should stay
  conservative until Pi is verified end-to-end with real provider credentials

That disagreement did **not** affect the larger boundary. All substantive voices
still rejected “migrate to Pi as the new primary harness for everything.”

### Final synthesis

The strongest conclusion is a disciplined hybrid:

1. Keep vendor CLIs as the primary path for serious named seats where the vendor
   harness materially shapes behavior or quality.
2. Keep **direct HTTP/API integration** as the canonical DeepSeek path.
3. Keep **OpenCode** for:
   - experimental free-model access
   - and future session-backed/server-backed seats that actually need it
4. Add **Pi** only as a second harness for bounded one-shot BYOK experiments,
   especially where:
   - `--provider`
   - `--model`
   - `--api-key`
   - `--no-session`
   - and `--mode json`
   are operationally useful

The live Pi failure is important here. It does not prove Pi is bad; it proves
that in this environment Pi is not yet a drop-in route to free models or even a
verified DeepSeek wrapper. That makes the right answer **hybrid and
conditional**, not migratory.

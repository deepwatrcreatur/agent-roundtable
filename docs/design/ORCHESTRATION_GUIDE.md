# Discussion Orchestration Guide

This guide is for the human or agent acting as the **discussion leader** for a
real Vaglio / `agent-roundtable` round.

If you need the shortest possible entry point, start with
`docs/design/DISCUSSION_LEADER_SUMMARY.md` and then come back here.

It exists to prevent repeated failure on the same operational problems:

- simulated voices being mistaken for genuine quorum
- silently dropping a requested participant
- discovering missing prerequisites only after a round has started
- losing round output because it lives only in `/tmp`
- mixing round documentation into a dirty local checkout

---

## 1. Non-negotiable rules

### 1.1 Genuine voices only

If a round says it includes Codex, Gemini, DeepSeek, or Copilot, that means the
actual tool must have been used for that voice.

Do **not** simulate absent agents.

If a requested voice cannot be run, stop and report a **degraded roster**
explicitly.

### 1.2 Never silently omit a requested voice

If the human asks for a specific roster, either:

- include that agent, or
- fail fast with the exact missing prerequisite

Example: `DeepSeek requested but DEEPSEEK_API_KEY is unavailable`.

### 1.3 Score objects, not people

When rounds discuss controversial public figures, keep the system-design focus
on:

- contested objects
- governance events
- power/process routing
- dashboard representation

Do not convert the round into personality judgment or unsupported factual claims
about people.

---

## 2. Where to read before running a round

Start in this order:

1. `AGENTS.md`
2. `docs/design/DECISION.md`
3. `docs/design/rounds/historical-synthesis.md`
4. the specific prior round files relevant to the topic
5. `/home/deepwatrcreatur/flakes/ORCHESTRATOR_HANDOFF.md` if a session handoff exists

If there is already a user/session handoff outside the repo, treat it as a
**state note**, not as authoritative round numbering.

---

## 3. Recommended roster

For the current real-world workflow, the best practical roster is:

- `Codex`
- `Gemini`
- `DeepSeek`
- `Copilot`

Notes:

- `Claude` may still be used as IC when available, but do not assume it is.
- `Copilot` is currently the discussion leader writing one real voice directly,
  not a separate repo-integrated subprocess.
- If Claude is unavailable, say so plainly and run a degraded synthesis process
  instead of inventing an IC voice.

### 3.1 Enrichment seats: free-model experiments are worth using when they add value

Do **not** forget the opportunity to enrich a round with an additional
experimental seat when a free-model path is available and the topic would benefit
from broader coverage.

In practice this usually means:

- an OpenCode/free-model voice
- or another explicitly experimental non-primary seat

Use these seats when they are likely to add one of:

- a cheaper dissenting view
- broader model-family coverage
- a stress test of whether the question is robust outside the main vendor CLIs

But keep the boundary clear:

- the core serious roster is still the vendor CLI / direct API path
- free-model seats are **enrichment**, not a substitute for the main quorum
- and they must be labeled honestly in the round note as experimental if they are
  lower-confidence or historically drift-prone

The failure mode to avoid is not “using free models.” The failure mode is
leaving value on the table by never trying them, or pretending they are
first-class evidence when they are really exploratory supplements.

---

## 4. Preflight checklist

Do this **before** launching the round.

### 4.1 Confirm requested roster

Write down the exact intended participants.

Example:

- Codex
- Gemini
- DeepSeek
- Copilot

### 4.2 Validate prerequisites

#### Codex

- binary: `codex`

#### Gemini

- binary: `gemini`
- keychain warnings are usually non-fatal

#### DeepSeek

DeepSeek is not run through a standalone CLI here. It is wired through
`Roundtable.Actions.RunCliAgent` in the Elixir project.

Expected decrypted secret locations on this host:

- `/home/deepwatrcreatur/.local/share/agenix-user-secrets/deepseek-api-key`
- fallback: `/run/agenix/deepseek-api-key`

Source secret in config repo:

- `unified-nix-configuration/secrets-agenix/deepseek-api-key.age`

Do **not** print the key. Only read it into the environment of the subprocess
that needs it.

If the local CLI path is unavailable or inconvenient, a direct HTTP API seat is
also valid here and has been successfully recovered in-session using:

- `https://api.deepseek.com/v1/chat/completions`
- the decrypted local key file
- explicit CA bundle:
  `/etc/ssl/certs/ca-certificates.crt`

#### Copilot

- the current conversation itself is the Copilot voice

#### Optional enrichment seat: OpenCode / free-model path

If you think a round would benefit from one extra experimental voice, check
whether the local OpenCode/free-model path is actually usable before launch.

Practical preflight in this environment:

```bash
opencode models
```

This prints the locally available provider/model IDs. In recent runs it exposed
free or cheap enrichment candidates such as:

- `opencode/nemotron-3-super-free`
- `opencode/deepseek-v4-flash-free`
- `opencode/big-pickle`

Typical reasons to add it:

- the topic is broad and would benefit from one more independent angle
- cost matters and you want a cheap extra challenge seat
- the project is explicitly evaluating harnesses, model access paths, or whether
  free-model voices are still worth keeping in the toolbox

Typical cautions:

- free-model voices have produced mixed-quality answers in prior rounds
- some have drifted into repo exploration instead of bounded response
- some have failed to return substantive output in the run window

So the rule is:

- use them opportunistically when they enrich the round
- but never count them as evidence that the main requested roster was satisfied
- and if OpenCode itself fails, record that failure as enrichment-seat
  unavailability rather than smoothing it over

### 4.3 Preflight failure policy

If any requested voice is unavailable:

- say which one
- say why
- do **not** call the resulting round complete

---

## 5. Prompt construction

Each round prompt should contain:

1. the round topic
2. any relevant closed-round context
3. concrete subquestions
4. explicit constraints
5. a required satisfaction marker

Keep the prompt focused on system design and protocol, especially when the topic
is socially sensitive.

Write the shared prompt to a temp file so all voices answer the **same** round:

`/tmp/<round-name>_prompt.txt`

---

## 6. Running the voices

## 6.1 Codex

Use the real CLI.

Example pattern:

```bash
cd /home/deepwatrcreatur/flakes/agent-roundtable
codex exec /tmp/round_prompt.txt --skip-git-repo-check --full-auto --model gpt-5.4 \
  > /tmp/codex_round.txt
```

## 6.2 Gemini

Use `gemini -p` with the prompt content.

Example pattern:

```bash
PROMPT="$(cat /tmp/round_prompt.txt)"
gemini -p "$PROMPT" > /tmp/gemini_round.txt
```

Notes:

- keychain warnings do not necessarily mean failure
- read the output file, not just stderr noise

## 6.3 DeepSeek

Use the repo's Elixir action:

- module: `roundtable/lib/roundtable/actions/run_cli_agent.ex`
- backend: direct HTTP via `Req`

Recommended pattern:

```bash
cd /home/deepwatrcreatur/flakes/agent-roundtable/roundtable
export DEEPSEEK_API_KEY="$(cat /home/deepwatrcreatur/.local/share/agenix-user-secrets/deepseek-api-key)"
nix develop . --command bash -lc '
  export DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY"
  mix compile >/dev/null 2>&1
  mix run --no-compile -e '\''prompt = File.read!("/tmp/round_prompt.txt");
  case Roundtable.Actions.RunCliAgent.run(%{agent: :deepseek, prompt: prompt, repo_root: File.cwd!()}, %{}) do
    {:ok, %{stdout: out}} -> IO.write(out)
    other -> IO.inspect(other, limit: :infinity); System.halt(1)
  end'\'' > /tmp/deepseek_round.txt
'
```

If DeepSeek fails with `:deepseek_api_key_missing`, fix the environment before
continuing. Do not downgrade silently to a three-voice round unless the human
approves that degraded quorum.

Direct HTTP fallback is also acceptable when it is the real DeepSeek API.
This pattern was successfully used to restore the DeepSeek seat:

```bash
python - <<'PY'
import json, pathlib, subprocess

key = pathlib.Path.home() / '.local/share/agenix-user-secrets/deepseek-api-key'
prompt = pathlib.Path('/tmp/round_prompt.txt').read_text()

cmd = [
    'curl', '-sS', '--max-time', '120',
    '--cacert', '/etc/ssl/certs/ca-certificates.crt',
    'https://api.deepseek.com/v1/chat/completions',
    '-H', 'Content-Type: application/json',
    '-H', f'Authorization: Bearer {key.read_text().strip()}',
    '-d', json.dumps({
        'model': 'deepseek-chat',
        'messages': [{'role': 'user', 'content': prompt}],
        'temperature': 0.2
    }),
]

proc = subprocess.run(cmd, capture_output=True, text=True)
print(proc.stdout)
PY
```

Notes:

- do **not** use `curl -k`
- if plain `curl` fails with certificate error 60, retry with the explicit
  `--cacert` path above
- record the seat as `DeepSeek API` in the round note if this path is used

### 6.3.1 Worked example: Round 104 DeepSeek rerun

This exact failure-and-recovery path happened while archiving:

- `round-104-critiquing-alternatives-and-product-necessity.md`

Observed sequence:

1. DeepSeek was initially marked unavailable because there was no working local
   CLI seat.
2. The discussion leader then checked for the decrypted local key and found:

   ```bash
   /home/deepwatrcreatur/.local/share/agenix-user-secrets/deepseek-api-key
   ```

3. A first direct `curl` call failed with TLS verification error 60:

   - unable to get local issuer certificate

4. Retrying with:

   ```bash
   --cacert /etc/ssl/certs/ca-certificates.crt
   ```

   succeeded.

5. The round note was then amended to say:

   - `DeepSeek API: substantive after restoring direct HTTP access`

6. The round note also explicitly recorded that the seat had been recovered via:

   - direct HTTP API
   - the local decrypted key
   - explicit CA bundle configuration

Operational lesson:

- if the key exists locally, DeepSeek is **not** unavailable merely because there
  is no standalone CLI binary
- recover the seat honestly, then amend the round note rather than leaving a
  stale “DeepSeek unavailable” statement in the durable record

## 6.4 Optional enrichment seat: OpenCode / free models

Use the real CLI when you add this seat.

Recommended discovery step:

```bash
opencode models
```

Recommended one-shot run pattern:

```bash
PROMPT="$(cat /tmp/round_prompt.txt)"
opencode run -m opencode/nemotron-3-super-free "$PROMPT" \
  > /tmp/opencode_round.txt
```

Notes:

- this is an enrichment seat, not part of the mandatory serious quorum
- save its output separately just like the primary seats
- if a specific model fails, try another listed OpenCode seat once rather than
  pretending the enrichment voice was never requested
- if the command returns only startup noise, inspect the saved file before
  deciding whether the seat failed

If the round topic explicitly evaluates harnesses, free-model access, or cheap
extra dissent, record the seat concretely, for example:

- `OpenCode free-model seat: substantive via opencode/nemotron-3-super-free`
- `OpenCode free-model seat: unavailable after model/provider failure`

## 6.5 Copilot

Copilot should contribute an explicit fourth voice in the discussion leader's
own synthesis process, not just summarize the others.

That means writing a real independent position answering the same prompt:

- what Copilot agrees with
- what Copilot disagrees with
- what Copilot would surface as the main failure mode
- a satisfaction marker

## 7. Interpreting outputs

Read all voices before synthesizing.

Do not rush from first-pass convergence to closure.

Look specifically for:

- hidden disagreement masked by similar wording
- governance gaps
- identity / authority / legitimacy problems
- gaming risks
- “this sounds good but would be illegitimate in practice” concerns

If there is a real disagreement, run a narrowed follow-up round on the exact
point of divergence.

Good narrowed follow-up targets are:

- identity anchor disputes
- authority / override rules
- what the dashboard may show vs. must refuse to show
- what is object-scoped vs. person-scoped

---

## 8. Closing a round

A round is ready to close when:

- all intended voices actually ran
- the remaining disagreements are resolved or explicitly narrowed away
- the resulting claims are operational and bounded

When closing, write:

1. first-pass convergence
2. disconfirmation findings
3. narrowed follow-up result if one happened
4. final closure summary

Do not present simulated consensus as if it were a real closed round.

---

## 9. Recording round artifacts

Store transient raw outputs in `/tmp/` while working, for example:

- `/tmp/codex_<round>.txt`
- `/tmp/gemini_<round>.txt`
- `/tmp/deepseek_<round>.txt`

Then persist the durable round note in:

- `docs/design/rounds/`

Recommended files:

- one dedicated round file, e.g. `round-49-open-source-controversy.md`
- update `docs/design/rounds/historical-synthesis.md`

The durable note should capture the consensus, not every raw paragraph.

Publishing is not finished when the note exists locally. After updating the
durable files, the leader should make sure the archival commit is actually
created and pushed unless the maintainer explicitly asked to leave it unpushed.

---

## 10. Safe git workflow for publishing rounds

If the main checkout is dirty, do **not** mix new round notes into unrelated
local changes.

Use this workflow:

1. inspect `git status`
2. if dirty and not clearly yours, create a separate worktree/branch
3. write round notes there
4. commit and push from the clean worktree after verifying the intended archive
   files
5. only then fast-forward or merge into `main`

This avoids overwriting unrelated local documentation or implementation work.

---

## 11. Known pitfalls

### 11.1 “The round used real agents” when one voice was simulated

This is the most important failure to avoid. If one voice was improvised, the
round is not a normal genuine round.

### 11.2 Secret exists in agenix but not in the subprocess environment

The `.age` file is not itself usable. The round leader needs the **decrypted**
path on the host and must export it for the subprocess only.

### 11.3 Mistaking noisy stderr for failure

Gemini in particular may emit keychain warnings and still succeed.

### 11.4 Forgetting useful enrichment seats because they are not part of the default roster

The leader should remember that free-model or OpenCode-style seats can add real
value when used deliberately.

Do not fall into the habit of:

- running only the default roster mechanically
- forgetting cheap extra coverage when it is available
- or treating enrichment seats as too low-status to bother with

The right pattern is:

- primary roster first
- enrichment seats when they are likely to improve the round
- honest labeling if the extra seat is experimental or degraded

### 11.5 Treating controversial-figure rounds as reputation scoring

The system should surface:

- object stress
- governance bottlenecks
- repeated power disputes

It should not emit:

- “toxicity scores”
- personality ratings
- durable reputation numbers

---

## 12. Minimum handoff format

When handing a round to the next discussion leader, include:

- the active topic
- the actual roster used
- any missing voices and why
- temp output paths in `/tmp`
- whether the round is first-pass, red-team, or narrowed follow-up
- whether durable notes were written
- whether commit/push happened

Do not treat "notes written locally" as equivalent to "round published". The
handoff should say explicitly if the archival commit is still only local.

---

## 13. Vaglio web app caution

The Vaglio VM may already be running the Phoenix / LiveView web app, but do not
assume the web app is yet the authoritative operational path for proving that a
requested roster is actually ready.

Until that is explicitly true, continue to validate:

- the real CLI/API path for each requested voice
- the local credential path where relevant
- and the actual returned output

before describing a round as complete.

---

## 14. Current guardrails in code

The repo now contains fail-fast guardrails for roster validation:

- `roundtable/lib/roundtable/actions/run_cli_agent.ex`
  - validates supported agents
  - rejects duplicate agents
  - fails fast if DeepSeek lacks `DEEPSEEK_API_KEY`
- `roundtable/lib/roundtable/cli.ex`
  - validates the requested roster before a discussion starts
- `AGENTS.md`
  - now instructs leaders not to silently omit requested voices

Use those guardrails, but do not rely on them as a substitute for operational
discipline.

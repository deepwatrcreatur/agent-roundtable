# Discussion Leader Summary

If you are leading a real Vaglio / `agent-roundtable` discussion round and you
only read one operational document, read this one first.

For full detail, then continue to:

- `AGENTS.md`
- `docs/design/ORCHESTRATION_GUIDE.md`
- `docs/design/rounds/historical-synthesis.md`

---

## 1. Non-negotiable rule

**Never simulate a missing voice.**

If a round claims to include `Codex`, `Gemini`, `DeepSeek`, `Claude`, or
`Copilot`, that voice must have been obtained from the real tool or API.

If one seat is unavailable:

- say which seat is missing
- say why
- record the round as a degraded roster, not a normal complete quorum

---

## 2. Current practical roster

For recent real rounds in this repo, the practical roster has been:

- `Codex`
- `Gemini`
- `Claude`
- `DeepSeek`
- `Copilot` synthesis / independent position

DeepSeek is **not** a local CLI seat here.
It is normally accessed through the repo's direct HTTP integration or an
equivalent direct API call using the local decrypted key.

Free-model / OpenCode-style seats are **not** part of the mandatory core roster,
but they are still worth remembering as optional enrichment seats when they can
add a useful extra angle at low cost. Use them to enrich a round, not to replace
the main vendor/direct-API quorum.

---

## 3. Where to look first

Before running a new round, read:

1. `AGENTS.md`
2. `docs/design/DISCUSSION_LEADER_SUMMARY.md`
3. `docs/design/ORCHESTRATION_GUIDE.md`
4. `docs/design/rounds/historical-synthesis.md`
5. the most recent relevant round files

---

## 4. DeepSeek recovery recipe that actually worked

This knowledge should not be lost again.

### 4.1 Expected local key path

On this host, the decrypted key was present at:

```bash
/home/deepwatrcreatur/.local/share/agenix-user-secrets/deepseek-api-key
```

Do **not** print the key itself.

### 4.2 Why the first attempt failed

Plain `curl` to `https://api.deepseek.com/v1/chat/completions` initially failed
with:

- `curl: (60) SSL certificate ... unable to get local issuer certificate`

The fix was **not** to disable verification.
The fix was to pass the explicit CA bundle:

```bash
--cacert /etc/ssl/certs/ca-certificates.crt
```

### 4.3 Proven direct API pattern

This pattern worked for recovering the DeepSeek seat:

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

Observed result during recovery:

- request succeeded
- DeepSeek responded with model name `deepseek-v4-flash`

That seat is acceptable as a real DeepSeek API voice and should be recorded as
such in the round note.

---

## 5. Real-round workflow

### 5.1 Build one shared prompt

Write the shared prompt to a temp file, for example:

```bash
/tmp/round104_prompt.txt
```

Every voice should answer the **same** prompt.

### 5.2 Run the voices

- `Codex`: real `codex` CLI
- `Gemini`: real `gemini -p`
- `Claude`: real `claude -p`
- `DeepSeek`: repo Elixir action or direct HTTP API with the CA bundle fix above
- `Copilot`: an explicit independent position, not just a summary of others
- optional enrichment seat: a real OpenCode/free-model voice when it is
  available and likely to add value

### 5.3 Save raw artifacts temporarily

Use `/tmp/` for raw outputs while working, e.g.:

- `/tmp/codex_round.txt`
- `/tmp/gemini_round.txt`
- `/tmp/claude_round.txt`
- `/tmp/deepseek_round.json`

### 5.4 Persist only the durable synthesis

Write the durable round note in:

```text
docs/design/rounds/
```

Then update:

- `docs/design/rounds/historical-synthesis.md`
- any queue/index files affected

Before declaring the round finished, commit and push the archival update unless
the maintainer explicitly asked you to stop before publication.

---

## 6. Vaglio web app note

The Vaglio VM and Phoenix / LiveView surface may exist and may be partially
working, but do **not** assume the web app is currently the authoritative way to
verify roster readiness.

For now, roster readiness should still be confirmed by:

- checking the actual CLI/API path for each requested voice
- verifying the credential path where relevant
- and capturing the real output before claiming a complete round

Until that changes, the repo documents and direct tool invocations remain the
source of truth for discussion leadership.

---

## 7. What to write in the round note

Each durable round note should say:

- which voices actually ran
- whether any seat was degraded or retried
- the main convergence
- real disagreements that remained
- whether a rerun happened

Do **not** flatten real disagreement away just to make the round look neat.

---

## 8. One-sentence operating principle

The discussion leader's job is not to make the round look complete; it is to
make the round's **actual roster and evidence trail** explicit and recoverable.

That includes remembering when an experimental free-model seat could enrich the
discussion, and then labeling that seat honestly if it is used.

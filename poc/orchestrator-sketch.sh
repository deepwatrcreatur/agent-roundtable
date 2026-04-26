#!/usr/bin/env bash
# orchestrator-sketch.sh — NOT production code
#
# A minimal sketch of the main orchestrator loop to anchor the design
# discussion. Agents should critique, improve, or replace this.
#
# Assumptions baked in here (to be validated in ACTIVE_DISCUSSION.md):
#   - Each agent CLI accepts a prompt via stdin and writes to stdout
#   - The discussion file grows by appending agent responses
#   - Termination is detected by grepping for [satisfied] markers
#   - The IC agent (claude) produces the final synthesis
#
# Usage: ./orchestrator-sketch.sh <brief.md> <discussion.md> [max_rounds]

set -euo pipefail

BRIEF="${1:?Usage: $0 <brief.md> <discussion.md> [max_rounds]}"
DISCUSSION="${2:?}"
MAX_ROUNDS="${3:-5}"
AGENTS=("codex" "gemini" "claude")  # claude is IC; runs last each round
LOCKFILE="${DISCUSSION}.lock"

log() { echo "[roundtable $(date -u +%H:%M:%S)] $*" >&2; }

invoke_agent() {
    local agent="$1"
    local prompt_file="$2"
    case "$agent" in
        claude)  claude --print < "$prompt_file" ;;
        codex)   codex --quiet  < "$prompt_file" ;;
        gemini)  gemini --headless < "$prompt_file" ;;  # flag TBD — see Q1
        *)       echo "unknown agent: $agent" >&2; return 1 ;;
    esac
}

all_satisfied() {
    # Returns 0 (true) if every non-IC agent has [satisfied] or
    # [satisfied-conditional] for all questions.
    # This naive grep is a placeholder — see Q3 for a robust approach.
    local unsatisfied
    unsatisfied=$(grep -c '\[needs more evidence' "$DISCUSSION" || true)
    [ "$unsatisfied" -eq 0 ]
}

build_prompt() {
    local agent="$1"
    printf "You are %s contributing to an autonomous design discussion.\n\n" "$agent"
    printf "Read the brief and discussion below, then append your next position.\n\n"
    printf "=== BRIEF ===\n"; cat "$BRIEF"
    printf "\n=== DISCUSSION SO FAR ===\n"; cat "$DISCUSSION"
}

main() {
    log "Starting roundtable: brief=$BRIEF discussion=$DISCUSSION max_rounds=$MAX_ROUNDS"

    for round in $(seq 1 "$MAX_ROUNDS"); do
        log "Round $round"

        for agent in "${AGENTS[@]}"; do
            # Acquire a simple file lock to prevent concurrent writes
            (
                flock -x 200
                log "Invoking $agent"
                local tmpfile
                tmpfile=$(mktemp)
                build_prompt "$agent" > "$tmpfile"
                response=$(invoke_agent "$agent" "$tmpfile")
                rm -f "$tmpfile"
                printf "\n%s\n" "$response" >> "$DISCUSSION"
            ) 200>"$LOCKFILE"
        done

        if all_satisfied; then
            log "All agents satisfied after round $round. Discussion closed."
            exit 0
        fi

        log "Round $round complete. Unsatisfied markers remain. Continuing."
    done

    log "Max rounds ($MAX_ROUNDS) reached without full consensus. Human review required."
    exit 1
}

main

#!/bin/sh
#
# json — the machine-readable interface, and why it matters more than the
# human-readable one.
#
#   examples/json/demo.sh
#
# --json is what makes fmevent usable inside a program rather than just inside
# an `if`. The exit status gives you the decision; --json gives you everything
# the model said about it.

set -u
cd "$(dirname "$0")" || exit 1
FMEVENT=../../bin/fmevent

TMP=$(mktemp "${TMPDIR:-/tmp}/fmevent-json.XXXXXX") || exit 1
trap 'rm -f "$TMP"' EXIT INT TERM

step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
show() { printf '\033[2m$ %s\033[0m\n' "$1"; }
note() { printf '\033[2m%s\033[0m\n' "$1"; }

GOOD='pip install failed: could not resolve dependency numpy==9.9.9'
BAD='hello world, everything is fine'

# ---------------------------------------------------------------------------

step 'The shape'
show 'fmevent --json "this is a dependency resolution failure"'
printf '%s\n' "$GOOD" | "$FMEVENT" --json --greedy "this is a dependency resolution failure" | jq .

note ''
note 'matched    the decision, same as the exit status'
note 'confidence the model'"'"'s self-report. Not a calibrated probability, and'
note '           not something to gate on by default.'
note 'evidence   what it quoted. Informational; never authoritative.'

# ---------------------------------------------------------------------------

step 'No match looks the same, with matched:false'
# Note the redirect rather than a pipe to jq: after a pipeline, $? is the LAST
# command's status, so piping here would report jq's exit code, not fmevent's.
printf '%s\n' "$BAD" | "$FMEVENT" --json --greedy "this is a dependency resolution failure" > "$TMP"
printf '\033[2mexit %d\033[0m\n' "$?"
jq . "$TMP"

# ---------------------------------------------------------------------------

step 'The exit status and the field agree — always'
note 'This is the invariant that lets you choose either one.'
printf '%s\n' "$GOOD" | "$FMEVENT" --json --greedy "this is a dependency resolution failure" > "$TMP"
printf '  exit status: %d\n' "$?"
printf '  .matched:    %s\n' "$(jq -r .matched "$TMP")"

# ---------------------------------------------------------------------------

step 'Chaining 1 — a shell conditional without the pipeline status'
note 'Handy when the command is buried inside a larger script and you want the'
note 'answer in a variable.'
if [ "$(printf '%s\n' "$GOOD" | "$FMEVENT" --json --greedy "this is a dependency failure" | jq -r .matched)" = 'true' ]; then
    printf '  -> branching on the parsed field\n'
fi

# ---------------------------------------------------------------------------

step 'Chaining 2 — decision plus detail in one call'
note 'A bare exit status cannot tell you how sure the model was. This can:'
printf '%s\n' "$GOOD" \
    | "$FMEVENT" --json --greedy "this is a dependency failure" \
    | jq -r '"matched=\(.matched) confidence=\(.confidence)\n\(.evidence)"' \
    | sed 's/^/  /'

# ---------------------------------------------------------------------------

step 'Chaining 3 — hand the whole thing to jq for routing on your side'
note 'fmevent answers one question; you compose the policy.'
printf '%s\n' "$GOOD" \
    | "$FMEVENT" --json --greedy "this is a dependency failure" \
    | jq -r 'if .matched and .confidence > 0.8 then "auto-retry" else "escalate to a human" end' \
    | sed 's/^/  decision: /'

printf '\n\033[1mDone.\033[0m\n\n'

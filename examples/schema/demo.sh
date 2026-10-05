#!/bin/sh
#
# schema — using fmevent as a structured extraction primitive rather than a
# yes/no question.
#
#   examples/schema/demo.sh
#
# Nothing is modified; every step only reads.

set -u
cd "$(dirname "$0")" || exit 1
FMEVENT=../../bin/fmevent

step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
show() { printf '\033[2m$ %s\033[0m\n' "$1"; }
note() { printf '\033[2m%s\033[0m\n' "$1"; }

DIFF='diff --git a/auth.go b/auth.go
- if password == storedPassword {
+ if subtle.ConstantTimeCompare([]byte(password), []byte(storedPassword)) == 1 {
'

# ---------------------------------------------------------------------------

step 'Give the model a shape to fill in'
note 'The schema file is ordinary JSON Schema with one Apple extension: x-order,'
note 'which fixes the order the model writes the fields in.'
show 'fmevent --schema change.json "analyse whether this changes security-sensitive behaviour"'
printf '%s' "$DIFF" \
    | "$FMEVENT" --schema change.json \
        "analyse whether this changes security-sensitive behaviour" | jq .

# ---------------------------------------------------------------------------

step 'The point: the output is a value, not prose'
note 'Because it is JSON on stdout, the decision stays in your hands. Here jq'
note 'gates on the extracted fields, with no model involved in the comparison.'
show 'fmevent --schema change.json "..." | jq -e ".security_sensitive"'
if printf '%s' "$DIFF" \
    | "$FMEVENT" --schema change.json \
        "analyse whether this changes security-sensitive behaviour" \
    | jq -e '.security_sensitive' >/dev/null; then
    printf '  -> flagged for security review\n'
else
    printf '  -> no review needed\n'
fi

# ---------------------------------------------------------------------------

step 'A second shape, over a log rather than a diff'
note 'findings.json asks for a list rather than a single verdict.'
show 'fmevent --schema findings.json "summarise what went wrong"'
printf 'warning: retrying request after timeout (attempt 2 of 3)\nERROR: could not connect to postgres at db:5432\nERROR: migration 0042 failed, aborting\n' \
    | "$FMEVENT" --schema findings.json "summarise what went wrong and say whether it blocks a release" | jq .

# ---------------------------------------------------------------------------

step 'Chaining: feed the structure straight into other tools'
show 'fmevent --schema findings.json "..." | jq -r .findings[]'
printf 'warning: retrying request after timeout (attempt 2 of 3)\nERROR: could not connect to postgres at db:5432\nERROR: migration 0042 failed, aborting\n' \
    | "$FMEVENT" --schema findings.json "summarise what went wrong and say whether it blocks a release" \
    | jq -r '.findings[]' \
    | while IFS= read -r line; do
        printf '  [ ] %s\n' "$line"
      done

note ''
note 'There is no true/false in this mode, so the exit status is 0 when valid'
note 'JSON came back and 2 when it did not — not a predicate.'

printf '\n\033[1mDone.\033[0m\n\n'

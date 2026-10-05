#!/bin/sh
#
# Gate a change on whether it touches security-sensitive behaviour.
#
#   git diff | examples/workflows/review-diff.sh -
#   examples/workflows/review-diff.sh            # takes the working-tree diff
#
# This is the --schema pattern in a workflow: the model extracts structure and
# says nothing about what to do with it. The policy is a jq expression, so it
# is inspectable, testable, and cannot be talked out of by a clever diff.
#
# Exits 1 when the change should be reviewed, so it drops straight into CI.

set -u

if [ "${1:-}" = '-' ] || [ ! -t 0 ]; then
    DIFF=$(cat)
else
    DIFF=$(git diff 2>/dev/null)
fi

if [ -z "$DIFF" ]; then
    printf 'no diff to review\n'
    exit 0
fi

cd "$(dirname "$0")" || exit 1
FMEVENT=../../bin/fmevent

RESULT=$(printf '%s' "$DIFF" | "$FMEVENT" --schema ../schema/change.json --greedy \
    "analyse whether this changes security-sensitive behaviour")
status=$?

if [ "$status" -ne 0 ]; then
    # 2 means fmevent could not produce an answer. Never treat that as "safe".
    printf 'review-diff: could not analyse the diff (exit %d)\n' "$status" >&2
    exit 2
fi

printf '%s\n' "$RESULT" | jq .

# The decision itself is deterministic. The model supplied the fields; jq
# decides what they mean for this pipeline.
if printf '%s' "$RESULT" | jq -e '
        .security_sensitive == true
        and (.category == "authentication" or .category == "cryptography")
    ' >/dev/null; then
    printf '\n\033[1mThis change alters %s. Requesting a security review.\033[0m\n' \
        "$(printf '%s' "$RESULT" | jq -r .category)" >&2
    exit 1
fi

printf '\nno security review needed (category: %s)\n' \
    "$(printf '%s' "$RESULT" | jq -r .category)"
exit 0

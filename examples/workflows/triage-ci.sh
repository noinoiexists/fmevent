#!/bin/sh
#
# A CI step that runs a command and, when it fails, routes the failure to the
# right handler instead of just going red.
#
#   examples/workflows/triage-ci.sh make test
#   examples/workflows/triage-ci.sh sh -c 'echo "boom" >&2; exit 1'
#
# Three details make this survive contact with real automation:
#
#   2>&1        the error text is on stderr, and stderr does not go through a
#               pipe. Without this, fmevent is handed an empty stream and
#               answers a question about nothing.
#   --greedy    the model is not deterministic, so without this the same build
#               can route differently on a re-run.
#   exit codes  0 routed, 1 nothing matched, 2 fmevent itself failed. All three
#               are distinguishable, so a broken model never looks like a
#               clean "no problem here".

set -u

[ "$#" -gt 0 ] || set -- sh -c 'echo "pip install failed: could not resolve dependency numpy==9.9.9" >&2; exit 1'

cd "$(dirname "$0")" || exit 1
FMEVENT=../../bin/fmevent
ROUTES=../routing/routes.json

LOG=$(mktemp "${TMPDIR:-/tmp}/fmevent-triage.XXXXXX") || exit 2
trap 'rm -f "$LOG"' EXIT INT TERM

# --- run the thing ---------------------------------------------------------

printf '\033[2m$ %s\033[0m\n' "$*"
"$@" > "$LOG" 2>&1
status=$?

if [ "$status" -eq 0 ]; then
    printf 'command succeeded\n'
    exit 0
fi

printf 'command failed (exit %d). What kind of failure is this?\n\n' "$status"
sed 's/^/    | /' "$LOG"
printf '\n'

# --- route it --------------------------------------------------------------

# fmevent reads the log on stdin and picks the highest-priority matching route
# from routes.json, then runs that route's handler. The model chooses among the
# names already declared in the file; it never produces the command itself.
"$FMEVENT" --route "$ROUTES" --greedy < "$LOG"
routed=$?

printf '\n'
case "$routed" in
    0) printf '\033[1mdispatched.\033[0m\n' ;;
    1) printf '\033[1mno route matched — escalating to a human.\033[0m\n' >&2 ;;
    *) printf '\033[1mfmevent could not decide (exit %d) — escalating.\033[0m\n' "$routed" >&2 ;;
esac

exit "$routed"

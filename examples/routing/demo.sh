#!/bin/sh
#
# routing — turning a semantic boolean into a semantic router.
#
#   examples/routing/demo.sh
#
# The handlers here only narrate; nothing on your system is modified, and the
# first two steps do not even run them. The script moves into its own directory
# first, because routes.json names its handlers relative to itself.

set -u
cd "$(dirname "$0")" || exit 1
FMEVENT=../../bin/fmevent

step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
show() { printf '\033[2m$ %s\033[0m\n' "$1"; }
note() { printf '\033[2m%s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------

step 'Decide without doing: --dry-run'
note 'The input involves both a CVE and a broken dependency resolution, so two'
note 'routes match. The model reports both; priority picks the winner.'
show 'fmevent --route routes.json --dry-run'
printf 'ERROR: CVE-2026-1234 affects 3 packages, but the patched versions conflict with the pinned lockfile so dependency resolution failed\n' \
    | "$FMEVENT" --route routes.json --dry-run

note ''
note 'Nothing ran. This is the mode to use while you are still tuning "when" text.'

# ---------------------------------------------------------------------------

step 'The same decision, machine-readable'
show 'fmevent --route routes.json --dry-run --json | jq .'
printf 'ERROR: CVE-2026-1234 affects 3 packages, but the patched versions conflict with the pinned lockfile so dependency resolution failed\n' \
    | "$FMEVENT" --route routes.json --dry-run --json | jq .

note ''
note 'Note "matches" (what the model said) versus the single winner. The model'
note 'never chooses the command; it only says which descriptions fit.'

# ---------------------------------------------------------------------------

step 'Something unambiguous routes to exactly one place'
show 'fmevent --route routes.json --dry-run'
printf 'FAILED tests/test_login.py::test_login - AssertionError: expected 200 got 500\n' \
    | "$FMEVENT" --route routes.json --dry-run

# ---------------------------------------------------------------------------

step 'Now actually run it'
show "printf 'FAILED tests/...' | fmevent --route routes.json"
printf 'FAILED tests/test_login.py::test_login - AssertionError: expected 200 got 500\n' \
    | "$FMEVENT" --route routes.json
printf '\033[2mexit %d — the action'"'"'s own status, not fmevent'"'"'s\033[0m\n' "$?"

# ---------------------------------------------------------------------------

step 'Why all_of exists'
note 'Ask a model for "a dependency failure involving a security vulnerability"'
note 'and it will hand you ["dependency", "security"] every time — it finds the'
note 'parts and does not report the whole. So the composite route declares what'
note 'implies it, and the engine derives it:'
printf '\n'
grep -A3 '"name": "dependency-security"' routes.json | sed 's/^/    /'

printf '\n\033[1mDone.\033[0m\n\n'

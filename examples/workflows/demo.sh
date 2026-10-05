#!/bin/sh
#
# workflows — end-to-end uses, chained with the tools you already have.
#
#   examples/workflows/demo.sh
#
# These are the examples to copy from: each one is a script you could drop into
# a Makefile or a CI job as-is.

set -u
cd "$(dirname "$0")" || exit 1

step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------

step 'CI triage — route a failure instead of just going red'
printf '\033[2m./triage-ci.sh sh -c "..."\033[0m\n\n'
./triage-ci.sh sh -c 'echo "ERROR: could not resolve dependency numpy==9.9.9; conflicting version constraints" >&2; exit 1'
printf '\033[2m(exit %d)\033[0m\n' "$?"

# ---------------------------------------------------------------------------

step 'CI triage — a failure nobody anticipated'
printf '\033[2m./triage-ci.sh sh -c "..."\033[0m\n\n'
./triage-ci.sh sh -c 'echo "quantum flux capacitor desynchronised at 88mph" >&2; exit 1'
printf '\033[2m(exit %d)\033[0m\n' "$?"

# ---------------------------------------------------------------------------

step 'Diff review — gate a change on security sensitivity'
printf '\033[2mgit diff | ./review-diff.sh -\033[0m\n\n'
printf 'diff --git a/auth.go b/auth.go\n--- a/auth.go\n+++ b/auth.go\n@@ -12,7 +12,7 @@ func login(u User) bool {\n-\tif u.Password == storedPassword {\n+\tif subtle.ConstantTimeCompare([]byte(u.Password), []byte(storedPassword)) == 1 {\n \t\treturn true\n \t}\n' \
    | ./review-diff.sh -
printf '\033[2m(exit %d — would fail the build)\033[0m\n' "$?"

# ---------------------------------------------------------------------------

step 'Diff review — a change that is not security-sensitive'
printf '\033[2mgit diff | ./review-diff.sh -\033[0m\n\n'
printf 'diff --git a/README.md b/README.md\n--- a/README.md\n+++ b/README.md\n@@ -1 +1 @@\n-# projct\n+# project\n' \
    | ./review-diff.sh -
printf '\033[2m(exit %d)\033[0m\n' "$?"

printf '\n\033[1mDone.\033[0m\n\n'

#!/bin/sh
#
# Run every example in turn.
#
#   examples/demo.sh
#
# Each area lives in its own directory with its own demo.sh; this just walks
# through them in order. Takes a few minutes, because every step is a real
# inference. Nothing outside this checkout is modified.
#
# To explore one area on its own:
#
#   examples/routing/demo.sh
#   examples/schema/demo.sh
#   examples/json/demo.sh
#   examples/workflows/demo.sh

set -u
cd "$(dirname "$0")" || exit 1

../bin/fmevent doctor || {
    printf '\nfmevent is not ready; fix the above first.\n'
    exit 1
}

for d in routing schema json workflows; do
    printf '\n\033[1m########## %s ##########\033[0m\n' "$d"
    "./$d/demo.sh" || printf '\033[2m(%s demo exited %d)\033[0m\n' "$d" "$?"
done

printf '\n\033[1mAll examples done.\033[0m See README.md for the full story.\n\n'

#!/bin/zsh
# Runs TripPickCore tests; prints errors and the summary only. Usage: scripts/core-test.sh [--filter X]
LOG="${TMPDIR:-/tmp}/trippick-core-test.log"
swift test --package-path "$(dirname $0)/../Packages/TripPickCore" "$@" > "$LOG" 2>&1
STATUS=$?
grep -E "error:|✘|failed|passed after|Test run with" "$LOG" | grep -v "^Failed frontend" | sed -E 's/^.*\/(Sources|Tests)\//\1\//' | head -40
exit $STATUS

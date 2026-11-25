#!/bin/zsh
# Builds the app for the iPhone 17 simulator; prints errors and the result only.
cd "$(dirname $0)/.."
LOG="${TMPDIR:-/tmp}/trippick-app-build.log"
xcodebuild -project TripPick.xcodeproj -scheme TripPick -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath .build/DerivedData build > "$LOG" 2>&1
STATUS=$?
grep -E "error:|BUILD (SUCCEEDED|FAILED)" "$LOG" | sort -u | head -40
exit $STATUS

#!/usr/bin/env bash
# Builds AuthUI, launches it in the iOS Simulator and runs the tests.
#   ./run_tests.sh            -> unit tests + UI tests
#   ./run_tests.sh unit       -> unit tests only (AuthUITests: stubbed + live API tests)
#   ./run_tests.sh ui         -> UI tests only (AuthUIUITests)
set -euo pipefail
cd "$(dirname "$0")"

SIM_NAME="${SIM_NAME:-$(xcrun simctl list devices available | grep -m1 -oE 'iPhone [0-9A-Za-z ]+' | sed 's/ *$//')}"
echo "Using simulator: $SIM_NAME"
DEST="platform=iOS Simulator,name=${SIM_NAME}"

ONLY=()
case "${1:-all}" in
  unit) ONLY=(-only-testing:AuthUITests) ;;
  ui)   ONLY=(-only-testing:AuthUIUITests) ;;
esac

xcodebuild test \
  -project AuthUI.xcodeproj \
  -scheme AuthUI \
  -destination "$DEST" \
  ${ONLY[@]+"${ONLY[@]}"} \
  -resultBundlePath build/TestResults.xcresult

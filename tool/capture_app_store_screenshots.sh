#!/usr/bin/env bash
# Builds a debug simulator app for each store shot, launches it on the booted
# simulator and saves a RAW screenshot (xcrun simctl io screenshot).
# No cropping, framing or editing. SHOWCASE is read by debug builds only
# (release ignores it); showcase mode uses in-memory sample data and never
# starts the ad SDK, so no ads appear.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-$HOME/Downloads/fuutou-screenshots-raw}"
DEV="${SIM_UDID:-booted}"
BUNDLE=jp.fuutouchokin.app
mkdir -p "$OUT"
xcrun simctl status_bar "$DEV" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 || true

shot() { # name scene
  local name=$1 scene=$2
  flutter build ios --simulator --debug --dart-define=SHOWCASE=$scene >/dev/null
  xcrun simctl terminate "$DEV" $BUNDLE 2>/dev/null || true
  xcrun simctl install "$DEV" build/ios/iphonesimulator/Runner.app
  xcrun simctl launch "$DEV" $BUNDLE >/dev/null
  sleep 14
  xcrun simctl io "$DEV" screenshot "$OUT/$name.png"
  sips -g pixelWidth -g pixelHeight "$OUT/$name.png" | tail -2
}

shot 01-envelopes board
shot 02-spend spend
shot 03-payday payday
shot 04-history history
echo "saved to $OUT"

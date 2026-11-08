#!/bin/bash
# Builds ObsidianAgenda.app (ad-hoc signed). Pass "install" to copy it to /Applications.
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
# Version comes from the VERSION file; the build number is the exact commit.
VERSION=$(tr -d '[:space:]' < VERSION)
COMMIT=$(git rev-parse --short HEAD)$(git diff --quiet HEAD -- Sources Package.swift VERSION || echo "-dirty")
APP=build/ObsidianAgenda.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/ObsidianAgenda "$APP/Contents/MacOS/ObsidianAgenda"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>app.obsidianagenda.ObsidianAgenda</string>
  <key>CFBundleName</key><string>ObsidianAgenda</string>
  <key>CFBundleExecutable</key><string>ObsidianAgenda</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>$COMMIT</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSCalendarsFullAccessUsageDescription</key>
  <string>ObsidianAgenda reads your meetings to remind you before they start and to open their Obsidian notes.</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
if [ "${1:-}" = "install" ]; then
  pkill -x ObsidianAgenda || true
  while pgrep -x ObsidianAgenda >/dev/null; do sleep 0.2; done
  rm -rf /Applications/ObsidianAgenda.app
  cp -R "$APP" /Applications/
  open /Applications/ObsidianAgenda.app
fi
echo "Built $APP (version $VERSION, build $COMMIT)"

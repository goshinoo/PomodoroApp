#!/bin/bash
set -e
cd "$(dirname "$0")"

APP="Pomodoro"
VERSION="1.1"
DMG="${APP}-${VERSION}.dmg"

echo "▶ Building..."
swift build -c release
cp .build/release/PomodoroApp ${APP}.app/Contents/MacOS/${APP}

echo "▶ Ad-hoc signing..."
codesign --force --deep --sign - ${APP}.app

echo "▶ Packaging DMG..."
STAGING=$(mktemp -d)
cp -r ${APP}.app "$STAGING/"
ln -s /Applications "$STAGING/Applications"

rm -f "$DMG"
hdiutil create \
    -volname "$APP" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    -o "$DMG"

rm -rf "$STAGING"
echo "✓ Created $DMG  ($(du -sh "$DMG" | cut -f1))"

#!/bin/bash
set -e
cd "$(dirname "$0")"

swift build -c release

cp .build/release/PomodoroApp Pomodoro.app/Contents/MacOS/Pomodoro
rm -rf /Applications/Pomodoro.app
cp -r Pomodoro.app /Applications/Pomodoro.app

echo "✓ Installed to /Applications"
open /Applications/Pomodoro.app

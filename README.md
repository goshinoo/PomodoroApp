# 🍅 Pomodoro

A minimal macOS Pomodoro timer built with Swift + SwiftUI.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **25 / 5 / 15 min** work and break cycles (fully customizable)
- **Menu bar** — live countdown always visible, control without opening the main window
- **Task tracking** — label what you're working on each session
- **Daily stats** — today's pomodoros, focus minutes, and streak days
- **History view** — browse past sessions grouped by day
- **System notifications + sound** on session complete
- **Runs in background** — closing the window keeps the timer going; click the Dock icon to bring it back

## Screenshots

<div align="center">
  <img src="screenshots/main.png" width="320" alt="Main window" />
  &nbsp;&nbsp;&nbsp;
  <img src="screenshots/settings.png" width="320" alt="Settings" />
</div>

## Build & Run

Requires Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/goshinoo/PomodoroApp.git
cd PomodoroApp
bash build_and_run.sh
```

This builds a release binary, installs it to `/Applications/Pomodoro.app`, and launches it.

## Package as DMG

```bash
bash make_dmg.sh
```

Produces `Pomodoro-1.0.dmg` with an ad-hoc signature. Recipients may need to right-click → Open the first time to bypass Gatekeeper.

## Project Structure

```
Sources/PomodoroApp/
├── PomodoroApp.swift      # App entry point, menu bar extra
├── TimerViewModel.swift   # Timer logic, persistence, stats
├── ContentView.swift      # Main window UI
├── MenuBarContent.swift   # Menu bar popover
├── HistoryView.swift      # Multi-day history sheet
└── SettingsView.swift     # Duration settings sheet
```

## Tech

- SwiftUI + AppKit on macOS 13+
- `UserDefaults` for per-day persistence
- `NSSound` for audio alerts
- `osascript` for system notifications
- Swift Package Manager (no dependencies)

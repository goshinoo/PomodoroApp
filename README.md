# 🍅 Pomodoro

A minimal macOS Pomodoro timer built with Swift + SwiftUI.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **25 / 5 / 15 min** work and break cycles (fully customizable)
- **Menu bar** — live countdown always visible, control without opening the main window
- **Task tracking** — label what you're working on; autocompletes from recent tasks
- **Auto-start** — optionally start the next session automatically after each transition
- **Accurate timer** — computed from wall-clock time, immune to system load and display sleep
- **Session continuity** — the 4-session break cycle (3 short → 1 long) persists across app restarts
- **Daily stats** — today's pomodoros, focus minutes, and streak days
- **History view** — 7-day bar chart + past sessions grouped by day
- **CSV export** — export all session data from the History view
- **System notifications + sound** on session complete
- **Runs in background** — closing the window keeps the timer going; click the Dock icon to bring it back
- **English / 中文** — language switcher in Settings

## Screenshots

<div align="center">
  <img src="screenshots/main.png" width="260" alt="Main window" />
  &nbsp;&nbsp;
  <img src="screenshots/settings.png" width="260" alt="Settings with Auto-start" />
  &nbsp;&nbsp;
  <img src="screenshots/history.png" width="260" alt="History with weekly chart" />
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

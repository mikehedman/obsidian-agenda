# ObsidianAgenda

A native macOS menu bar app that turns your Mac Calendar into an Obsidian daily agenda and gives you silent, escalating on-screen meeting reminders.

It replaces this repo's original Node.js script + launchd job. The old version is still available in the git history (everything before the Swift rewrite commit).

## Features

- **Daily agenda note**: writes `Today's Meetings.md` in your Obsidian vault from a Mac Calendar.
- **Escalating, silent reminders** on every monitor:
  - **T-5 min**: amber countdown in the menu bar.
  - **T-3 min**: banner.
  - **T-1 min**: flashing overlay that stays until clicked.
- **Open note**: jumps to the meeting's Obsidian page (creating it in the new-meetings folder if needed).
- **Login Item**: registers itself on first launch; toggle it from the app's menu.

## Requirements

- macOS 14 or later
- Swift 5.9+ toolchain (Xcode or Command Line Tools)
- Obsidian, with the vault on the same Mac

## Build and install

```bash
swift test               # run the core tests
./build-app.sh           # build build/ObsidianAgenda.app (ad hoc signed)
./build-app.sh install   # build, copy to /Applications, and launch
```

On first launch, grant **Calendar** access when prompted.

## Configuration

Click the menu bar icon and choose **Settings…** to pick the calendar (from a list of your actual calendars), the Obsidian vault folder, and the folder for new meeting notes.

The settings are stored with `defaults`, so you can also change them from Terminal, then restart the app:

```bash
defaults write app.obsidianagenda.ObsidianAgenda calendarName "Work"
defaults write app.obsidianagenda.ObsidianAgenda vaultPath "/path/to/vault"
defaults write app.obsidianagenda.ObsidianAgenda newMeetingsFolder "Work/Meetings"
```

| Key | Purpose | Default |
| --- | --- | --- |
| `calendarName` | Mac Calendar to read events from | `Calendar` |
| `vaultPath` | Obsidian vault path | `~/Documents/Obsidian` |
| `newMeetingsFolder` | Vault folder for new meeting notes | `Meetings` |

## Layout

```
Sources/ObsidianAgendaCore/   Meeting model and note generation (unit tested)
Sources/ObsidianAgenda/       App: calendar access, scheduler, alerts, Obsidian writer
Tests/                         Core tests
build-app.sh                   Builds, signs, and optionally installs the .app
```

## Migrating from the Node script

If you used the old Node script, retire its launchd job once the app is working:

```bash
launchctl bootout gui/$(id -u)/<your-job-label>
rm ~/Library/LaunchAgents/<your-job-label>.plist
```

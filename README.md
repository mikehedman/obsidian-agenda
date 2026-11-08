# ObsidianAgenda

A native macOS menu bar app that turns your Mac Calendar into an Obsidian daily agenda and gives you silent, escalating on-screen meeting reminders.

It replaces this repo's original Node.js script + launchd job. The old version is still available in the git history (everything before the Swift rewrite commit).

## Features

- **Daily agenda note**: writes `Today's Meetings.md` in your Obsidian vault from a Mac Calendar.
- **Escalating, silent reminders** on every monitor:
  - **T-5 min**: amber countdown in the menu bar.
  - **T-3 min**: banner.
  - **T-1 min**: the banner flashes and stays until clicked.
- **Open note**: jumps to the meeting's Obsidian page (creating it in the new-meetings folder if needed).
- **Join / Join + open note**: shown when the event has a Zoom, Teams, Google Meet, or Webex link (also inside Outlook Safe Links). Zoom and Teams links open straight in the app when it's installed.
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

Plain `./build-app.sh` does not touch the copy in `/Applications`; use `install` to update the running app.

## Versioning and releases

The app version comes from the `VERSION` file ([semantic versioning](https://semver.org)), and the build number is the short commit hash, with `-dirty` appended when `Sources/`, `Package.swift`, or `VERSION` have uncommitted changes. The menu shows both, e.g. **Version 1.2.0 (b853e40)**, so you can confirm which build is running.

Every change goes through a pull request, and the version bump is part of it:

```bash
git checkout -b my-change                  # never commit directly to main
# edit code, and bump VERSION: patch for fixes, minor for features, major for breaking changes
swift test
git commit -am "..."
git push -u origin my-change
gh pr create --fill                        # review, then merge on GitHub

git checkout main && git pull              # after the merge
./build-app.sh install                     # build, install to /Applications, and relaunch
```

Then check that the menu shows the new version and commit.

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
VERSION                        App version shown in the menu (bump it in each PR)
```

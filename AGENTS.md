# ObsidianAgenda

macOS menu bar app (Swift package): reads meetings via EventKit, shows escalating alerts, and opens (or creates) an Obsidian note named after each meeting. It also keeps a `Today's Meetings.md` agenda in the vault that links to those notes. It does not use Obsidian's Daily Notes. See README.md for build, layout, and release details.

## Rules

- Every change goes through a pull request. Never commit directly to `main`; create a branch first.
- Bump `VERSION` in every PR (semver: patch for fixes, minor for features, major for breaking changes). The menu shows this version, so an unbumped PR ships a build that looks like the previous release.
- Run `swift test` before committing. Put testable logic in `ObsidianAgendaCore` and add tests in `Tests/ObsidianAgendaCoreTests`.
- Keep README.md in sync when behavior, configuration, or the release process changes.

import Foundation

/// Defaults mirror the constants at the top of the old index.js.
/// Override with e.g. `defaults write app.obsidianagenda.ObsidianAgenda calendarName "Work"`.
enum Config {
    private static let defaults = UserDefaults.standard

    static var calendarName: String {
        get { defaults.string(forKey: "calendarName") ?? "Calendar" }
        set { defaults.set(newValue, forKey: "calendarName") }
    }
    static var vaultPath: String {
        get { defaults.string(forKey: "vaultPath") ?? NSHomeDirectory() + "/Documents/Obsidian" }
        set { defaults.set(newValue, forKey: "vaultPath") }
    }
    static var newMeetingsFolder: String {
        get { defaults.string(forKey: "newMeetingsFolder") ?? "Meetings" }
        set { defaults.set(newValue, forKey: "newMeetingsFolder") }
    }
    static var vaultURL: URL { URL(fileURLWithPath: vaultPath) }
    static var vaultName: String { vaultURL.lastPathComponent }
}

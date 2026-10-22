import Foundation

/// Defaults mirror the constants at the top of the old index.js.
/// Override with e.g. `defaults write app.meetingreminder.MeetingReminder calendarName "Work"`.
enum Config {
    private static let defaults = UserDefaults.standard

    static var calendarName: String { defaults.string(forKey: "calendarName") ?? "Calendar" }
    static var vaultPath: String {
        defaults.string(forKey: "vaultPath") ?? NSHomeDirectory() + "/Documents/Obsidian"
    }
    static var newMeetingsFolder: String {
        defaults.string(forKey: "newMeetingsFolder") ?? "Meetings"
    }
    static var vaultURL: URL { URL(fileURLWithPath: vaultPath) }
    static var vaultName: String { vaultURL.lastPathComponent }
}

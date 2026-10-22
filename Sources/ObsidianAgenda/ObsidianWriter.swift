import Foundation
import ObsidianAgendaCore

/// Writes "Today's Meetings.md" and resolves the note to open for a meeting.
final class ObsidianWriter {
    private(set) var noteNames = Set<String>()

    /// Rescans the vault and rewrites the daily note. Call off the main thread.
    func write(meetings: [Meeting]) {
        noteNames = Notes.scanVault(Config.vaultURL)
        let text = Notes.render(day: Calendar.current.startOfDay(for: Date()), meetings: meetings,
                                noteNames: noteNames, newMeetingsFolder: Config.newMeetingsFolder,
                                generatedAt: Date())
        let file = Config.vaultURL.appendingPathComponent(Notes.dailyNoteTitle)
        do {
            try text.write(to: file, atomically: true, encoding: .utf8)
        } catch {
            NSLog("Error writing \(file.path): \(error)")
        }
    }

    func noteURL(for meeting: Meeting) -> URL? {
        Notes.openURL(vaultName: Config.vaultName, meetingTitle: meeting.title,
                      noteNames: noteNames, newMeetingsFolder: Config.newMeetingsFolder)
    }
}

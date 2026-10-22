import EventKit
import ObsidianAgendaCore

final class CalendarService {
    private let store = EKEventStore()
    private(set) var problem: String?

    func requestAccess() async -> Bool {
        let granted = (try? await store.requestFullAccessToEvents()) ?? false
        if !granted { problem = "Calendar access denied (System Settings > Privacy > Calendars)" }
        return granted
    }

    func observeChanges(_ handler: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main) { _ in handler() }
    }

    /// Titles of every event calendar, for the settings picker.
    func calendarTitles() -> [String] {
        var seen = Set<String>()
        return store.calendars(for: .event).map(\.title).filter { seen.insert($0).inserted }.sorted()
    }

    func todaysMeetings() -> [Meeting] {
        let calendars = store.calendars(for: .event).filter { $0.title == Config.calendarName }
        guard !calendars.isEmpty else {
            // Keep the menu message short; the full calendar list goes to the log only.
            let all = store.calendars(for: .event)
            let names = all.map { "\($0.title) [\($0.source.title)]" }.joined(separator: ", ")
            NSLog("ObsidianAgenda: no calendar named \"\(Config.calendarName)\" (access: \(EKEventStore.authorizationStatus(for: .event).rawValue), \(all.count) visible: \(names))")
            problem = "Calendar \"\(Config.calendarName)\" not found"
            return []
        }
        problem = nil
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay && $0.status != .canceled && !isDeclined($0) }
            .sorted { $0.startDate < $1.startDate }
            .map {
                Meeting(id: "\($0.eventIdentifier ?? $0.title ?? "event")-\($0.startDate.timeIntervalSince1970)",
                        title: $0.title ?? "(No title)", start: $0.startDate, end: $0.endDate)
            }
    }

    private func isDeclined(_ event: EKEvent) -> Bool {
        event.attendees?.first(where: { $0.isCurrentUser })?.participantStatus == .declined
    }
}

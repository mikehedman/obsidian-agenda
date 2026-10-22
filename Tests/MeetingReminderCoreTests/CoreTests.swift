import XCTest
@testable import MeetingReminderCore

final class CoreTests: XCTestCase {
    func testCleanTitle() {
        XCTAssertEqual(cleanTitle("a/b\\c:d[e]f|g"), "a-b-c-d-e-f-g")
        XCTAssertEqual(cleanTitle("Standup"), "Standup")
    }

    func testStages() {
        XCTAssertEqual(AlertStage.stage(timeToStart: 6 * 60), .none)
        XCTAssertEqual(AlertStage.stage(timeToStart: 5 * 60), .countdown)
        XCTAssertEqual(AlertStage.stage(timeToStart: 3 * 60), .banner)
        XCTAssertEqual(AlertStage.stage(timeToStart: 60), .overlay)
        XCTAssertEqual(AlertStage.stage(timeToStart: 0), .none)
        XCTAssertEqual(AlertStage.stage(timeToStart: 50, timeScale: 1.0 / 6), .countdown)
        XCTAssertEqual(AlertStage.stage(timeToStart: 10, timeScale: 1.0 / 6), .overlay)
    }

    func testNoteWindow() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        func date(_ d: Int, _ h: Int) -> Date {  // Oct 2026: 18th is a Sunday
            cal.date(from: DateComponents(year: 2026, month: 10, day: 18 + d, hour: h))!
        }
        XCTAssertFalse(Notes.isNoteWindowOpen(date(0, 11), calendar: cal))  // Sunday morning
        XCTAssertTrue(Notes.isNoteWindowOpen(date(0, 12), calendar: cal))
        XCTAssertTrue(Notes.isNoteWindowOpen(date(2, 9), calendar: cal))
        XCTAssertFalse(Notes.isNoteWindowOpen(date(2, 19), calendar: cal))
        XCTAssertFalse(Notes.isNoteWindowOpen(date(2, 3), calendar: cal))
        XCTAssertFalse(Notes.isNoteWindowOpen(date(5, 18), calendar: cal))  // Friday 6pm
        XCTAssertFalse(Notes.isNoteWindowOpen(date(6, 10), calendar: cal))  // Saturday
    }

    func testRenderAndOpenURL() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let meetings = [Meeting(id: "1", title: "Plan: Q4", start: start, end: start.addingTimeInterval(3600)),
                        Meeting(id: "2", title: "Known", start: start, end: start.addingTimeInterval(1800))]
        let text = Notes.render(day: start, meetings: meetings, noteNames: ["Known"],
                                newMeetingsFolder: "Work/Meetings", generatedAt: start)
        XCTAssertTrue(text.contains("**[[Work/Meetings/Plan- Q4|Plan- Q4]]**"))
        XCTAssertTrue(text.contains("**[[Known]]**"))
        XCTAssertTrue(text.hasPrefix("# Calendar Events for "))
        XCTAssertTrue(Notes.render(day: start, meetings: [], noteNames: [], newMeetingsFolder: "x",
                                   generatedAt: start).contains("No meetings today!"))

        let open = Notes.openURL(vaultName: "My Vault", meetingTitle: "Known", noteNames: ["Known"], newMeetingsFolder: "W")
        XCTAssertEqual(open?.host, "open")
        let new = Notes.openURL(vaultName: "My Vault", meetingTitle: "Other", noteNames: [], newMeetingsFolder: "W")
        XCTAssertEqual(new?.host, "new")
        XCTAssertTrue(new?.absoluteString.contains("vault=My%20Vault") ?? false)
    }
}

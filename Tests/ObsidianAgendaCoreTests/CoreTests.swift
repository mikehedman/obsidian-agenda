import XCTest
@testable import ObsidianAgendaCore

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

    func testMeetingLinks() {
        let teams = "https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc%40thread.v2/0?context=%7b%22Tid%22%3a%221%22%7d"
        let notes = """
        Agenda: https://example.com/doc
        ________________________________________________________________________________
        Microsoft Teams meeting
        Join on your computer, mobile app or room device
        Click here to join the meeting<\(teams)>
        """
        XCTAssertEqual(MeetingLink.find(in: [nil, "Conf Room 4", notes])?.absoluteString, teams)
        XCTAssertEqual(MeetingLink.nativeURL(for: URL(string: teams)!)?.absoluteString,
                       "msteams:/l/meetup-join/19%3ameeting_abc%40thread.v2/0?context=%7b%22Tid%22%3a%221%22%7d")

        let zoom = MeetingLink.find(in: ["https://acme.zoom.us/j/81234567890?pwd=AbC123.1", nil])
        XCTAssertEqual(zoom?.absoluteString, "https://acme.zoom.us/j/81234567890?pwd=AbC123.1")
        XCTAssertEqual(MeetingLink.nativeURL(for: zoom!)?.absoluteString,
                       "zoommtg://acme.zoom.us/join?action=join&confno=81234567890&pwd=AbC123.1")

        let safe = "https://nam12.safelinks.protection.outlook.com/?url=https%3A%2F%2Fmeet.google.com%2Fabc-defg-hij&data=x"
        XCTAssertEqual(MeetingLink.find(in: ["See " + safe])?.absoluteString, "https://meet.google.com/abc-defg-hij")
        XCTAssertNil(MeetingLink.nativeURL(for: URL(string: "https://meet.google.com/abc-defg-hij")!))

        XCTAssertNil(MeetingLink.find(in: ["https://zoom.us/pricing", "https://example.com", nil]))
    }
}

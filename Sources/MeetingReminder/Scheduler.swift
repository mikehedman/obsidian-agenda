import AppKit
import ServiceManagement
import MeetingReminderCore

/// Owns the meeting list, the menu bar item, and drives alert stages.
final class Scheduler: NSObject, NSMenuDelegate {
    private let calendar = CalendarService()
    private let writer = ObsidianWriter()
    private let alerts = AlertController()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    private var meetings: [Meeting] = []
    private var testMeeting: Meeting?
    private var dismissed = Set<String>()
    private var stickyOverlay: Meeting?
    private var alertingMeeting: Meeting?
    private var lastWrite = Date.distantPast
    private var loadedDay = Calendar.current.startOfDay(for: Date())

    func start() {
        statusItem.button?.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Meetings")
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        alerts.onDismiss = { [weak self] meeting in self?.dismiss(meeting) }
        alerts.onOpenNote = { [weak self] meeting in
            if let url = self?.writer.noteURL(for: meeting) { NSWorkspace.shared.open(url) }
        }
        registerLoginItemIfNeeded()

        calendar.observeChanges { [weak self] in self?.refresh() }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
        Task { @MainActor in
            if await calendar.requestAccess() { refresh() } else { updateStatus(now: Date(), next: nil) }
        }
        let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer, forMode: .common)
    }

    func refresh() {
        meetings = calendar.todaysMeetings()
        loadedDay = Calendar.current.startOfDay(for: Date())
        let snapshot = meetings
        if Notes.isNoteWindowOpen(Date()) {
            lastWrite = Date()
            DispatchQueue.global(qos: .utility).async { [writer] in writer.write(meetings: snapshot) }
        }
        tick()
    }

    func startTestAlert() {
        let start = Date().addingTimeInterval(50)
        testMeeting = Meeting(id: "test", title: "Test meeting", start: start,
                              end: start.addingTimeInterval(1800), timeScale: 1.0 / 6)
        dismissed.remove("test")
        stickyOverlay = nil
        tick()
    }

    private func dismiss(_ meeting: Meeting) {
        dismissed.insert(meeting.id)
        if stickyOverlay?.id == meeting.id { stickyOverlay = nil }
        if testMeeting?.id == meeting.id { testMeeting = nil }
        alerts.clear()
        tick()
    }

    private func tick() {
        let now = Date()
        if Calendar.current.startOfDay(for: now) != loadedDay || now.timeIntervalSince(lastWrite) > 3600 {
            refresh()
            return
        }
        let all = meetings + (testMeeting.map { [$0] } ?? [])
        let live = all.filter { !dismissed.contains($0.id) }

        if let sticky = stickyOverlay, now >= sticky.end || dismissed.contains(sticky.id) { stickyOverlay = nil }

        var current: (Meeting, AlertStage)? = stickyOverlay.map { ($0, .overlay) }
        if current == nil {
            for meeting in live {
                let stage = AlertStage.stage(timeToStart: meeting.start.timeIntervalSince(now),
                                             timeScale: meeting.timeScale)
                if stage > (current?.1 ?? .none) { current = (meeting, stage) }
            }
        }
        if let (meeting, stage) = current, stage == .overlay { stickyOverlay = meeting }

        alertingMeeting = current?.0
        let next = live.filter { $0.start > now }.min { $0.start < $1.start }
        updateStatus(now: now, next: current?.0 ?? next, stage: current?.1 ?? .none)
        if let (meeting, stage) = current { alerts.show(stage: stage, meeting: meeting, now: now) } else { alerts.clear() }
    }

    private func updateStatus(now: Date, next: Meeting?, stage: AlertStage = .none) {
        guard let button = statusItem.button else { return }
        guard let next, stage != .none else {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Meetings")
            button.attributedTitle = NSAttributedString(string: "")
            return
        }
        // The menu bar ignores text/tint colors, so draw a colored pill ourselves.
        let minutes = Int(max(0, next.start.timeIntervalSince(now)) / 60) + 1
        let text = "\(next.title.prefix(24)) \(minutes)m" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white, .font: NSFont.boldSystemFont(ofSize: 13)]
        let textSize = text.size(withAttributes: attrs)
        let size = NSSize(width: ceil(textSize.width) + 16, height: 20)
        let fill: NSColor = stage == .countdown ? .systemOrange : .systemRed
        let image = NSImage(size: size, flipped: false) { rect in
            fill.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).fill()
            text.draw(at: NSPoint(x: 8, y: (rect.height - textSize.height) / 2), withAttributes: attrs)
            return true
        }
        image.isTemplate = false
        button.image = image
        button.attributedTitle = NSAttributedString(string: "")
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let now = Date()
        if let alerting = alertingMeeting {
            addItem(menu, "Dismiss alert: \(alerting.title.prefix(30))", #selector(dismissAlerting))
            menu.addItem(.separator())
        }
        if let problem = calendar.problem {
            menu.addItem(withTitle: problem, action: nil, keyEquivalent: "").isEnabled = false
        } else if let next = meetings.first(where: { $0.start > now && !dismissed.contains($0.id) }) {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            menu.addItem(withTitle: "Next: \(next.title) at \(f.string(from: next.start))", action: nil,
                         keyEquivalent: "").isEnabled = false
        } else {
            menu.addItem(withTitle: "No more meetings today", action: nil, keyEquivalent: "").isEnabled = false
        }
        menu.addItem(.separator())
        addItem(menu, "Refresh now", #selector(refreshClicked))
        addItem(menu, "Test alert", #selector(testClicked))
        let status = SMAppService.mainApp.status
        if status == .requiresApproval {
            addItem(menu, "Approve in Login Items…", #selector(openLoginItems))
        } else {
            let item = addItem(menu, "Launch at login", #selector(toggleLogin))
            item.state = status == .enabled ? .on : .off
        }
        menu.addItem(.separator())
        addItem(menu, "Quit", #selector(quit))
    }

    @discardableResult
    private func addItem(_ menu: NSMenu, _ title: String, _ action: Selector) -> NSMenuItem {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    /// Left click dismisses an active alert; otherwise (or on right click) show the menu.
    @objc private func statusClicked() {
        let rightClick = NSApp.currentEvent?.type == .rightMouseUp
        if let alerting = alertingMeeting, !rightClick {
            dismiss(alerting)
            return
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func dismissAlerting() { if let m = alertingMeeting { dismiss(m) } }
    @objc private func refreshClicked() { refresh() }
    @objc private func testClicked() { startTestAlert() }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func openLoginItems() { SMAppService.openSystemSettingsLoginItems() }

    @objc private func toggleLogin() {
        let defaults = UserDefaults.standard
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
            defaults.set(true, forKey: "loginItemDisabledByUser")
        } else {
            try? SMAppService.mainApp.register()
            defaults.set(false, forKey: "loginItemDisabledByUser")
        }
    }

    private func registerLoginItemIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "loginItemDisabledByUser"),
              SMAppService.mainApp.status == .notRegistered else { return }
        do { try SMAppService.mainApp.register() } catch { NSLog("Login item registration failed: \(error)") }
    }
}

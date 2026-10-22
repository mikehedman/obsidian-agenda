import AppKit
import MeetingReminderCore

/// Click-anywhere view used by banner and overlay windows.
final class ClickView: NSView {
    var onClick: (() -> Void)?
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { onClick?() }
}

final class AlertPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Shows the banner (T-3) and flashing overlay (T-1) on every screen.
final class AlertController {
    var onDismiss: ((Meeting) -> Void)?
    var onOpenNote: ((Meeting) -> Void)?

    private struct Entry {
        let panel: AlertPanel
        let countdown: NSTextField
        let background: NSView
    }

    private var entries: [Entry] = []
    private var shownStage = AlertStage.none
    private var shownMeeting: Meeting?
    private var flashTimer: Timer?
    private var flashOn = false

    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
                guard let self, let meeting = self.shownMeeting else { return }
                let stage = self.shownStage
                self.clear()
                self.show(stage: stage, meeting: meeting, now: Date())
            }
    }

    func show(stage: AlertStage, meeting: Meeting, now: Date) {
        guard stage >= .banner else { clear(); return }
        if stage != shownStage || meeting != shownMeeting { clear(); build(stage: stage, meeting: meeting) }
        let text = Self.countdownText(meeting.start.timeIntervalSince(now))
        entries.forEach { $0.countdown.stringValue = text }
    }

    func clear() {
        flashTimer?.invalidate()
        flashTimer = nil
        entries.forEach { $0.panel.orderOut(nil) }
        entries = []
        shownStage = .none
        shownMeeting = nil
    }

    static func countdownText(_ seconds: TimeInterval) -> String {
        if seconds <= 0 {
            let ago = Int(-seconds)
            return ago < 5 ? "Starting now" : String(format: "Started %d:%02d ago", ago / 60, ago % 60)
        }
        let s = Int(seconds.rounded(.up))
        return String(format: "Starts in %d:%02d", s / 60, s % 60)
    }

    private func build(stage: AlertStage, meeting: Meeting) {
        shownStage = stage
        shownMeeting = meeting
        let overlay = stage == .overlay
        for screen in NSScreen.screens {
            let frame = overlay ? screen.frame : Self.bannerFrame(on: screen)
            let panel = AlertPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                                   backing: .buffered, defer: false)
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .screenSaver
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

            let background = ClickView(frame: NSRect(origin: .zero, size: frame.size))
            background.wantsLayer = true
            background.layer?.backgroundColor = (overlay ? NSColor.systemRed : NSColor.systemOrange)
                .withAlphaComponent(0.92).cgColor
            background.layer?.cornerRadius = overlay ? 0 : 18
            background.onClick = { [weak self] in self?.onDismiss?(meeting) }
            panel.contentView = background

            let title = Self.label(meeting.title, size: overlay ? 72 : 28, weight: .bold)
            let countdown = Self.label("", size: overlay ? 44 : 20, weight: .medium)
            let button = NSButton(title: "Open note", target: nil, action: nil)
            button.bezelStyle = .rounded
            button.controlSize = overlay ? .large : .regular
            let stack = NSStackView(views: [title, countdown, button])
            stack.orientation = .vertical
            stack.spacing = overlay ? 24 : 8
            stack.translatesAutoresizingMaskIntoConstraints = false
            background.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: background.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: background.centerYAnchor),
                stack.widthAnchor.constraint(lessThanOrEqualTo: background.widthAnchor, constant: -40),
            ])
            let handler = ButtonHandler { [weak self] in self?.onOpenNote?(meeting) }
            button.target = handler
            button.action = #selector(ButtonHandler.fire)
            objc_setAssociatedObject(button, &ButtonHandler.key, handler, .OBJC_ASSOCIATION_RETAIN)

            panel.orderFrontRegardless()
            entries.append(Entry(panel: panel, countdown: countdown, background: background))
        }
        if overlay { startFlashing() }
    }

    private func startFlashing() {
        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.flashOn.toggle()
            let color = (self.flashOn ? NSColor.systemOrange : NSColor.systemRed).withAlphaComponent(0.92)
            self.entries.forEach { $0.background.layer?.backgroundColor = color.cgColor }
        }
    }

    private static func bannerFrame(on screen: NSScreen) -> NSRect {
        let size = NSSize(width: 560, height: 150)
        let f = screen.visibleFrame
        return NSRect(x: f.midX - size.width / 2, y: f.maxY - size.height - 40, width: size.width, height: size.height)
    }

    private static func label(_ text: String, size: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: size, weight: weight)
        field.textColor = .white
        field.alignment = .center
        field.lineBreakMode = .byTruncatingTail
        return field
    }
}

private final class ButtonHandler: NSObject {
    static var key = 0
    let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    @objc func fire() { action() }
}

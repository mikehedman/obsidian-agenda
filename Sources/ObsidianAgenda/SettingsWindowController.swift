import AppKit

/// Small settings window: pick the calendar, the Obsidian vault, and the new-meetings folder.
final class SettingsWindowController: NSWindowController {
    private let calendarPopUp = NSPopUpButton(frame: .zero, pullsDown: false)
    private let vaultField = NSTextField()
    private let folderField = NSTextField()
    private let calendarTitles: () -> [String]
    private let onSave: () -> Void

    init(calendarTitles: @escaping () -> [String], onSave: @escaping () -> Void) {
        self.calendarTitles = calendarTitles
        self.onSave = onSave
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 180),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "ObsidianAgenda Settings"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildContent(in: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func present() {
        loadValues()
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    // MARK: Layout

    private func buildContent(in window: NSWindow) {
        vaultField.placeholderString = "/path/to/your/vault"
        folderField.placeholderString = "Meetings"
        vaultField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let chooseButton = NSButton(title: "Choose…", target: self, action: #selector(chooseVault))
        let vaultRow = NSStackView(views: [vaultField, chooseButton])
        vaultRow.spacing = 8

        let grid = NSGridView(views: [
            [label("Calendar:"), calendarPopUp],
            [label("Obsidian vault:"), vaultRow],
            [label("New meetings folder:"), folderField],
        ])
        grid.rowSpacing = 12
        grid.columnSpacing = 10
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).xPlacement = .fill
        grid.translatesAutoresizingMaskIntoConstraints = false

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancel.keyEquivalent = "\u{1b}"
        let save = NSButton(title: "Save", target: self, action: #selector(saveClicked))
        save.keyEquivalent = "\r"
        let buttons = NSStackView(views: [cancel, save])
        buttons.spacing = 8
        buttons.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(grid)
        content.addSubview(buttons)
        window.contentView = content
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            buttons.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 20),
            buttons.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            buttons.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalToConstant: 520),
        ])
    }

    private func label(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.alignment = .right
        return field
    }

    // MARK: Values

    private func loadValues() {
        var titles = calendarTitles()
        if !titles.contains(Config.calendarName) { titles.insert(Config.calendarName, at: 0) }
        calendarPopUp.removeAllItems()
        calendarPopUp.addItems(withTitles: titles)
        calendarPopUp.selectItem(withTitle: Config.calendarName)
        vaultField.stringValue = Config.vaultPath
        folderField.stringValue = Config.newMeetingsFolder
    }

    @objc private func chooseVault() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.prompt = "Choose"
        panel.directoryURL = URL(fileURLWithPath: vaultField.stringValue)
        if panel.runModal() == .OK, let url = panel.url { vaultField.stringValue = url.path }
    }

    @objc private func saveClicked() {
        if let title = calendarPopUp.titleOfSelectedItem { Config.calendarName = title }
        let vault = vaultField.stringValue.trimmingCharacters(in: .whitespaces)
        if !vault.isEmpty { Config.vaultPath = vault }
        let folder = folderField.stringValue.trimmingCharacters(in: .whitespaces)
        if !folder.isEmpty { Config.newMeetingsFolder = folder }
        window?.close()
        onSave()
    }

    @objc private func cancelClicked() { window?.close() }
}

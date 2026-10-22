// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MeetingReminder",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MeetingReminderCore"),
        .executableTarget(name: "MeetingReminder", dependencies: ["MeetingReminderCore"]),
        .testTarget(name: "MeetingReminderCoreTests", dependencies: ["MeetingReminderCore"]),
    ]
)

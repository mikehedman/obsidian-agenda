// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ObsidianAgenda",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "ObsidianAgendaCore"),
        .executableTarget(name: "ObsidianAgenda", dependencies: ["ObsidianAgendaCore"]),
        .testTarget(name: "ObsidianAgendaCoreTests", dependencies: ["ObsidianAgendaCore"]),
    ]
)

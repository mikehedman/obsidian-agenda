import Foundation

public struct Meeting: Equatable {
    public let id: String
    public let title: String
    public let start: Date
    public let end: Date
    /// 1 = real time. Smaller values compress the alert stages (used by "Test alert").
    public let timeScale: Double

    public init(id: String, title: String, start: Date, end: Date, timeScale: Double = 1) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.timeScale = timeScale
    }
}

public enum AlertStage: Int, Comparable {
    case none, countdown, banner, overlay

    public static func < (a: AlertStage, b: AlertStage) -> Bool { a.rawValue < b.rawValue }

    /// T-5 min: countdown in the menu bar, T-3: banner on every screen, T-1: the banner flashes on every screen until clicked.
    public static func stage(timeToStart: TimeInterval, timeScale: Double = 1) -> AlertStage {
        if timeToStart <= 0 { return .none }
        let minutes = timeToStart / (60 * timeScale)
        if minutes <= 1 { return .overlay }
        if minutes <= 3 { return .banner }
        if minutes <= 5 { return .countdown }
        return .none
    }
}

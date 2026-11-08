import Foundation

/// Finds Zoom / Teams / Google Meet / Webex join links in calendar event text.
public enum MeetingLink {
    /// First video-meeting link found, searching the sources in order (e.g. URL, location, notes).
    public static func find(in sources: [String?]) -> URL? {
        for case let text? in sources {
            for candidate in urls(in: text) {
                let url = unwrapSafeLink(candidate)
                if isMeetingLink(url) { return url }
            }
        }
        return nil
    }

    /// App-scheme URL that skips the browser hop (zoommtg:, msteams:), or nil if there isn't one.
    public static func nativeURL(for url: URL) -> URL? {
        guard let host = url.host?.lowercased(),
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let path = comps.path
        if isZoom(host), path.hasPrefix("/j/") {
            let id = path.dropFirst(3).prefix { $0.isNumber }
            guard !id.isEmpty else { return nil }
            var out = URLComponents()
            out.scheme = "zoommtg"
            out.host = host
            out.path = "/join"
            out.queryItems = [URLQueryItem(name: "action", value: "join"), URLQueryItem(name: "confno", value: String(id))]
                + (comps.queryItems ?? []).filter { $0.name == "pwd" }
            return out.url
        }
        if host == "teams.microsoft.com", path.hasPrefix("/l/meetup-join/") {
            let rest = url.absoluteString.components(separatedBy: "teams.microsoft.com").dropFirst().joined()
            return URL(string: "msteams:" + rest)
        }
        return nil
    }

    static func isMeetingLink(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http",
              let host = url.host?.lowercased() else { return false }
        let path = url.path
        if isZoom(host) { return ["/j/", "/my/", "/w/", "/s/", "/wc/"].contains { path.hasPrefix($0) } }
        if host == "teams.microsoft.com" || host == "teams.live.com" {
            return path.hasPrefix("/l/meetup-join/") || path.hasPrefix("/meet/")
        }
        if host == "meet.google.com" { return path.count > 1 }
        if host.hasSuffix(".webex.com") { return path.count > 1 }
        return false
    }

    private static func isZoom(_ host: String) -> Bool {
        ["zoom.us", "zoom.com", "zoomgov.com"].contains { host == $0 || host.hasSuffix("." + $0) }
    }

    /// Outlook rewrites links as https://*.safelinks.protection.outlook.com/?url=<real link>&...
    private static func unwrapSafeLink(_ url: URL) -> URL {
        guard url.host?.lowercased().hasSuffix("safelinks.protection.outlook.com") == true,
              let inner = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "url" })?.value,
              let real = URL(string: inner) else { return url }
        return real
    }

    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    private static func urls(in text: String) -> [URL] {
        guard let detector else { return [] }
        return detector.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap(\.url)
    }
}

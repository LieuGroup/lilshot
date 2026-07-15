import Foundation
import LilshotCore

enum CaptureOutputPath {
    static func `default`(for window: WindowInfo, now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: now)
        let slug = slugify(window.appName)
        let desktop = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop", isDirectory: true)
        return desktop.appendingPathComponent("lilshot-\(slug)-\(stamp).png").path
    }

    private static func slugify(_ appName: String) -> String {
        let folded = appName
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
        let allowed = CharacterSet.alphanumerics
        var slug = ""
        var pendingDash = false
        for scalar in folded.unicodeScalars {
            if allowed.contains(scalar) {
                if pendingDash, !slug.isEmpty {
                    slug.append("-")
                }
                slug.append(Character(scalar))
                pendingDash = false
            } else {
                pendingDash = true
            }
        }
        return slug.isEmpty ? "window" : slug
    }
}

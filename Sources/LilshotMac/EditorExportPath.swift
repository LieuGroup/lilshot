import Foundation

/// Desktop PNG path using the same `lilshot-…-yyyyMMdd-HHmmss.png` pattern as CLI.
public enum EditorExportPath {
    public static func desktopPNG(label: String = "edit") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: Date())
        let slug = slugify(label)
        let desktop = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop", isDirectory: true)
        return desktop.appendingPathComponent("lilshot-\(slug)-\(stamp).png").path
    }

    private static func slugify(_ raw: String) -> String {
        let folded = raw
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
        return slug.isEmpty ? "edit" : slug
    }
}

import Foundation

/// Pure formatting for partial hotkey registration failures (testable without Carbon).
public enum HotkeyFailureFormatting {
    public static func summary(labelsAndStatuses: [(label: String, status: Int32)]) -> String {
        guard !labelsAndStatuses.isEmpty else { return "" }
        let parts = labelsAndStatuses.map { "\($0.label) (OSStatus \($0.status))" }
        return "hotkey registration partial failure: " + parts.joined(separator: ", ")
    }
}

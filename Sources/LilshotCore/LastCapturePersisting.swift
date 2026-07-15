import Foundation

/// Injected get/set seam for last-capture persistence (UserDefaults in app, mock in tests).
public protocol LastCapturePersisting: Sendable {
    func integer(forKey key: String) -> Int?
    func string(forKey key: String) -> String?
    func set(_ value: Int?, forKey key: String)
    func set(_ value: String?, forKey key: String)
}

public enum LastCapturePersistenceKey {
    public static let windowID = "lilshot.lastCapture.windowID"
    public static let appName = "lilshot.lastCapture.appName"
}

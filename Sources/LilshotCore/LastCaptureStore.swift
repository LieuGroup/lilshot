import Foundation

/// In-memory record of the last successful picker capture (window ID + app name).
public struct LastCapture: Equatable, Sendable {
    public let windowID: UInt32
    public let appName: String

    public init(windowID: UInt32, appName: String) {
        self.windowID = windowID
        self.appName = appName
    }
}

/// Survives only for the process lifetime; cleared explicitly or overwritten on next capture.
public struct LastCaptureStore: Equatable, Sendable {
    public private(set) var current: LastCapture?

    public init(current: LastCapture? = nil) {
        self.current = current
    }

    public mutating func remember(windowID: UInt32, appName: String) {
        current = LastCapture(windowID: windowID, appName: appName)
    }

    public mutating func clear() {
        current = nil
    }
}

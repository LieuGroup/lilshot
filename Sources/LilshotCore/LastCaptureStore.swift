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

/// Holds the last capture; optionally mirrors to an injected persistence seam.
public struct LastCaptureStore: Equatable, Sendable {
    public private(set) var current: LastCapture?
    private let persistence: (any LastCapturePersisting)?

    public init(
        current: LastCapture? = nil,
        persistence: (any LastCapturePersisting)? = nil
    ) {
        self.persistence = persistence
        if let current {
            self.current = current
        } else if let persistence {
            self.current = Self.load(from: persistence)
        } else {
            self.current = nil
        }
    }

    public mutating func remember(windowID: UInt32, appName: String) {
        current = LastCapture(windowID: windowID, appName: appName)
        persistCurrent()
    }

    public mutating func clear() {
        current = nil
        persistCurrent()
    }

    private func persistCurrent() {
        guard let persistence else { return }
        if let current {
            persistence.set(Int(current.windowID), forKey: LastCapturePersistenceKey.windowID)
            persistence.set(current.appName, forKey: LastCapturePersistenceKey.appName)
        } else {
            persistence.set(nil as Int?, forKey: LastCapturePersistenceKey.windowID)
            persistence.set(nil as String?, forKey: LastCapturePersistenceKey.appName)
        }
    }

    private static func load(from persistence: any LastCapturePersisting) -> LastCapture? {
        guard
            let rawID = persistence.integer(forKey: LastCapturePersistenceKey.windowID),
            rawID >= 0,
            let appName = persistence.string(forKey: LastCapturePersistenceKey.appName),
            !appName.isEmpty
        else {
            return nil
        }
        return LastCapture(windowID: UInt32(rawID), appName: appName)
    }

    public static func == (lhs: LastCaptureStore, rhs: LastCaptureStore) -> Bool {
        lhs.current == rhs.current
    }
}

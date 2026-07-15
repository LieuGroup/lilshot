import Foundation
import ScreenCaptureKit

/// Caches the last `SCShareableContent` fetch so capture paths avoid a
/// 100–500ms system-wide enumeration on every window lookup.
public actor ShareableContentCache {
    public static let shared = ShareableContentCache()

    private let maxAge: TimeInterval
    private var content: SCShareableContent?
    private var fetchedAt: Date?

    public init(maxAge: TimeInterval = 3.0) {
        self.maxAge = maxAge
    }

    /// Returns the window with `id`, reusing a warm cache when it still contains that id.
    public func window(for id: UInt32) async throws -> SCWindow {
        if let cached = warmContent(),
           let window = cached.windows.first(where: { $0.windowID == id }) {
            return window
        }
        let fresh = try await fetch()
        guard let window = fresh.windows.first(where: { $0.windowID == id }) else {
            throw ShareableContentCacheError.windowNotFound(id)
        }
        return window
    }

    /// Full shareable content for listing; reuses cache while younger than `maxAge`.
    public func shareableContent() async throws -> SCShareableContent {
        if let cached = warmContent() {
            return cached
        }
        return try await fetch()
    }

    private func warmContent() -> SCShareableContent? {
        guard let content, let fetchedAt,
              Date().timeIntervalSince(fetchedAt) < maxAge else {
            return nil
        }
        return content
    }

    private func fetch() async throws -> SCShareableContent {
        let fresh = try await SCShareableContent.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: false
        )
        content = fresh
        fetchedAt = Date()
        return fresh
    }
}

public enum ShareableContentCacheError: LocalizedError {
    case windowNotFound(UInt32)

    public var errorDescription: String? {
        switch self {
        case .windowNotFound(let id):
            return "No window found with ID \(id)"
        }
    }
}

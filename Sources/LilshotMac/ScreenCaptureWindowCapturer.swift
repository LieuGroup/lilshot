import AppKit
import CoreGraphics
import Foundation
import LilshotCore
import ScreenCaptureKit

public struct ScreenCaptureWindowCapturer: WindowCapturing {
    private let cache: ShareableContentCache

    public init(cache: ShareableContentCache = .shared) {
        self.cache = cache
    }

    public func captureImage(windowID: UInt32, relativeScale: Double) async throws -> CGImage {
        // SCScreenshotManager requires a WindowServer connection; a bare CLI
        // process has none until NSApplication is touched on the main actor.
        _ = await MainActor.run { NSApplication.shared }

        let window: SCWindow
        do {
            window = try await cache.window(for: windowID)
        } catch ShareableContentCacheError.windowNotFound {
            throw CaptureError.windowNotFound(windowID)
        }

        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        let pixels = CaptureDimensions.pixelSize(
            pointSize: window.frame.size,
            pointPixelScale: Double(filter.pointPixelScale),
            relativeScale: relativeScale
        )
        config.width = pixels.width
        config.height = pixels.height
        config.showsCursor = false
        config.captureResolution = .best

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }

    public enum CaptureError: LocalizedError {
        case windowNotFound(UInt32)

        public var errorDescription: String? {
            switch self {
            case .windowNotFound(let id):
                return "No window found with ID \(id)"
            }
        }
    }
}

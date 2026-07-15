import AppKit
import CoreGraphics
import Foundation
import LilshotCore
import ScreenCaptureKit

public struct ScreenCaptureDisplayCapturer: DisplayCapturing {
    private let cache: ShareableContentCache

    public init(cache: ShareableContentCache = .shared) {
        self.cache = cache
    }

    public func captureMainDisplay(scale: Double) async throws -> CGImage {
        try await capture(region: nil, scale: scale)
    }

    public func captureMainDisplayRegion(_ rect: CGRect, scale: Double) async throws -> CGImage {
        guard rect.width >= 1, rect.height >= 1 else {
            throw CaptureError.emptyRegion
        }
        return try await capture(region: rect, scale: scale)
    }

    private func capture(region: CGRect?, scale: Double) async throws -> CGImage {
        // SCScreenshotManager needs a WindowServer connection.
        _ = await MainActor.run { NSApplication.shared }

        let display: SCDisplay
        do {
            display = try await cache.mainDisplay()
        } catch ShareableContentCacheError.displayNotFound {
            throw CaptureError.mainDisplayUnavailable
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        let safeScale = max(scale, 0.1)

        let captureSize: CGSize
        if let region {
            config.sourceRect = region
            captureSize = region.size
        } else {
            captureSize = display.frame.size
        }

        config.width = max(1, Int((captureSize.width * safeScale).rounded()))
        config.height = max(1, Int((captureSize.height * safeScale).rounded()))
        config.showsCursor = false
        config.captureResolution = .best

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }

    public enum CaptureError: LocalizedError {
        case emptyRegion
        case mainDisplayUnavailable

        public var errorDescription: String? {
            switch self {
            case .emptyRegion:
                return "Capture region is empty"
            case .mainDisplayUnavailable:
                return "Main display is unavailable"
            }
        }
    }
}

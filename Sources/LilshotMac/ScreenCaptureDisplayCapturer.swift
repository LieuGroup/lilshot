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

    public func captureMainDisplay(relativeScale: Double) async throws -> CGImage {
        try await capture(region: nil, relativeScale: relativeScale)
    }

    public func captureMainDisplayRegion(_ rect: CGRect, relativeScale: Double) async throws -> CGImage {
        guard rect.width >= 1, rect.height >= 1 else {
            throw CaptureError.emptyRegion
        }
        return try await capture(region: rect, relativeScale: relativeScale)
    }

    private func capture(region: CGRect?, relativeScale: Double) async throws -> CGImage {
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
        let pointSize = region?.size ?? display.frame.size
        if let region {
            config.sourceRect = region
        }

        let pixels = CaptureDimensions.pixelSize(
            pointSize: pointSize,
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

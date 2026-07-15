import AppKit
import CoreGraphics
import Foundation
import LilshotCore
import ScreenCaptureKit

public struct ScreenCaptureWindowCapturer: WindowCapturing {
    public init() {}

    public func captureImage(windowID: UInt32, scale: Double) async throws -> CGImage {
        // SCScreenshotManager requires a WindowServer connection; a bare CLI
        // process has none until NSApplication is touched on the main actor.
        _ = await MainActor.run { NSApplication.shared }

        let content = try await SCShareableContent.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: false
        )
        guard let window = content.windows.first(where: { $0.windowID == windowID }) else {
            throw CaptureError.windowNotFound(windowID)
        }

        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        let safeScale = max(scale, 0.1)
        config.width = max(1, Int((window.frame.width * safeScale).rounded()))
        config.height = max(1, Int((window.frame.height * safeScale).rounded()))
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

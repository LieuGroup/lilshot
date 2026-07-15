import AppKit
import CoreGraphics
import Foundation
import LilshotCore
import ScreenCaptureKit

struct ScreenCaptureWindowCapturer: WindowCapturing {
    func captureImage(windowID: UInt32) async throws -> CGImage {
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
        let scale: CGFloat = 2
        config.width = Int(window.frame.width * scale)
        config.height = Int(window.frame.height * scale)
        config.showsCursor = false
        config.captureResolution = .best

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }

    enum CaptureError: LocalizedError {
        case windowNotFound(UInt32)

        var errorDescription: String? {
            switch self {
            case .windowNotFound(let id):
                return "No window found with ID \(id)"
            }
        }
    }
}

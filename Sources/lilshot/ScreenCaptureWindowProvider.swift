import Foundation
import LilshotCore
import ScreenCaptureKit

struct ScreenCaptureWindowProvider: WindowProviding {
    func windows() async throws -> [WindowInfo] {
        let content = try await SCShareableContent.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: false
        )
        return content.windows.map { window in
            WindowInfo(
                id: window.windowID,
                appName: window.owningApplication?.applicationName ?? "",
                title: window.title ?? "",
                width: Int(window.frame.width.rounded()),
                height: Int(window.frame.height.rounded()),
                isOnScreen: window.isOnScreen
            )
        }
    }
}

import AppKit
import Foundation
import LilshotCore
import ScreenCaptureKit

public struct ScreenCaptureWindowProvider: WindowProviding {
    private let cache: ShareableContentCache

    public init(cache: ShareableContentCache = .shared) {
        self.cache = cache
    }

    public func windows() async throws -> [WindowInfo] {
        let content = try await cache.shareableContent()
        return content.windows.map { window in
            let pid = window.owningApplication?.processID
            let ownerIsRegularApp: Bool
            if let pid {
                let app = NSRunningApplication(processIdentifier: pid)
                ownerIsRegularApp = app?.activationPolicy == .regular
            } else {
                ownerIsRegularApp = false
            }
            return WindowInfo(
                id: window.windowID,
                appName: window.owningApplication?.applicationName ?? "",
                title: window.title ?? "",
                width: Int(window.frame.width.rounded()),
                height: Int(window.frame.height.rounded()),
                isOnScreen: window.isOnScreen,
                layer: window.windowLayer,
                ownerIsRegularApp: ownerIsRegularApp
            )
        }
    }
}

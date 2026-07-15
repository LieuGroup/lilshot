import CoreGraphics

public struct WindowInfo: Equatable, Sendable {
    public let id: UInt32
    public let appName: String
    public let title: String
    public let width: Int
    public let height: Int
    public let isOnScreen: Bool
    public let layer: Int
    public let ownerIsRegularApp: Bool

    public init(
        id: UInt32,
        appName: String,
        title: String,
        width: Int,
        height: Int,
        isOnScreen: Bool,
        layer: Int,
        ownerIsRegularApp: Bool
    ) {
        self.id = id
        self.appName = appName
        self.title = title
        self.width = width
        self.height = height
        self.isOnScreen = isOnScreen
        self.layer = layer
        self.ownerIsRegularApp = ownerIsRegularApp
    }
}

public protocol WindowProviding: Sendable {
    func windows() async throws -> [WindowInfo]
}

public protocol WindowCapturing: Sendable {
    /// Captures a window at `scale` relative to its point size (e.g. 2 for retina, 0.5 for previews).
    func captureImage(windowID: UInt32, scale: Double) async throws -> CGImage
}

public protocol DisplayCapturing: Sendable {
    /// Captures the main display at `scale` relative to its point size.
    func captureMainDisplay(scale: Double) async throws -> CGImage

    /// Captures a region of the main display. `rect` is in ScreenCaptureKit
    /// point space (origin top-left of the display).
    func captureMainDisplayRegion(_ rect: CGRect, scale: Double) async throws -> CGImage
}

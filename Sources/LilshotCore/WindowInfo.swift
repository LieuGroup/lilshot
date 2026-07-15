import CoreGraphics
import Foundation

public struct WindowInfo: Equatable, Sendable {
    public let id: UInt32
    public let appName: String
    public let title: String
    public let width: Int
    public let height: Int
    public let isOnScreen: Bool

    public init(
        id: UInt32,
        appName: String,
        title: String,
        width: Int,
        height: Int,
        isOnScreen: Bool
    ) {
        self.id = id
        self.appName = appName
        self.title = title
        self.width = width
        self.height = height
        self.isOnScreen = isOnScreen
    }
}

public protocol WindowProviding: Sendable {
    func windows() async throws -> [WindowInfo]
}

public protocol WindowCapturing: Sendable {
    func captureImage(windowID: UInt32) async throws -> CGImage
}

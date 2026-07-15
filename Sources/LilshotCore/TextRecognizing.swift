import CoreGraphics

public protocol TextRecognizing: Sendable {
    func recognize(in image: CGImage) async throws -> [(String, CGRect)]
}

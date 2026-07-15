import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PNGWriter {
    static func write(_ image: CGImage, to path: String) throws {
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw WriteError.couldNotCreateDestination(path)
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw WriteError.couldNotWrite(path)
        }
    }

    enum WriteError: LocalizedError {
        case couldNotCreateDestination(String)
        case couldNotWrite(String)

        var errorDescription: String? {
            switch self {
            case .couldNotCreateDestination(let path):
                return "Failed to create image destination at \(path)"
            case .couldNotWrite(let path):
                return "Failed to write PNG to \(path)"
            }
        }
    }
}

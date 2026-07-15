import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Encode a `CGImage` as PNG data or write it to disk.
public enum PNGImageWriter {
    public enum WriteError: LocalizedError {
        case encodeFailed
        case writeFailed(String)

        public var errorDescription: String? {
            switch self {
            case .encodeFailed:
                return "Failed to encode PNG"
            case .writeFailed(let path):
                return "Failed to write PNG to \(path)"
            }
        }
    }

    public static func data(from image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw WriteError.encodeFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw WriteError.encodeFailed
        }
        return data as Data
    }

    public static func write(_ image: CGImage, to path: String) throws {
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
            throw WriteError.writeFailed(path)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw WriteError.writeFailed(path)
        }
    }
}

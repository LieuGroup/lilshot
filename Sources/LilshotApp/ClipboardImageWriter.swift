import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum ClipboardImageWriter {
    enum WriteError: LocalizedError {
        case pngEncodeFailed
        case tiffEncodeFailed

        var errorDescription: String? {
            switch self {
            case .pngEncodeFailed: return "Failed to encode PNG for clipboard"
            case .tiffEncodeFailed: return "Failed to encode TIFF for clipboard"
            }
        }
    }

    static func write(_ image: CGImage) throws {
        let png = try pngData(from: image)
        let nsImage = NSImage(
            cgImage: image,
            size: NSSize(width: image.width, height: image.height)
        )
        guard let tiff = nsImage.tiffRepresentation else {
            throw WriteError.tiffEncodeFailed
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(png, forType: .png)
        pasteboard.setData(tiff, forType: .tiff)
    }

    private static func pngData(from image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw WriteError.pngEncodeFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw WriteError.pngEncodeFailed
        }
        return data as Data
    }
}

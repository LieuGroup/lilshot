import AppKit
import CoreGraphics
import LilshotMac

enum ClipboardImageWriter {
    enum WriteError: LocalizedError {
        case tiffEncodeFailed

        var errorDescription: String? {
            switch self {
            case .tiffEncodeFailed: return "Failed to encode TIFF for clipboard"
            }
        }
    }

    static func write(_ image: CGImage) throws {
        let png = try PNGImageWriter.data(from: image)
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
}

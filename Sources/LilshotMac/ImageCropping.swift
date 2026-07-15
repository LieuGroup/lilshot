import CoreGraphics
import Foundation
import LilshotCore

/// Crops a `CGImage` using image-pixel (top-left) coordinates.
public enum ImageCropping {
    public static func crop(_ image: CGImage, to rect: CGRect) -> CGImage? {
        let pixel = CGRect(
            x: rect.origin.x.rounded(.towardZero),
            y: rect.origin.y.rounded(.towardZero),
            width: rect.width.rounded(.towardZero),
            height: rect.height.rounded(.towardZero)
        )
        guard pixel.width >= 1, pixel.height >= 1 else { return nil }
        let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let clamped = pixel.intersection(bounds)
        guard clamped.width >= 1, clamped.height >= 1 else { return nil }
        return image.cropping(to: clamped)
    }
}

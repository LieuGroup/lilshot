import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import LilshotCore

/// CIPixellate blur for annotation rects (image pixel space, top-left).
enum AnnotationPixellate {
    private static let ciContext = CIContext(options: nil)

    /// Pixellate `rect` from `base` and draw into a top-left-oriented context.
    static func draw(_ rect: CGRect, from base: CGImage, in context: CGContext) {
        guard rect.width >= 1, rect.height >= 1 else { return }
        let cell = AnnotationHitTesting.pixellateCellSize(
            imageSize: CGSize(width: base.width, height: base.height)
        )
        guard let cropped = crop(base, imageSpaceRect: rect) else { return }
        guard let pixellated = apply(cropped, cellSize: cell) else { return }
        context.draw(pixellated, in: rect)
    }

    private static func crop(_ image: CGImage, imageSpaceRect rect: CGRect) -> CGImage? {
        let height = CGFloat(image.height)
        let bitmapRect = CGRect(
            x: rect.origin.x,
            y: height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        ).integral
        guard bitmapRect.width >= 1, bitmapRect.height >= 1 else { return nil }
        return image.cropping(to: bitmapRect)
    }

    private static func apply(_ image: CGImage, cellSize: CGFloat) -> CGImage? {
        let input = CIImage(cgImage: image)
        let filter = CIFilter.pixellate()
        filter.inputImage = input
        filter.center = CGPoint(x: input.extent.midX, y: input.extent.midY)
        filter.scale = Float(max(cellSize, 1))
        guard let output = filter.outputImage?.cropped(to: input.extent) else { return nil }
        return ciContext.createCGImage(output, from: input.extent)
    }
}

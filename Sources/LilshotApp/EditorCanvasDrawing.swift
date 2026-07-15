import AppKit
import LilshotCore
import LilshotMac

/// Shared canvas drawing helpers (image-pixel annotations → fitted view).
enum EditorCanvasDrawing {
    static func drawAnnotation(
        _ annotation: Annotation,
        fitted: CGRect,
        imageSize: CGSize,
        viewSize: CGSize,
        in context: CGContext
    ) {
        context.saveGState()
        context.translateBy(x: fitted.origin.x, y: fitted.origin.y)
        let scale = EditorGeometry.fitScale(imageSize: imageSize, viewSize: viewSize)
        context.scaleBy(x: scale, y: scale)
        AnnotationRenderer.draw(annotation, in: context)
        context.restoreGState()
    }

    static func drawCropOverlay(
        _ crop: CGRect,
        imageSize: CGSize,
        viewSize: CGSize,
        bounds: CGRect,
        dashPhase: CGFloat,
        in context: CGContext
    ) {
        let viewCrop = EditorGeometry.viewRect(
            fromImage: crop,
            imageSize: imageSize,
            viewSize: viewSize
        )

        context.saveGState()
        let dim = CGMutablePath()
        dim.addRect(bounds)
        dim.addRect(viewCrop)
        context.addPath(dim)
        context.setFillColor(NSColor.black.withAlphaComponent(0.45).cgColor)
        context.drawPath(using: .eoFill)
        context.restoreGState()

        let path = NSBezierPath(rect: viewCrop.insetBy(dx: 0.5, dy: 0.5))
        path.lineWidth = 1
        let pattern: [CGFloat] = [5, 4]
        path.setLineDash(pattern, count: pattern.count, phase: dashPhase)
        NSColor.white.setStroke()
        path.stroke()
        path.setLineDash(pattern, count: pattern.count, phase: dashPhase + 4.5)
        NSColor.black.setStroke()
        path.stroke()
    }
}

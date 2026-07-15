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
        actualSize: Bool,
        base: CGImage?,
        in context: CGContext
    ) {
        context.saveGState()
        context.translateBy(x: fitted.origin.x, y: fitted.origin.y)
        let scale = EditorGeometry.displayScale(
            imageSize: imageSize, viewSize: viewSize, actualSize: actualSize
        )
        context.scaleBy(x: scale, y: scale)
        AnnotationRenderer.draw(annotation, in: context, base: base)
        context.restoreGState()
    }

    static func drawSelection(
        around annotation: Annotation,
        imageSize: CGSize,
        viewSize: CGSize,
        actualSize: Bool,
        in context: CGContext
    ) {
        let bounds = AnnotationHitTesting.selectionBounds(annotation)
        let viewBounds = EditorGeometry.viewRect(
            fromImage: bounds,
            imageSize: imageSize,
            viewSize: viewSize,
            actualSize: actualSize
        ).insetBy(dx: -3, dy: -3)

        context.saveGState()
        context.setStrokeColor(NSColor.systemYellow.withAlphaComponent(0.9).cgColor)
        context.setLineWidth(1.5)
        context.stroke(viewBounds)

        let handle: CGFloat = 6
        let corners = [
            CGPoint(x: viewBounds.minX, y: viewBounds.minY),
            CGPoint(x: viewBounds.maxX, y: viewBounds.minY),
            CGPoint(x: viewBounds.minX, y: viewBounds.maxY),
            CGPoint(x: viewBounds.maxX, y: viewBounds.maxY),
        ]
        context.setFillColor(NSColor.systemYellow.cgColor)
        for corner in corners {
            let handleRect = CGRect(
                x: corner.x - handle / 2,
                y: corner.y - handle / 2,
                width: handle,
                height: handle
            )
            context.fill(handleRect)
        }
        context.restoreGState()
    }

    static func drawCropOverlay(
        _ crop: CGRect,
        imageSize: CGSize,
        viewSize: CGSize,
        actualSize: Bool,
        bounds: CGRect,
        dashPhase: CGFloat,
        in context: CGContext
    ) {
        let viewCrop = EditorGeometry.viewRect(
            fromImage: crop,
            imageSize: imageSize,
            viewSize: viewSize,
            actualSize: actualSize
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

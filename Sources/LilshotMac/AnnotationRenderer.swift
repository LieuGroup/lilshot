import CoreGraphics
import CoreText
import Foundation
import LilshotCore

/// Draws annotations into a bitmap over a base image (image pixel space, top-left).
public enum AnnotationRenderer {
    /// Flatten `base` + `annotations` into a single image for clipboard/save.
    public static func render(base: CGImage, annotations: [Annotation]) -> CGImage? {
        let width = base.width
        let height = base.height
        guard width > 0, height > 0 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(base, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Annotations use top-left image space; flip the context to match.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        for annotation in annotations {
            draw(annotation, in: context, base: base)
        }

        return context.makeImage()
    }

    /// Draw a single annotation into an already top-left-oriented context.
    public static func draw(_ annotation: Annotation, in context: CGContext, base: CGImage? = nil) {
        switch annotation {
        case let .arrow(from, to, color, strokeWidth):
            drawArrow(from: from, to: to, color: color, strokeWidth: strokeWidth, in: context)
        case let .rect(rect, color, strokeWidth):
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(strokeWidth)
            context.stroke(rect.insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2))
        case let .text(origin, string, fontSize, color):
            drawText(string, at: origin, fontSize: fontSize, color: color, in: context)
        case let .blur(rect):
            if let base {
                AnnotationPixellate.draw(rect, from: base, in: context)
            } else {
                context.setFillColor(AnnotationColor.black.withAlpha(0.35).cgColor)
                context.fill(rect)
            }
        case let .stepNumber(center, index, color):
            drawStep(center: center, index: index, color: color, in: context)
        }
    }

    private static func drawArrow(
        from: CGPoint,
        to: CGPoint,
        color: AnnotationColor,
        strokeWidth: CGFloat,
        in context: CGContext
    ) {
        let headLength = max(strokeWidth * 4, 10)
        let headWidth = max(strokeWidth * 3, 8)
        let tips = EditorGeometry.arrowheadPoints(
            from: from,
            to: to,
            length: headLength,
            width: headWidth
        )

        context.setStrokeColor(color.cgColor)
        context.setFillColor(color.cgColor)
        context.setLineWidth(strokeWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()

        context.move(to: to)
        context.addLine(to: tips.left)
        context.addLine(to: tips.right)
        context.closePath()
        context.fillPath()
    }

    private static func drawText(
        _ string: String,
        at origin: CGPoint,
        fontSize: CGFloat,
        color: AnnotationColor,
        in context: CGContext
    ) {
        let font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color.cgColor,
        ]
        let attributed = NSAttributedString(string: string, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed)
        context.textPosition = origin
        CTLineDraw(line, context)
    }

    private static func drawStep(
        center: CGPoint,
        index: Int,
        color: AnnotationColor,
        in context: CGContext
    ) {
        let radius: CGFloat = 12
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: rect)

        let label = "\(index)"
        let fontSize: CGFloat = 14
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: AnnotationColor.white.cgColor,
        ]
        let attributed = NSAttributedString(string: label, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed)
        let bounds = CTLineGetBoundsWithOptions(line, [])
        context.textPosition = CGPoint(
            x: center.x - bounds.width / 2,
            y: center.y - bounds.height / 2 - bounds.origin.y
        )
        CTLineDraw(line, context)
    }
}

private extension AnnotationColor {
    func withAlpha(_ alpha: CGFloat) -> AnnotationColor {
        AnnotationColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

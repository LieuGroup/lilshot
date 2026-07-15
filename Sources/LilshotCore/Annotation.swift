import CoreGraphics

/// Drawing annotations in image pixel space (not view space).
public enum Annotation: Equatable, Sendable {
    case arrow(from: CGPoint, to: CGPoint, color: AnnotationColor, strokeWidth: CGFloat)
    case rect(CGRect, color: AnnotationColor, strokeWidth: CGFloat)
    case text(origin: CGPoint, string: String, fontSize: CGFloat, color: AnnotationColor)
    case blur(CGRect)
    case stepNumber(center: CGPoint, index: Int, color: AnnotationColor)

    /// Translate all points by `delta` (used when cropping).
    public func translated(by delta: CGVector) -> Annotation {
        let dx = delta.dx
        let dy = delta.dy
        switch self {
        case let .arrow(from, to, color, strokeWidth):
            return .arrow(
                from: CGPoint(x: from.x + dx, y: from.y + dy),
                to: CGPoint(x: to.x + dx, y: to.y + dy),
                color: color,
                strokeWidth: strokeWidth
            )
        case let .rect(rect, color, strokeWidth):
            return .rect(
                rect.offsetBy(dx: dx, dy: dy),
                color: color,
                strokeWidth: strokeWidth
            )
        case let .text(origin, string, fontSize, color):
            return .text(
                origin: CGPoint(x: origin.x + dx, y: origin.y + dy),
                string: string,
                fontSize: fontSize,
                color: color
            )
        case let .blur(rect):
            return .blur(rect.offsetBy(dx: dx, dy: dy))
        case let .stepNumber(center, index, color):
            return .stepNumber(
                center: CGPoint(x: center.x + dx, y: center.y + dy),
                index: index,
                color: color
            )
        }
    }
}

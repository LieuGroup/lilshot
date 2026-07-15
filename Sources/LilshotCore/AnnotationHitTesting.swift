import CoreGraphics

/// Hit-testing and selection bounds for annotations in image pixel space.
public enum AnnotationHitTesting {
    public static let defaultTolerance: CGFloat = 8
    public static let stepRadius: CGFloat = 12

    /// Topmost annotation index containing `point`, or nil.
    public static func hitIndex(
        at point: CGPoint,
        in annotations: [Annotation],
        tolerance: CGFloat = defaultTolerance
    ) -> Int? {
        for index in annotations.indices.reversed() {
            if contains(annotations[index], point: point, tolerance: tolerance) {
                return index
            }
        }
        return nil
    }

    public static func contains(
        _ annotation: Annotation,
        point: CGPoint,
        tolerance: CGFloat
    ) -> Bool {
        switch annotation {
        case let .arrow(from, to, _, strokeWidth):
            let pad = max(tolerance, strokeWidth)
            return distanceToSegment(point, from: from, to: to) <= pad
        case let .rect(rect, _, strokeWidth):
            let pad = max(tolerance, strokeWidth)
            return distanceToRectEdge(point, rect: rect) <= pad
        case let .blur(rect):
            return rect.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
        case .text, .stepNumber:
            return selectionBounds(annotation)
                .insetBy(dx: -tolerance, dy: -tolerance)
                .contains(point)
        }
    }

    public static func selectionBounds(_ annotation: Annotation) -> CGRect {
        switch annotation {
        case let .arrow(from, to, _, strokeWidth):
            let pad = max(strokeWidth, 4)
            let minX = min(from.x, to.x) - pad
            let minY = min(from.y, to.y) - pad
            let maxX = max(from.x, to.x) + pad
            let maxY = max(from.y, to.y) + pad
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        case let .rect(rect, _, _):
            return rect
        case let .blur(rect):
            return rect
        case let .text(origin, string, fontSize, _):
            let width = max(CGFloat(string.count) * fontSize * 0.6, fontSize)
            let height = fontSize * 1.2
            return CGRect(
                x: origin.x,
                y: origin.y - fontSize * 0.85,
                width: width,
                height: height
            )
        case let .stepNumber(center, _, _):
            let r = stepRadius
            return CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        }
    }

    /// Distance from `point` to the closest point on segment a→b.
    public static func distanceToSegment(
        _ point: CGPoint,
        from a: CGPoint,
        to b: CGPoint
    ) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSq = dx * dx + dy * dy
        guard lengthSq > 0 else {
            return hypot(point.x - a.x, point.y - a.y)
        }
        let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSq))
        let proj = CGPoint(x: a.x + t * dx, y: a.y + t * dy)
        return hypot(point.x - proj.x, point.y - proj.y)
    }

    /// Distance from `point` to the nearest edge of `rect` (interior is > 0).
    public static func distanceToRectEdge(_ point: CGPoint, rect: CGRect) -> CGFloat {
        if !rect.contains(point) {
            let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
            let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
            if dx > 0, dy > 0 { return hypot(dx, dy) }
            return max(dx, dy)
        }
        let left = point.x - rect.minX
        let right = rect.maxX - point.x
        let top = point.y - rect.minY
        let bottom = rect.maxY - point.y
        return min(left, right, top, bottom)
    }

    /// CIPixellate cell size: ~1.5% of the longer image edge, minimum 8px.
    public static func pixellateCellSize(imageSize: CGSize) -> CGFloat {
        max(8, max(imageSize.width, imageSize.height) * 0.015)
    }
}

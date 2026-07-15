import CoreGraphics

/// Pure geometry for region capture: drag normalization, bounds clamping,
/// and AppKit (bottom-left) → ScreenCaptureKit (top-left) conversion.
public enum RegionGeometry {
    /// Positive-size rect from two drag corners, regardless of drag direction.
    public static func normalizedRect(from a: CGPoint, to b: CGPoint) -> CGRect {
        let minX = min(a.x, b.x)
        let minY = min(a.y, b.y)
        let width = abs(a.x - b.x)
        let height = abs(a.y - b.y)
        return CGRect(x: minX, y: minY, width: width, height: height)
    }

    /// Intersection of `rect` with `bounds`; empty when they do not overlap.
    public static func clamp(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        rect.intersection(bounds)
    }

    /// Convert a display-local AppKit rect (origin bottom-left) to SCK space
    /// (origin top-left of the same display).
    public static func appKitRectToScreenCaptureKit(
        _ rect: CGRect,
        displayHeight: CGFloat
    ) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: displayHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    /// Scale a point-space rect into pixel space for CGImage cropping.
    public static func pixelRect(from pointRect: CGRect, scale: CGFloat) -> CGRect {
        let safe = max(scale, 0.1)
        return CGRect(
            x: pointRect.origin.x * safe,
            y: pointRect.origin.y * safe,
            width: pointRect.width * safe,
            height: pointRect.height * safe
        )
    }
}

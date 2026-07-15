import CoreGraphics

/// Pixel canvas size for ScreenCaptureKit captures from point size and scales.
public enum CaptureDimensions {
    /// Pixel width/height for a capture config.
    ///
    /// - Parameters:
    ///   - pointSize: Content size in points (display/window frame or region).
    ///   - pointPixelScale: Native pixels-per-point from `SCContentFilter.pointPixelScale`.
    ///   - relativeScale: Multiplier on native pixel scale (1.0 = native, 0.5 = half).
    public static func pixelSize(
        pointSize: CGSize,
        pointPixelScale: Double,
        relativeScale: Double
    ) -> (width: Int, height: Int) {
        let factor = pointPixelScale * relativeScale
        return (
            width: max(1, Int((Double(pointSize.width) * factor).rounded())),
            height: max(1, Int((Double(pointSize.height) * factor).rounded()))
        )
    }
}

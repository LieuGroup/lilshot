import CoreGraphics

/// Editor canvas geometry: zoom-to-fit mapping, crop clamp, arrowheads.
public enum EditorGeometry {
    /// Scale that fits `imageSize` inside `viewSize` without cropping.
    public static func fitScale(imageSize: CGSize, viewSize: CGSize) -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0,
              viewSize.width > 0, viewSize.height > 0
        else { return 1 }
        return min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
    }

    /// Image rect centered in the view after zoom-to-fit.
    public static func fittedImageRect(imageSize: CGSize, in viewSize: CGSize) -> CGRect {
        let scale = fitScale(imageSize: imageSize, viewSize: viewSize)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: (viewSize.width - width) / 2,
            y: (viewSize.height - height) / 2,
            width: width,
            height: height
        )
    }

    public static func imagePoint(
        fromView point: CGPoint,
        imageSize: CGSize,
        viewSize: CGSize
    ) -> CGPoint {
        let fitted = fittedImageRect(imageSize: imageSize, in: viewSize)
        let scale = fitScale(imageSize: imageSize, viewSize: viewSize)
        guard scale > 0 else { return .zero }
        return CGPoint(
            x: (point.x - fitted.origin.x) / scale,
            y: (point.y - fitted.origin.y) / scale
        )
    }

    public static func viewPoint(
        fromImage point: CGPoint,
        imageSize: CGSize,
        viewSize: CGSize
    ) -> CGPoint {
        let fitted = fittedImageRect(imageSize: imageSize, in: viewSize)
        let scale = fitScale(imageSize: imageSize, viewSize: viewSize)
        return CGPoint(
            x: fitted.origin.x + point.x * scale,
            y: fitted.origin.y + point.y * scale
        )
    }

    public static func imageRect(
        fromView rect: CGRect,
        imageSize: CGSize,
        viewSize: CGSize
    ) -> CGRect {
        let origin = imagePoint(fromView: rect.origin, imageSize: imageSize, viewSize: viewSize)
        let corner = imagePoint(
            fromView: CGPoint(x: rect.maxX, y: rect.maxY),
            imageSize: imageSize,
            viewSize: viewSize
        )
        return RegionGeometry.normalizedRect(from: origin, to: corner)
    }

    public static func viewRect(
        fromImage rect: CGRect,
        imageSize: CGSize,
        viewSize: CGSize
    ) -> CGRect {
        let origin = viewPoint(fromImage: rect.origin, imageSize: imageSize, viewSize: viewSize)
        let corner = viewPoint(
            fromImage: CGPoint(x: rect.maxX, y: rect.maxY),
            imageSize: imageSize,
            viewSize: viewSize
        )
        return RegionGeometry.normalizedRect(from: origin, to: corner)
    }

    /// Clamp a crop rect to image pixel bounds via `RegionGeometry.clamp`.
    public static func clampCrop(_ rect: CGRect, to canvasSize: CGSize) -> CGRect {
        RegionGeometry.clamp(
            rect,
            to: CGRect(origin: .zero, size: canvasSize)
        )
    }

    /// Left/right base corners of an arrowhead at `to`, pointing along from→to.
    public static func arrowheadPoints(
        from: CGPoint,
        to: CGPoint,
        length: CGFloat,
        width: CGFloat
    ) -> (left: CGPoint, right: CGPoint) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let shaft = hypot(dx, dy)
        guard shaft >= length, shaft > 0 else {
            return (left: to, right: to)
        }
        let ux = dx / shaft
        let uy = dy / shaft
        let base = CGPoint(x: to.x - ux * length, y: to.y - uy * length)
        let half = width / 2
        // Perpendicular to unit direction
        let px = -uy * half
        let py = ux * half
        return (
            left: CGPoint(x: base.x + px, y: base.y + py),
            right: CGPoint(x: base.x - px, y: base.y - py)
        )
    }
}

import AppKit
import LilshotCore
import LilshotMac

/// Zoom-to-fit canvas with crop drag (dimmed outside, marching ants).
final class EditorCanvasView: NSView {
    var image: CGImage? {
        didSet { needsDisplay = true }
    }

    var model: EditorModel = EditorModel(canvasSize: .zero) {
        didSet { needsDisplay = true }
    }

    var onCropDraftChanged: ((CGPoint, CGPoint) -> Void)?
    var onCropDraftCleared: (() -> Void)?

    private var dragAnchor: CGPoint?
    private var dashPhase: CGFloat = 0
    private var antsTimer: Timer?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            startAnts()
        } else {
            stopAnts()
        }
    }

    deinit { stopAnts() }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        guard model.tool == .crop else { return }
        let point = convert(event.locationInWindow, from: nil)
        guard imagePoint(fromView: point) != nil else { return }
        dragAnchor = point
    }

    override func mouseDragged(with event: NSEvent) {
        guard model.tool == .crop, let anchor = dragAnchor else { return }
        let cursor = convert(event.locationInWindow, from: nil)
        guard let a = imagePoint(fromView: anchor),
              let b = imagePoint(fromView: cursor)
        else { return }
        onCropDraftChanged?(a, b)
    }

    override func mouseUp(with event: NSEvent) {
        guard model.tool == .crop, let anchor = dragAnchor else { return }
        dragAnchor = nil
        let cursor = convert(event.locationInWindow, from: nil)
        guard let a = imagePoint(fromView: anchor),
              let b = imagePoint(fromView: cursor)
        else {
            onCropDraftCleared?()
            return
        }
        let draft = RegionGeometry.normalizedRect(from: a, to: b)
        if draft.width < 2 || draft.height < 2 {
            onCropDraftCleared?()
        } else {
            onCropDraftChanged?(a, b)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        bounds.fill()

        guard let image else { return }
        let imageSize = CGSize(width: image.width, height: image.height)
        let fitted = EditorGeometry.fittedImageRect(imageSize: imageSize, in: bounds.size)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.interpolationQuality = .high
        context.draw(image, in: fitted)

        for annotation in model.annotations {
            drawAnnotation(annotation, fitted: fitted, imageSize: imageSize, in: context)
        }

        if let crop = model.cropDraft {
            drawCropOverlay(crop, fitted: fitted, imageSize: imageSize, in: context)
        }
        context.restoreGState()
    }

    private func drawCropOverlay(
        _ crop: CGRect,
        fitted: CGRect,
        imageSize: CGSize,
        in context: CGContext
    ) {
        let viewCrop = EditorGeometry.viewRect(
            fromImage: crop,
            imageSize: imageSize,
            viewSize: bounds.size
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

    private func drawAnnotation(
        _ annotation: Annotation,
        fitted: CGRect,
        imageSize: CGSize,
        in context: CGContext
    ) {
        // Overlay preview: map image-space drawing into the fitted rect.
        context.saveGState()
        context.translateBy(x: fitted.origin.x, y: fitted.origin.y)
        let scale = EditorGeometry.fitScale(imageSize: imageSize, viewSize: bounds.size)
        context.scaleBy(x: scale, y: scale)
        AnnotationRenderer.draw(annotation, in: context)
        context.restoreGState()
    }

    private func imagePoint(fromView point: CGPoint) -> CGPoint? {
        guard let image else { return nil }
        let imageSize = CGSize(width: image.width, height: image.height)
        let fitted = EditorGeometry.fittedImageRect(imageSize: imageSize, in: bounds.size)
        guard fitted.contains(point) else { return nil }
        return EditorGeometry.imagePoint(
            fromView: point,
            imageSize: imageSize,
            viewSize: bounds.size
        )
    }

    private func startAnts() {
        stopAnts()
        antsTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self, self.model.cropDraft != nil else { return }
            self.dashPhase += 1
            self.needsDisplay = true
        }
    }

    private func stopAnts() {
        antsTimer?.invalidate()
        antsTimer = nil
    }
}

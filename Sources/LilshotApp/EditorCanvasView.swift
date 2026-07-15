import AppKit
import LilshotCore

/// Zoom-to-fit canvas: crop, arrow/rect drag preview, step click, text input.
final class EditorCanvasView: NSView {
    var image: CGImage? {
        didSet { needsDisplay = true }
    }

    var model: EditorModel = EditorModel(canvasSize: .zero) {
        didSet { needsDisplay = true }
    }

    var onCropDraftChanged: ((CGPoint, CGPoint) -> Void)?
    var onCropDraftCleared: (() -> Void)?
    var onCommitArrow: ((CGPoint, CGPoint) -> Void)?
    var onCommitRect: ((CGPoint, CGPoint) -> Void)?
    var onCommitStep: ((CGPoint) -> Void)?
    var onCommitText: ((CGPoint, String) -> Void)?

    private var dragAnchor: CGPoint?
    private var draftAnnotation: Annotation?
    private var dashPhase: CGFloat = 0
    private var antsTimer: Timer?
    private let textSession = EditorTextInputSession()

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    var isEditingText: Bool { textSession.isActive }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            startAnts()
            textSession.onCommit = { [weak self] origin, string in
                self?.onCommitText?(origin, string)
            }
        } else {
            stopAnts()
            textSession.cancel()
        }
    }

    deinit { stopAnts() }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        if textSession.isActive { textSession.commit(); return }

        let point = convert(event.locationInWindow, from: nil)
        guard let imagePt = imagePoint(fromView: point) else { return }

        switch model.tool {
        case .crop, .arrow, .rect:
            dragAnchor = point
        case .stepNumber:
            onCommitStep?(imagePt)
        case .text:
            beginText(at: point, imageOrigin: imagePt)
        case .select, .blur:
            break
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let anchor = dragAnchor else { return }
        let cursor = convert(event.locationInWindow, from: nil)
        guard let a = imagePoint(fromView: anchor),
              let b = imagePoint(fromView: cursor)
        else { return }

        switch model.tool {
        case .crop:
            onCropDraftChanged?(a, b)
        case .arrow:
            draftAnnotation = .arrow(
                from: a, to: b, color: model.color, strokeWidth: model.strokeWidth
            )
            needsDisplay = true
        case .rect:
            let rect = RegionGeometry.normalizedRect(from: a, to: b)
            draftAnnotation = .rect(rect, color: model.color, strokeWidth: model.strokeWidth)
            needsDisplay = true
        default:
            break
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard let anchor = dragAnchor else { return }
        dragAnchor = nil
        let cursor = convert(event.locationInWindow, from: nil)
        let a = imagePoint(fromView: anchor)
        let b = imagePoint(fromView: cursor)
        let draft = draftAnnotation
        draftAnnotation = nil
        needsDisplay = true

        switch model.tool {
        case .crop:
            finishCrop(from: a, to: b)
        case .arrow:
            if let a, let b, case .arrow = draft { onCommitArrow?(a, b) }
        case .rect:
            if let a, let b, case .rect = draft { onCommitRect?(a, b) }
        default:
            break
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        bounds.fill()
        guard let image, let context = NSGraphicsContext.current?.cgContext else { return }
        let imageSize = CGSize(width: image.width, height: image.height)
        let fitted = EditorGeometry.fittedImageRect(imageSize: imageSize, in: bounds.size)
        context.saveGState()
        context.interpolationQuality = .high
        context.draw(image, in: fitted)
        let all = model.annotations + (draftAnnotation.map { [$0] } ?? [])
        for annotation in all {
            EditorCanvasDrawing.drawAnnotation(
                annotation, fitted: fitted, imageSize: imageSize, viewSize: bounds.size, in: context
            )
        }
        if let crop = model.cropDraft {
            EditorCanvasDrawing.drawCropOverlay(
                crop, imageSize: imageSize, viewSize: bounds.size,
                bounds: bounds, dashPhase: dashPhase, in: context
            )
        }
        context.restoreGState()
    }

    private func beginText(at viewPoint: CGPoint, imageOrigin: CGPoint) {
        let scale = fitScale()
        let fontSize = max(
            EditorModel.defaultTextFontSize(canvasHeight: model.canvasSize.height) * scale,
            10
        )
        textSession.begin(
            at: viewPoint,
            imageOrigin: imageOrigin,
            fontSize: fontSize,
            color: NSColor(
                srgbRed: model.color.red,
                green: model.color.green,
                blue: model.color.blue,
                alpha: model.color.alpha
            ),
            in: self
        )
    }

    private func finishCrop(from a: CGPoint?, to b: CGPoint?) {
        guard let a, let b else { onCropDraftCleared?(); return }
        let draft = RegionGeometry.normalizedRect(from: a, to: b)
        if draft.width < 2 || draft.height < 2 {
            onCropDraftCleared?()
        } else {
            onCropDraftChanged?(a, b)
        }
    }

    private func imagePoint(fromView point: CGPoint) -> CGPoint? {
        guard let image else { return nil }
        let imageSize = CGSize(width: image.width, height: image.height)
        let fitted = EditorGeometry.fittedImageRect(imageSize: imageSize, in: bounds.size)
        guard fitted.contains(point) else { return nil }
        return EditorGeometry.imagePoint(fromView: point, imageSize: imageSize, viewSize: bounds.size)
    }

    private func fitScale() -> CGFloat {
        guard let image else { return 1 }
        return EditorGeometry.fitScale(
            imageSize: CGSize(width: image.width, height: image.height),
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

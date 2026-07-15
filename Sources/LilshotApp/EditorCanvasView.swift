import AppKit
import LilshotCore

/// Zoomable canvas: crop, draw tools, blur, and select/move.
final class EditorCanvasView: NSView {
    var image: CGImage? {
        didSet { needsDisplay = true }
    }

    var model: EditorModel = EditorModel(canvasSize: .zero) {
        didSet { needsDisplay = true }
    }

    /// When true, show image at 1:1 pixels; otherwise zoom-to-fit.
    var actualSize: Bool = false {
        didSet { needsDisplay = true }
    }

    var onCropDraftChanged: ((CGPoint, CGPoint) -> Void)?
    var onCropDraftCleared: (() -> Void)?
    var onCommitArrow: ((CGPoint, CGPoint) -> Void)?
    var onCommitRect: ((CGPoint, CGPoint) -> Void)?
    var onCommitBlur: ((CGPoint, CGPoint) -> Void)?
    var onCommitStep: ((CGPoint) -> Void)?
    var onCommitText: ((CGPoint, String) -> Void)?
    var onSelectAt: ((CGPoint) -> Void)?
    var onBeginMove: (() -> Void)?
    var onMoveBy: ((CGVector) -> Void)?

    private var dragAnchor: CGPoint?
    private var lastMoveImagePoint: CGPoint?
    private var moveStarted = false
    private var draftAnnotation: Annotation?
    private var dashPhase: CGFloat = 0
    private var antsTimer: Timer?
    private let textSession = EditorTextInputSession()

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    var isEditingText: Bool { textSession.isActive }

    var dragAnchorPoint: CGPoint? { dragAnchor }
    var lastMovePoint: CGPoint? { lastMoveImagePoint }
    var hasMoveStarted: Bool { moveStarted }

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

    override func mouseDown(with event: NSEvent) { handleMouseDown(event) }
    override func mouseDragged(with event: NSEvent) { handleMouseDragged(event) }
    override func mouseUp(with event: NSEvent) { handleMouseUp(event) }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        bounds.fill()
        guard let image, let context = NSGraphicsContext.current?.cgContext else { return }
        let imageSize = CGSize(width: image.width, height: image.height)
        let fitted = EditorGeometry.imageRect(
            imageSize: imageSize, in: bounds.size, actualSize: actualSize
        )
        context.saveGState()
        context.interpolationQuality = .high
        context.draw(image, in: fitted)
        let all = model.annotations + (draftAnnotation.map { [$0] } ?? [])
        for annotation in all {
            EditorCanvasDrawing.drawAnnotation(
                annotation,
                fitted: fitted,
                imageSize: imageSize,
                viewSize: bounds.size,
                actualSize: actualSize,
                base: image,
                in: context
            )
        }
        if let index = model.selectedIndex, model.annotations.indices.contains(index) {
            EditorCanvasDrawing.drawSelection(
                around: model.annotations[index],
                imageSize: imageSize,
                viewSize: bounds.size,
                actualSize: actualSize,
                in: context
            )
        }
        if let crop = model.cropDraft {
            EditorCanvasDrawing.drawCropOverlay(
                crop, imageSize: imageSize, viewSize: bounds.size, actualSize: actualSize,
                bounds: bounds, dashPhase: dashPhase, in: context
            )
        }
        context.restoreGState()
    }

    func textSessionCommit() { textSession.commit() }

    func setDragAnchor(_ point: CGPoint) { dragAnchor = point }

    func setMoveTracking(_ imagePt: CGPoint) {
        lastMoveImagePoint = imagePt
        moveStarted = false
    }

    func markMoveStarted() { moveStarted = true }

    func updateLastMovePoint(_ point: CGPoint) { lastMoveImagePoint = point }

    func setDraft(_ annotation: Annotation) {
        draftAnnotation = annotation
        needsDisplay = true
    }

    func takeDraft() -> Annotation? {
        let draft = draftAnnotation
        draftAnnotation = nil
        return draft
    }

    func clearDragState() {
        dragAnchor = nil
        lastMoveImagePoint = nil
        moveStarted = false
    }

    func beginTextInput(at viewPoint: CGPoint, imageOrigin: CGPoint) {
        let scale = displayScale()
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

    func finishCropInteraction(from a: CGPoint?, to b: CGPoint?) {
        guard let a, let b else { onCropDraftCleared?(); return }
        let draft = RegionGeometry.normalizedRect(from: a, to: b)
        if draft.width < 2 || draft.height < 2 {
            onCropDraftCleared?()
        } else {
            onCropDraftChanged?(a, b)
        }
    }

    func imagePointForInteraction(fromView point: CGPoint) -> CGPoint? {
        guard let image else { return nil }
        let imageSize = CGSize(width: image.width, height: image.height)
        let fitted = EditorGeometry.imageRect(
            imageSize: imageSize, in: bounds.size, actualSize: actualSize
        )
        guard fitted.contains(point) else { return nil }
        return EditorGeometry.imagePoint(
            fromView: point, imageSize: imageSize, viewSize: bounds.size, actualSize: actualSize
        )
    }

    private func displayScale() -> CGFloat {
        guard let image else { return 1 }
        return EditorGeometry.displayScale(
            imageSize: CGSize(width: image.width, height: image.height),
            viewSize: bounds.size,
            actualSize: actualSize
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

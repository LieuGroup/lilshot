import AppKit
import LilshotCore

/// Dimmed overlay with marching-ants selection while dragging.
final class RegionSelectionView: NSView {
    var onCommit: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var anchor: CGPoint?
    private var cursor: CGPoint?
    private var dashPhase: CGFloat = 0
    private var antsTimer: Timer?

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            startAnts()
            window?.makeFirstResponder(self)
        } else {
            stopAnts()
        }
    }

    deinit {
        stopAnts()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        anchor = point
        cursor = point
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard anchor != nil else { return }
        cursor = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let anchor else { return }
        let end = convert(event.locationInWindow, from: nil)
        self.anchor = nil
        self.cursor = nil
        needsDisplay = true

        let bounds = bounds
        let raw = RegionGeometry.normalizedRect(from: anchor, to: end)
        let clamped = RegionGeometry.clamp(raw, to: bounds)
        guard clamped.width >= 2, clamped.height >= 2 else {
            onCancel?()
            return
        }
        onCommit?(clamped)
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        NSColor.black.withAlphaComponent(0.35).setFill()
        bounds.fill()

        guard let anchor, let cursor else { return }
        let selection = RegionGeometry.clamp(
            RegionGeometry.normalizedRect(from: anchor, to: cursor),
            to: bounds
        )
        guard !selection.isEmpty else { return }

        context.setBlendMode(.clear)
        context.fill(selection)
        context.setBlendMode(.normal)

        let path = NSBezierPath(rect: selection.insetBy(dx: 0.5, dy: 0.5))
        path.lineWidth = 1
        let pattern: [CGFloat] = [5, 4]
        path.setLineDash(pattern, count: pattern.count, phase: dashPhase)
        NSColor.white.setStroke()
        path.stroke()

        path.setLineDash(pattern, count: pattern.count, phase: dashPhase + 4.5)
        NSColor.black.setStroke()
        path.stroke()
    }

    private func startAnts() {
        stopAnts()
        antsTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.dashPhase += 1
            if self.anchor != nil {
                self.needsDisplay = true
            }
        }
    }

    private func stopAnts() {
        antsTimer?.invalidate()
        antsTimer = nil
    }
}

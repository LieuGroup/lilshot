import CoreGraphics
import Foundation

/// Active editor tool. Draw tools + crop are Round 2; select/blur in Round 3.
public enum EditorTool: Equatable, Sendable {
    case select
    case arrow
    case rect
    case text
    case blur
    case stepNumber
    case crop
}

/// Snapshot for undo/redo.
public struct EditorSnapshot: Equatable, Sendable {
    public var canvasSize: CGSize
    public var annotations: [Annotation]
    public var nextStepIndex: Int

    public init(canvasSize: CGSize, annotations: [Annotation], nextStepIndex: Int) {
        self.canvasSize = canvasSize
        self.annotations = annotations
        self.nextStepIndex = nextStepIndex
    }
}

/// Pure editor state: tools, annotations, crop draft, snapshot undo/redo.
public struct EditorModel: Equatable, Sendable {
    public var tool: EditorTool
    public var color: AnnotationColor
    public var strokeWidth: CGFloat
    public var canvasSize: CGSize
    public var annotations: [Annotation]
    public var cropDraft: CGRect?
    public var nextStepIndex: Int

    private var undoStack: [EditorSnapshot]
    private var redoStack: [EditorSnapshot]

    public init(canvasSize: CGSize) {
        self.tool = .crop
        self.color = .amber
        self.strokeWidth = 3
        self.canvasSize = canvasSize
        self.annotations = []
        self.cropDraft = nil
        self.nextStepIndex = 1
        self.undoStack = []
        self.redoStack = []
    }

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public mutating func selectTool(_ tool: EditorTool) {
        self.tool = tool
    }

    /// Normalize drag corners and clamp to the current canvas.
    public mutating func setCropDraft(from a: CGPoint, to b: CGPoint) {
        let raw = RegionGeometry.normalizedRect(from: a, to: b)
        cropDraft = EditorGeometry.clampCrop(raw, to: canvasSize)
    }

    public mutating func clearCropDraft() {
        cropDraft = nil
    }

    /// Apply crop draft: shrink canvas, shift annotations, push undo.
    public mutating func applyCrop() {
        guard let draft = cropDraft, draft.width >= 2, draft.height >= 2 else { return }
        pushUndo()
        let delta = CGVector(dx: -draft.origin.x, dy: -draft.origin.y)
        annotations = annotations.map { $0.translated(by: delta) }
        canvasSize = CGSize(width: draft.width, height: draft.height)
        cropDraft = nil
    }

    public mutating func pushAnnotation(_ annotation: Annotation) {
        pushUndo()
        annotations.append(annotation)
        if case .stepNumber(_, let index, _) = annotation {
            nextStepIndex = max(nextStepIndex, index + 1)
        }
    }

    /// Font size ≈ 5% of canvas height for the text tool.
    public static func defaultTextFontSize(canvasHeight: CGFloat) -> CGFloat {
        canvasHeight * 0.05
    }

    public mutating func addArrow(from: CGPoint, to: CGPoint) {
        pushAnnotation(
            .arrow(from: from, to: to, color: color, strokeWidth: strokeWidth)
        )
    }

    public mutating func addRect(from: CGPoint, to: CGPoint) {
        let rect = RegionGeometry.normalizedRect(from: from, to: to)
        guard rect.width >= 2, rect.height >= 2 else { return }
        pushAnnotation(.rect(rect, color: color, strokeWidth: strokeWidth))
    }

    public mutating func addStepNumber(at center: CGPoint) {
        pushAnnotation(.stepNumber(center: center, index: nextStepIndex, color: color))
    }

    public mutating func addText(at origin: CGPoint, string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let fontSize = Self.defaultTextFontSize(canvasHeight: canvasSize.height)
        pushAnnotation(.text(origin: origin, string: trimmed, fontSize: fontSize, color: color))
    }

    public mutating func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(snapshot())
        restore(previous)
    }

    public mutating func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(snapshot())
        restore(next)
    }

    private mutating func pushUndo() {
        undoStack.append(snapshot())
        redoStack.removeAll()
    }

    private func snapshot() -> EditorSnapshot {
        EditorSnapshot(
            canvasSize: canvasSize,
            annotations: annotations,
            nextStepIndex: nextStepIndex
        )
    }

    private mutating func restore(_ snapshot: EditorSnapshot) {
        canvasSize = snapshot.canvasSize
        annotations = snapshot.annotations
        nextStepIndex = snapshot.nextStepIndex
        cropDraft = nil
    }
}

import AppKit
import LilshotCore

extension EditorWindowController {
    func wireEditorCanvas(_ canvas: EditorCanvasView) {
        canvas.onCropDraftChanged = { [weak self] a, b in
            self?.applyModel { $0.setCropDraft(from: a, to: b) }
        }
        canvas.onCropDraftCleared = { [weak self] in
            self?.applyModel { $0.clearCropDraft() }
        }
        canvas.onCommitArrow = { [weak self] a, b in
            self?.applyModel { $0.addArrow(from: a, to: b) }
        }
        canvas.onCommitRect = { [weak self] a, b in
            self?.applyModel { $0.addRect(from: a, to: b) }
        }
        canvas.onCommitBlur = { [weak self] a, b in
            self?.applyModel { $0.addBlur(from: a, to: b) }
        }
        canvas.onCommitStep = { [weak self] point in
            self?.applyModel { $0.addStepNumber(at: point) }
        }
        canvas.onCommitText = { [weak self] origin, string in
            self?.applyModel { $0.addText(at: origin, string: string) }
        }
        canvas.onSelectAt = { [weak self] point in
            self?.applyModel { $0.selectAt(point) }
        }
        canvas.onBeginMove = { [weak self] in
            self?.mutateModel { $0.beginMoveSelected() }
        }
        canvas.onMoveBy = { [weak self] delta in
            self?.applyModel { $0.moveSelected(by: delta) }
        }
    }
}

import AppKit
import LilshotCore

extension EditorCanvasView {
    func handleMouseDown(_ event: NSEvent) {
        window?.makeFirstResponder(self)
        if isEditingText {
            textSessionCommit()
            return
        }

        let point = convert(event.locationInWindow, from: nil)
        guard let imagePt = imagePointForInteraction(fromView: point) else {
            if model.tool == .select { onSelectAt?(CGPoint(x: -1, y: -1)) }
            return
        }

        switch model.tool {
        case .crop, .arrow, .rect, .blur:
            setDragAnchor(point)
        case .stepNumber:
            onCommitStep?(imagePt)
        case .text:
            beginTextInput(at: point, imageOrigin: imagePt)
        case .select:
            onSelectAt?(imagePt)
            setMoveTracking(imagePt)
            setDragAnchor(point)
        }
    }

    func handleMouseDragged(_ event: NSEvent) {
        guard let anchor = dragAnchorPoint else { return }
        let cursor = convert(event.locationInWindow, from: nil)
        guard let a = imagePointForInteraction(fromView: anchor),
              let b = imagePointForInteraction(fromView: cursor)
        else { return }

        switch model.tool {
        case .crop:
            onCropDraftChanged?(a, b)
        case .arrow:
            setDraft(
                .arrow(from: a, to: b, color: model.color, strokeWidth: model.strokeWidth)
            )
        case .rect:
            let rect = RegionGeometry.normalizedRect(from: a, to: b)
            setDraft(.rect(rect, color: model.color, strokeWidth: model.strokeWidth))
        case .blur:
            let rect = RegionGeometry.normalizedRect(from: a, to: b)
            setDraft(.blur(rect))
        case .select:
            guard model.selectedIndex != nil else { return }
            if !hasMoveStarted {
                onBeginMove?()
                markMoveStarted()
            }
            if let last = lastMovePoint {
                onMoveBy?(CGVector(dx: b.x - last.x, dy: b.y - last.y))
            }
            updateLastMovePoint(b)
        default:
            break
        }
    }

    func handleMouseUp(_ event: NSEvent) {
        guard let anchor = dragAnchorPoint else { return }
        clearDragState()
        let cursor = convert(event.locationInWindow, from: nil)
        let a = imagePointForInteraction(fromView: anchor)
        let b = imagePointForInteraction(fromView: cursor)
        let draft = takeDraft()
        needsDisplay = true

        switch model.tool {
        case .crop:
            finishCropInteraction(from: a, to: b)
        case .arrow:
            if let a, let b, case .arrow = draft { onCommitArrow?(a, b) }
        case .rect:
            if let a, let b, case .rect = draft { onCommitRect?(a, b) }
        case .blur:
            if let a, let b, case .blur = draft { onCommitBlur?(a, b) }
        default:
            break
        }
    }
}

import CoreGraphics
import XCTest
@testable import LilshotCore

final class EditorModelTests: XCTestCase {
    func testDefaultsToCropToolWithEmptyAnnotations() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        XCTAssertEqual(model.tool, .crop)
        XCTAssertTrue(model.annotations.isEmpty)
        XCTAssertEqual(model.color, .amber)
        XCTAssertNil(model.cropDraft)
        XCTAssertFalse(model.canUndo)
        XCTAssertFalse(model.canRedo)
        _ = model
    }

    func testSelectToolUpdatesCurrentTool() {
        var model = EditorModel(canvasSize: CGSize(width: 100, height: 100))
        model.selectTool(.arrow)
        XCTAssertEqual(model.tool, .arrow)
        model.selectTool(.rect)
        XCTAssertEqual(model.tool, .rect)
    }

    func testSetCropDraftNormalizesAndClampsToCanvas() {
        var model = EditorModel(canvasSize: CGSize(width: 100, height: 80))
        model.setCropDraft(from: CGPoint(x: 90, y: 70), to: CGPoint(x: -10, y: -20))
        XCTAssertEqual(
            model.cropDraft,
            CGRect(x: 0, y: 0, width: 90, height: 70)
        )
    }

    func testApplyCropUpdatesCanvasSizeAndClearsDraft() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.setCropDraft(from: CGPoint(x: 20, y: 10), to: CGPoint(x: 120, y: 60))
        model.applyCrop()
        XCTAssertEqual(model.canvasSize, CGSize(width: 100, height: 50))
        XCTAssertNil(model.cropDraft)
        XCTAssertTrue(model.canUndo)
    }

    func testApplyCropShiftsAnnotationsRelativeToCropOrigin() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.annotations = [
            .rect(
                CGRect(x: 30, y: 20, width: 40, height: 20),
                color: .red,
                strokeWidth: 2
            ),
            .arrow(
                from: CGPoint(x: 10, y: 10),
                to: CGPoint(x: 50, y: 50),
                color: .blue,
                strokeWidth: 3
            ),
        ]
        model.setCropDraft(from: CGPoint(x: 20, y: 10), to: CGPoint(x: 120, y: 80))
        model.applyCrop()
        XCTAssertEqual(
            model.annotations,
            [
                .rect(
                    CGRect(x: 10, y: 10, width: 40, height: 20),
                    color: .red,
                    strokeWidth: 2
                ),
                .arrow(
                    from: CGPoint(x: -10, y: 0),
                    to: CGPoint(x: 30, y: 40),
                    color: .blue,
                    strokeWidth: 3
                ),
            ]
        )
    }

    func testApplyCropIgnoresEmptyOrMissingDraft() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.applyCrop()
        XCTAssertEqual(model.canvasSize, CGSize(width: 200, height: 100))
        XCTAssertFalse(model.canUndo)

        model.setCropDraft(from: CGPoint(x: 40, y: 40), to: CGPoint(x: 41, y: 40))
        model.applyCrop()
        XCTAssertEqual(model.canvasSize, CGSize(width: 200, height: 100))
        XCTAssertFalse(model.canUndo)
    }

    func testUndoRestoresPreCropSnapshotAndEnablesRedo() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.annotations = [
            .blur(CGRect(x: 5, y: 5, width: 10, height: 10)),
        ]
        model.setCropDraft(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 50, y: 40))
        model.applyCrop()
        XCTAssertEqual(model.canvasSize, CGSize(width: 50, height: 40))

        model.undo()
        XCTAssertEqual(model.canvasSize, CGSize(width: 200, height: 100))
        XCTAssertEqual(model.annotations, [.blur(CGRect(x: 5, y: 5, width: 10, height: 10))])
        XCTAssertTrue(model.canRedo)
        XCTAssertFalse(model.canUndo)
    }

    func testRedoReappliesUndoneSnapshot() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.setCropDraft(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 110, y: 60))
        model.applyCrop()
        model.undo()
        model.redo()
        XCTAssertEqual(model.canvasSize, CGSize(width: 100, height: 50))
        XCTAssertTrue(model.canUndo)
        XCTAssertFalse(model.canRedo)
    }

    func testNewMutationClearsRedoStack() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.setCropDraft(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 80, y: 60))
        model.applyCrop()
        model.undo()
        XCTAssertTrue(model.canRedo)

        model.setCropDraft(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 40, y: 30))
        model.applyCrop()
        XCTAssertFalse(model.canRedo)
        XCTAssertEqual(model.canvasSize, CGSize(width: 40, height: 30))
    }

    func testPushAnnotationRecordsUndo() {
        var model = EditorModel(canvasSize: CGSize(width: 100, height: 100))
        model.pushAnnotation(
            .stepNumber(center: CGPoint(x: 20, y: 20), index: 1, color: .amber)
        )
        XCTAssertEqual(model.annotations.count, 1)
        XCTAssertEqual(model.nextStepIndex, 2)
        model.undo()
        XCTAssertTrue(model.annotations.isEmpty)
        XCTAssertEqual(model.nextStepIndex, 1)
    }
}

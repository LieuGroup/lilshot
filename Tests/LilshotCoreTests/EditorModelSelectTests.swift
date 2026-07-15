import CoreGraphics
import XCTest
@testable import LilshotCore

final class EditorModelSelectTests: XCTestCase {
    func testAddBlurNormalizesAndRecordsUndo() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.addBlur(from: CGPoint(x: 80, y: 60), to: CGPoint(x: 20, y: 20))
        XCTAssertEqual(
            model.annotations,
            [.blur(CGRect(x: 20, y: 20, width: 60, height: 40))]
        )
        XCTAssertTrue(model.canUndo)
        model.undo()
        XCTAssertTrue(model.annotations.isEmpty)
    }

    func testSelectAtPointSetsSelectedIndex() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.pushAnnotation(.blur(CGRect(x: 10, y: 10, width: 40, height: 30)))
        model.pushAnnotation(
            .stepNumber(center: CGPoint(x: 100, y: 50), index: 1, color: .amber)
        )
        model.selectAt(CGPoint(x: 100, y: 50))
        XCTAssertEqual(model.selectedIndex, 1)
        model.selectAt(CGPoint(x: 0, y: 0))
        XCTAssertNil(model.selectedIndex)
    }

    func testMoveSelectedTranslatesAnnotationAndUndoRestores() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.pushAnnotation(.blur(CGRect(x: 10, y: 10, width: 20, height: 20)))
        model.selectAt(CGPoint(x: 15, y: 15))
        model.beginMoveSelected()
        model.moveSelected(by: CGVector(dx: 5, dy: -3))
        XCTAssertEqual(model.annotations, [.blur(CGRect(x: 15, y: 7, width: 20, height: 20))])
        model.undo()
        XCTAssertEqual(model.annotations, [.blur(CGRect(x: 10, y: 10, width: 20, height: 20))])
    }

    func testDeleteSelectedRemovesAnnotationAndClearsSelection() {
        var model = EditorModel(canvasSize: CGSize(width: 200, height: 100))
        model.pushAnnotation(
            .arrow(
                from: CGPoint(x: 0, y: 0),
                to: CGPoint(x: 40, y: 0),
                color: .red,
                strokeWidth: 2
            )
        )
        model.pushAnnotation(.blur(CGRect(x: 50, y: 50, width: 10, height: 10)))
        model.selectAt(CGPoint(x: 20, y: 0))
        XCTAssertEqual(model.selectedIndex, 0)
        model.deleteSelected()
        XCTAssertEqual(model.annotations.count, 1)
        XCTAssertNil(model.selectedIndex)
        XCTAssertTrue(model.canUndo)
        model.undo()
        XCTAssertEqual(model.annotations.count, 2)
    }

    func testDeleteSelectedNoopsWithoutSelection() {
        var model = EditorModel(canvasSize: CGSize(width: 100, height: 100))
        model.pushAnnotation(.blur(CGRect(x: 0, y: 0, width: 10, height: 10)))
        let before = model.annotations
        model.deleteSelected()
        XCTAssertEqual(model.annotations, before)
    }
}
